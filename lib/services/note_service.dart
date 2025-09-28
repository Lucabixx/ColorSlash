// lib/services/note_service.dart
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

import '../models/note_model.dart';
import 'auth_service.dart';
import 'package:http/http.dart' as http;

class NoteService extends ChangeNotifier {
  final List<NoteModel> _notes = [];
  List<NoteModel> get notes => List.unmodifiable(_notes);

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // connettività
  final Connectivity _connectivity = Connectivity();
  Stream<ConnectivityResult>? _connectivityStream;

  NoteService() {
    // Avvia listener connettività per sync automatico quando ritorna online
    _connectivityStream = _connectivity.onConnectivityChanged;
    _connectivityStream?.listen((status) async {
      if (status != ConnectivityResult.none) {
        debugPrint('Network available -> tentativo di sincronizzazione');
        // se vuoi: ottieni AuthService con Provider quando esegui in app
      }
    });
  }

  // -------------------------
  // File locale
  // -------------------------
  Future<File> _getNotesFile() async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/notes.json');
  }

  Future<void> loadLocalNotes() async {
    try {
      final file = await _getNotesFile();
      if (!await file.exists()) {
        _notes.clear();
        notifyListeners();
        return;
      }
      final raw = await file.readAsString();
      final List<dynamic> decoded = jsonDecode(raw);
      _notes.clear();
      _notes.addAll(decoded.map((e) => NoteModel.fromJson(Map<String, dynamic>.from(e as Map))));
      notifyListeners();
    } catch (e) {
      debugPrint('loadLocalNotes error: $e');
    }
  }

  Future<void> saveLocalNotes() async {
    try {
      final file = await _getNotesFile();
      final jsonData = jsonEncode(_notes.map((n) => n.toJson()).toList());
      await file.writeAsString(jsonData);
    } catch (e) {
      debugPrint('saveLocalNotes error: $e');
    }
  }

  // -------------------------
  // CRUD locali + cloud
  // -------------------------
  Future<void> addOrUpdate(NoteModel note, {bool sync = true, AuthService? auth}) async {
    final idx = _notes.indexWhere((n) => n.id == note.id);
    if (idx != -1) {
      _notes[idx] = note;
    } else {
      _notes.add(note);
    }
    await saveLocalNotes();
    notifyListeners();

    if (sync && auth != null) {
      await _saveToCloud(note, auth);
    }
  }

  Future<void> delete(String id, {bool sync = true, AuthService? auth}) async {
    _notes.removeWhere((n) => n.id == id);
    await saveLocalNotes();
    notifyListeners();
    if (sync && auth != null) {
      try {
        final user = auth.currentUser;
        if (user != null) {
          await _firestore.collection('users').doc(user.uid).collection('notes').doc(id).delete();
        }
      } catch (e) {
        debugPrint('delete cloud error: $e');
      }
    }
  }

  // -------------------------
  // Sincronizzazione bidirezionale con Firestore
  // -------------------------
  Future<void> syncWithCloud(AuthService auth) async {
    final user = auth.currentUser;
    if (user == null) return;
    try {
      // carica cloud
      final ref = _firestore.collection('users').doc(user.uid).collection('notes');
      final snap = await ref.get();
      final cloudNotes = snap.docs.map((d) => NoteModel.fromDoc(d)).toList();

      // mappa per id
      final localMap = {for (var n in _notes) n.id: n};
      final cloudMap = {for (var c in cloudNotes) c.id: c};

      final ids = {...localMap.keys, ...cloudMap.keys};
      for (final id in ids) {
        final local = localMap[id];
        final cloud = cloudMap[id];

        if (local == null && cloud != null) {
          // solo cloud -> aggiungi locale
          _notes.add(cloud);
        } else if (cloud == null && local != null) {
          // solo locale -> salva su cloud
          await _saveToCloud(local, auth);
        } else if (local != null && cloud != null) {
          // entrambi -> compare updatedAt
          if (local.updatedAt.isAfter(cloud.updatedAt)) {
            await _saveToCloud(local, auth);
          } else if (cloud.updatedAt.isAfter(local.updatedAt)) {
            final idx = _notes.indexWhere((n) => n.id == cloud.id);
            if (idx != -1) _notes[idx] = cloud;
          }
        }
      }

      await saveLocalNotes();
      notifyListeners();

      // dopo la sync Firestore, carica su Drive / OneDrive (se configurati)
      final notesFile = await _getNotesFile();
      if (await notesFile.exists()) {
        // upload su Google Drive se token disponibile
        await _uploadToGoogleDriveIfPossible(notesFile, auth);
        // upload su OneDrive (se implementato)
        await _uploadToOneDriveIfPossible(notesFile, auth);
      }
    } catch (e) {
      debugPrint('syncWithCloud error: $e');
    }
  }

  Future<void> _saveToCloud(NoteModel note, AuthService auth) async {
    try {
      final user = auth.currentUser;
      if (user == null) return;
      final ref = _firestore.collection('users').doc(user.uid).collection('notes').doc(note.id);
      await ref.set(note.toJson());
    } catch (e) {
      debugPrint('_saveToCloud error: $e');
    }
  }

  // -------------------------
  // Google Drive upload helper
  // -------------------------
  Future<void> _uploadToGoogleDriveIfPossible(File file, AuthService auth) async {
    try {
      final uploaded = await auth.uploadNotesFileToDrive(file);
      if (uploaded) debugPrint('notes.json uploaded to Google Drive');
    } catch (e) {
      debugPrint('_uploadToGoogleDriveIfPossible error: $e');
    }
  }

  // -------------------------
  // OneDrive upload scaffold - richiede l'implementazione OAuth Microsoft
  // -------------------------
  Future<void> _uploadToOneDriveIfPossible(File file, AuthService auth) async {
    try {
      // TODO: se hai access token Microsoft disponibile, fai upload con MS Graph:
      // PUT https://graph.microsoft.com/v1.0/me/drive/special/approot:/notes.json:/content
      // con Authorization: Bearer <token>
      debugPrint('_uploadToOneDriveIfPossible: non implementato, vedere TODO');
    } catch (e) {
      debugPrint('_uploadToOneDriveIfPossible error: $e');
    }
  }

  // -------------------------
  // Utility: crea nuova nota vuota
  // -------------------------
  NoteModel createEmptyNote({String type = 'note'}) {
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    return NoteModel(
      id: id,
      type: type,
      title: '',
      content: '',
      colorHex: '#FF1E1E1E',
      updatedAt: DateTime.now(),
      attachments: [],
    );
  }
}
