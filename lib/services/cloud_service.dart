// lib/services/cloud_service.dart
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

class CloudService {
  static final _firestore = FirebaseFirestore.instance;
  static final _storage = FirebaseStorage.instance;

  /// Upload a media file to Firebase Storage and return its download URL.
  /// noteId is used to build a folder path.
  static Future<String> uploadMedia(File file, String noteId) async {
    final fileName = file.path.split('/').last;
    final ref = _storage.ref().child('notes/$noteId/$fileName');
    final task = await ref.putFile(file);
    final url = await ref.getDownloadURL();
    return url;
  }

  /// Save note metadata (including attachments with remote urls) on Firestore
  /// Expects note map with at least 'id' field.
  static Future<void> backupNote(Map<String, dynamic> note) async {
    final id = note['id'] ?? DateTime.now().millisecondsSinceEpoch.toString();
    await _firestore.collection('notes').doc(id).set(note);
  }

  /// Upload all local notes - helper (you can extend to iterate local storage)
  static Future<void> uploadAllNotes(List<Map<String, dynamic>> notes) async {
    for (var n in notes) {
      final id = n['id'] ?? DateTime.now().millisecondsSinceEpoch.toString();
      await _firestore.collection('notes').doc(id).set(n);
    }
  }
}
