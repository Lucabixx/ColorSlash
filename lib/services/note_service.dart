// lib/services/note_service.dart
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:http/http.dart' as http;

import '../models/note_model.dart';
import 'auth_service.dart';

class NoteService extends ChangeNotifier {
  final List<NoteModel> _notes = [];
  List<NoteModel> get notes => List.unmodifiable(_notes);

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Connectivity _connectivity = Connectivity();

  Stream<ConnectivityResult>? _connectivityStream;

  NoteService() {
    // Ascolta lo stato della rete per riattivare la sync automatica
    _connectivityStream = _connectivity.onConnectivityChanged;
    _connectivityStream?.listen((status) async {
      if (status != ConnectivityResult.none) {
        debugPrint('🌐 Connessione ripristinata → avvio sincronizzazione automatica');
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
      _notes
        ..clear()
        ..addAll(decoded.map((e) => NoteModel.fromJson(Map<String, dynamic>.from(e as Map))));
      notifyListeners();
    } catch (e) {
      debugPrint('❌ loadLocalNotes error: $e');
    }
  }

  Future<void> saveLocalNotes() async {
    try {
      final file = await _getNotesFile();
      final data = jsonEncode(_notes.map((n) => n.toJson()).toList());
      await file.writeAsString(data);
    } catch (e) {
      debugPrint('❌ saveLocalNotes error: $e');
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
          await _firestore
              .collection('users')
              .doc(user.uid)
              .collection('notes')
              .doc(id)
              .delete();
        }
      } catch (e) {
        debugPrint('❌ delete cloud error: $e');
      }
    }
  }

  // -------------------------
  // Sync bidirezionale completa
  // -------------------------
  Future<void> syncWithCloud(AuthService auth) async {
    final user = auth.currentUser;
    if (user == null) {
      debugPrint('⚠️ Nessun utente loggato: sync ignorata');
      return;
    }

    try {
      final ref = _firestore.collection('users').doc(user.uid).collection('notes');
      final snap = await ref.get();
      final cloudNotes = snap.docs.map((d) => NoteModel.fromDoc(d)).toList();

      final localMap = {for (var n in _notes) n.id: n};
      final cloudMap = {for (var c in cloudNotes) c.id: c};
      final allIds = {...localMap.keys, ...cloudMap.keys};

      for (final id in allIds) {
        final local = localMap[id];
        final cloud = cloudMap[id];

        if (local == null && cloud != null) {
          // Solo su Firestore → aggiungi in locale
          _notes.add(cloud);
        } else if (cloud == null && local != null) {
          // Solo in locale → carica su cloud
          await _saveToCloud(local, auth);
        } else if (local != null && cloud != null) {
          // Esistono entrambi → tieni il più recente
          if (local.updatedAt.isAfter(cloud.updatedAt)) {
            await _saveToCloud(local, auth);
          } else if (cloud.updatedAt.isAfter(local.updatedAt)) {
            final idx = _notes.indexWhere((n) => n.id == id);
            if (idx != -1) _notes[idx] = cloud;
          }
        }
      }

      await saveLocalNotes();
      notifyListeners();

      final notesFile = await _getNotesFile();
      if (await notesFile.exists()) {
        await _uploadToGoogleDriveIfPossible(notesFile, auth);
        await _uploadToOneDriveIfPossible(notesFile, auth);
      }

      debugPrint('✅ Sincronizzazione completata');
    } catch (e) {
      debugPrint('❌ syncWithCloud error: $e');
    }
  }

  Future<void> _saveToCloud(NoteModel note, AuthService auth) async {
    try {
      final user = auth.currentUser;
      if (user == null) return;

      final ref = _firestore.collection('users').doc(user.uid).collection('notes').doc(note.id);
      await ref.set(note.toJson());
    } catch (e) {
      debugPrint('❌ _saveToCloud error: $e');
    }
  }

  // -------------------------
  // Google Drive upload
  // -------------------------
  Future<void> _uploadToGoogleDriveIfPossible(File file, AuthService auth) async {
    try {
      final uploaded = await auth.uploadNotesFileToDrive(file);
      if (uploaded) debugPrint('☁️ notes.json caricato su Google Drive');
    } catch (e) {
      debugPrint('❌ _uploadToGoogleDriveIfPossible error: $e');
    }
  }

  // -------------------------
  // OneDrive upload stub
  // -------------------------
  Future<void> _uploadToOneDriveIfPossible(File file, AuthService auth) async {
    try {
      // TODO: Implementare upload OneDrive via Microsoft Graph API
      debugPrint('ℹ️ _uploadToOneDriveIfPossible: non implementato');
    } catch (e) {
      debugPrint('❌ _uploadToOneDriveIfPossible error: $e');
    }
  }

  // -------------------------
  // Utility: crea nuova nota
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
