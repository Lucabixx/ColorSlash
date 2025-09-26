// lib/services/storage_service.dart
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hive/hive.dart';
import 'package:path/path.dart' as p;

class StorageService {
  static late Box _notesBox;
  static final _firestore = FirebaseFirestore.instance;
  static final _storage = FirebaseStorage.instance;

  static Future<void> init() async {
    _notesBox = await Hive.openBox('notesBox');
  }

  static List<Map<String, dynamic>> getAllNotes() {
    return _notesBox.values.map((e) => Map<String, dynamic>.from(e)).toList();
  }

  static Map<String, dynamic>? getNote(String id) {
    final v = _notesBox.get(id);
    if (v == null) return null;
    return Map<String, dynamic>.from(v);
  }

  static Future<void> deleteNote(String id) async {
    await _notesBox.delete(id);
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await _firestore.collection('users').doc(user.uid).collection('notes').doc(id).delete();
    }
  }

  static bool _isRemote(String path) => path.startsWith('http://') || path.startsWith('https://');

  static Future<String> _uploadFile(File f, String remotePath) async {
    final ref = _storage.ref().child(remotePath);
    final task = await ref.putFile(f);
    return await ref.getDownloadURL();
  }

  /// Save note data (data must contain 'attachments' = List<Map>)
  /// If user is logged, uploads local files to Storage and replaces path with download URL.
  static Future<void> saveNote(String id, Map<String, dynamic> data) async {
    final user = FirebaseAuth.instance.currentUser;
    final List<dynamic> attsRaw = data['attachments'] ?? [];
    final List<Map<String, dynamic>> atts = attsRaw.map((e) => Map<String, dynamic>.from(e)).toList();
    final List<Map<String, dynamic>> resultAtts = [];

    for (var a in atts) {
      final String? pathLocal = a['path'] as String?;
      if (pathLocal == null) continue;

      if (_isRemote(pathLocal) || user == null) {
        // keep remote URLs, or if not logged keep local path as-is
        resultAtts.add({
          ...a,
          'url': _isRemote(pathLocal) ? pathLocal : null,
          'localPath': _isRemote(pathLocal) ? null : pathLocal,
        });
      } else {
        final f = File(pathLocal);
        if (!await f.exists()) {
          resultAtts.add({'type': a['type'], 'localPath': pathLocal});
          continue;
        }
        final ext = p.extension(pathLocal);
        final remotePath = 'users/${user.uid}/notes/$id/${DateTime.now().millisecondsSinceEpoch}$ext';
        try {
          final url = await _uploadFile(f, remotePath);
          resultAtts.add({'type': a['type'], 'url': url, 'localPath': pathLocal});
        } catch (e) {
          // upload failed -> keep local path
          resultAtts.add({'type': a['type'], 'localPath': pathLocal});
        }
      }
    }

    final toSave = {
      ...data,
      'attachments': resultAtts,
      'id': id,
      'timestamp': DateTime.now().toIso8601String(),
    };

    await _notesBox.put(id, toSave);

    if (user != null) {
      await _firestore.collection('users').doc(user.uid).collection('notes').doc(id).set(toSave);
    }
  }

  /// Pull cloud notes to local (overwrites local by id)
  static Future<void> pullNotesFromCloud() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final snap = await _firestore.collection('users').doc(user.uid).collection('notes').get();
    for (var d in snap.docs) {
      await _notesBox.put(d.id, d.data());
    }
  }

  /// Sync all local notes to cloud
  static Future<void> syncAllNotes() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    for (var v in _notesBox.values) {
      final m = Map<String, dynamic>.from(v);
      await _firestore.collection('users').doc(user.uid).collection('notes').doc(m['id']).set(m);
    }
  }
}