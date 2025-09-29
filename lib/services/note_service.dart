import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

import '../models/note_model.dart';
import 'auth_service.dart';

class NoteService extends ChangeNotifier {
  final List<NoteModel> _notes = [];
  List<NoteModel> get notes => List.unmodifiable(_notes);

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Connectivity _connectivity = Connectivity();

  Stream<ConnectivityResult>? _connectivityStream;

  bool _isSyncing = false;
  int _retryDelaySeconds = 30;

  BuildContext? appContext;

  NoteService({this.appContext}) {
    _connectivityStream = _connectivity.onConnectivityChanged;

    _connectivityStream?.listen((result) async {
      if (result != ConnectivityResult.none) {
        debugPrint('🌐 Connessione ripristinata → avvio sincronizzazione automatica');
        _showSnackBar("🌐 Connessione ripristinata: sincronizzazione in corso...");
        await _trySyncWithRetry();
      } else {
        _showSnackBar("📴 Connessione assente — modalità offline");
      }
    });
  }

  // 🔁 Tentativo di sync con retry progressivo
  Future<void> _trySyncWithRetry() async {
    if (_isSyncing) return;
    _isSyncing = true;

    int attempt = 0;
    final maxDelay = Duration(minutes: 2);

    while (true) {
      try {
        final auth = AuthService();
        if (auth.currentUser == null) {
          debugPrint('⚠️ Utente non autenticato → interrompo retry sync');
          _showSnackBar("⚠️ Nessun utente loggato, sincronizzazione interrotta");
          break;
        }

        await syncWithCloud(auth);
        _retryDelaySeconds = 30;
        _showSnackBar("✅ Sincronizzazione completata con successo");
        debugPrint('✅ Sync automatica completata');
        break;
      } catch (e) {
        attempt++;
        final delay = Duration(seconds: _retryDelaySeconds);
        debugPrint('❌ Tentativo $attempt fallito: $e → ritento tra ${delay.inSeconds}s');
        _showSnackBar(
          "⚠️ Tentativo $attempt fallito — nuovo tentativo tra ${delay.inSeconds}s",
          color: Colors.orangeAccent,
        );

        await Future.delayed(delay);
        _retryDelaySeconds = (_retryDelaySeconds * 2).clamp(30, maxDelay.inSeconds);
      }
    }

    _isSyncing = false;
  }

  // ✅ SnackBar visuale globale
  void _showSnackBar(String message, {Color color = Colors.greenAccent}) {
    if (appContext != null) {
      final ctx = appContext!;
      ScaffoldMessenger.of(ctx).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: color,
          duration: const Duration(seconds: 3),
        ),
      );
    } else {
      debugPrint('🔔 Snackbar: $message');
    }
  }

  // -------------------------
  // 📁 File locale
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
  // ✏️ CRUD locali + cloud
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
  // ☁️ Sync bidirezionale con merge intelligente
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
          // Nuova nota dal cloud
          _notes.add(cloud);
          debugPrint('⬇️ Aggiunta da cloud: ${cloud.title}');
        } else if (cloud == null && local != null) {
          // Nuova nota locale
          await _saveToCloud(local, auth);
          debugPrint('⬆️ Caricata su cloud: ${local.title}');
        } else if (local != null && cloud != null) {
          // Entrambe esistono — merge intelligente
          final merged = _mergeNotes(local, cloud);
          if (merged == null) {
            // Conflitto non risolvibile → duplicato
            final conflictNote = cloud.copyWith(
              id: '${cloud.id}_conflict',
              title: '${cloud.title} (CONFLITTO)',
              updatedAt: DateTime.now(),
            );
            _notes.add(conflictNote);
            debugPrint('⚠️ Conflitto rilevato → creata copia: ${conflictNote.title}');
          } else {
            // Merge riuscito
            final idx = _notes.indexWhere((n) => n.id == id);
            if (idx != -1) {
              _notes[idx] = merged;
              debugPrint('🔄 Merge riuscito per nota: ${merged.title}');
            }
            await _saveToCloud(merged, auth);
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

      _showSnackBar("✅ Sincronizzazione completata con successo");
      debugPrint('✅ Sincronizzazione completata');
    } catch (e) {
      debugPrint('❌ syncWithCloud error: $e');
      rethrow;
    }
  }

  /// Merge logico di due note — restituisce `null` se conflitto irrisolvibile
  NoteModel? _mergeNotes(NoteModel local, NoteModel cloud) {
    // Se una è più recente → prendo quella
    if (local.updatedAt.isAfter(cloud.updatedAt)) return local;
    if (cloud.updatedAt.isAfter(local.updatedAt)) return cloud;

    // Stesso timestamp → tentativo di merge contenuto
    if (local.content.trim() == cloud.content.trim()) {
      return local; // uguali
    }

    // Merge testuale semplice (mantiene entrambi i paragrafi)
    try {
      final mergedContent = _smartMergeText(local.content, cloud.content);
      return local.copyWith(
        content: mergedContent,
        updatedAt: DateTime.now(),
      );
    } catch (e) {
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

import '../models/note_model.dart';
import 'auth_service.dart';

class NoteService extends ChangeNotifier {
  final List<NoteModel> _notes = [];
  List<NoteModel> get notes => List.unmodifiable(_notes);

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Connectivity _connectivity = Connectivity();

  Stream<ConnectivityResult>? _connectivityStream;

  bool _isSyncing = false;
  int _retryDelaySeconds = 30;

  BuildContext? appContext;

  NoteService({this.appContext}) {
    _connectivityStream = _connectivity.onConnectivityChanged;

    _connectivityStream?.listen((result) async {
      if (result != ConnectivityResult.none) {
        debugPrint('🌐 Connessione ripristinata → avvio sincronizzazione automatica');
        _showSnackBar("🌐 Connessione ripristinata: sincronizzazione in corso...");
        await _trySyncWithRetry();
      } else {
        _showSnackBar("📴 Connessione assente — modalità offline");
      }
    });
  }

  // 🔁 Tentativo di sync con retry progressivo
  Future<void> _trySyncWithRetry() async {
    if (_isSyncing) return;
    _isSyncing = true;

    int attempt = 0;
    final maxDelay = Duration(minutes: 2);

    while (true) {
      try {
        final auth = AuthService();
        if (auth.currentUser == null) {
          debugPrint('⚠️ Utente non autenticato → interrompo retry sync');
          _showSnackBar("⚠️ Nessun utente loggato, sincronizzazione interrotta");
          break;
        }

        await syncWithCloud(auth);
        _retryDelaySeconds = 30;
        _showSnackBar("✅ Sincronizzazione completata con successo");
        debugPrint('✅ Sync automatica completata');
        break;
      } catch (e) {
        attempt++;
        final delay = Duration(seconds: _retryDelaySeconds);
        debugPrint('❌ Tentativo $attempt fallito: $e → ritento tra ${delay.inSeconds}s');
        _showSnackBar(
          "⚠️ Tentativo $attempt fallito — nuovo tentativo tra ${delay.inSeconds}s",
          color: Colors.orangeAccent,
        );

        await Future.delayed(delay);
        _retryDelaySeconds = (_retryDelaySeconds * 2).clamp(30, maxDelay.inSeconds);
      }
    }

    _isSyncing = false;
  }

  // ✅ SnackBar visuale globale
  void _showSnackBar(String message, {Color color = Colors.greenAccent}) {
    if (appContext != null) {
      final ctx = appContext!;
      ScaffoldMessenger.of(ctx).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: color,
          duration: const Duration(seconds: 3),
        ),
      );
    } else {
      debugPrint('🔔 Snackbar: $message');
    }
  }

  // -------------------------
  // 📁 File locale
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
  // ✏️ CRUD locali + cloud
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
  // ☁️ Sync bidirezionale con merge intelligente
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
          // Nuova nota dal cloud
          _notes.add(cloud);
          debugPrint('⬇️ Aggiunta da cloud: ${cloud.title}');
        } else if (cloud == null && local != null) {
          // Nuova nota locale
          await _saveToCloud(local, auth);
          debugPrint('⬆️ Caricata su cloud: ${local.title}');
        } else if (local != null && cloud != null) {
          // Entrambe esistono — merge intelligente
          final merged = _mergeNotes(local, cloud);
          if (merged == null) {
            // Conflitto non risolvibile → duplicato
            final conflictNote = cloud.copyWith(
              id: '${cloud.id}_conflict',
              title: '${cloud.title} (CONFLITTO)',
              updatedAt: DateTime.now(),
            );
            _notes.add(conflictNote);
            debugPrint('⚠️ Conflitto rilevato → creata copia: ${conflictNote.title}');
          } else {
            // Merge riuscito
            final idx = _notes.indexWhere((n) => n.id == id);
            if (idx != -1) {
              _notes[idx] = merged;
              debugPrint('🔄 Merge riuscito per nota: ${merged.title}');
            }
            await _saveToCloud(merged, auth);
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

      _showSnackBar("✅ Sincronizzazione completata con successo");
      debugPrint('✅ Sincronizzazione completata');
    } catch (e) {
      debugPrint('❌ syncWithCloud error: $e');
      rethrow;
    }
  }

  /// Merge logico di due note — restituisce `null` se conflitto irrisolvibile
  NoteModel? _mergeNotes(NoteModel local, NoteModel cloud) {
    // Se una è più recente → prendo quella
    if (local.updatedAt.isAfter(cloud.updatedAt)) return local;
    if (cloud.updatedAt.isAfter(local.updatedAt)) return cloud;

    // Stesso timestamp → tentativo di merge contenuto
    if (local.content.trim() == cloud.content.trim()) {
      return local; // uguali
    }

    // Merge testuale semplice (mantiene entrambi i paragrafi)
    try {
      final mergedContent = _smartMergeText(local.content, cloud.content);
      return local.copyWith(
        content: mergedContent,
        updatedAt: DateTime.now(),
      );
    } catch (e) {
      debugPrint('❌ Merge contenuto fallito: $e');
      return null;
    }
  }

  /// Merge testuale — unisce differenze evitando duplicati banali
  String _smartMergeText(String a, String b) {
    final linesA = a.split('\n').map((l) => l.trim()).where((l) => l.isNotEmpty).toSet();
    final linesB = b.split('\n').map((l) => l.trim()).where((l) => l.isNotEmpty).toSet();

    final merged = [...linesA, ...linesB];
    return merged.join('\n');
  }

  Future<void> _saveToCloud(NoteModel note, AuthService auth) async {
    try {
      final user = auth.currentUser;
      if (user == null) return;

      final ref = _firestore
          .collection('users')
          .doc(user.uid)
          .collection('notes')
          .doc(note.id);

      await ref.set(note.toJson());
    } catch (e) {
      debugPrint('❌ _saveToCloud error: $e');
    }
  }

  Future<void> _uploadToGoogleDriveIfPossible(File file, AuthService auth) async {
    try {
      final uploaded = await auth.uploadNotesFileToDrive(file);
      if (uploaded) debugPrint('☁️ notes.json caricato su Google Drive');
    } catch (e) {
      debugPrint('❌ _uploadToGoogleDriveIfPossible error: $e');
    }
  }

  Future<void> _uploadToOneDriveIfPossible(File file, AuthService auth) async {
    try {
      debugPrint('ℹ️ _uploadToOneDriveIfPossible: non implementato');
    } catch (e) {
      debugPrint('❌ _uploadToOneDriveIfPossible error: $e');
    }
  }

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
}      debugPrint('❌ Merge contenuto fallito: $e');
      return null;
    }
  }

  /// Merge testuale — unisce differenze evitando duplicati banali
  String _smartMergeText(String a, String b) {
    final linesA = a.split('\n').map((l) => l.trim()).where((l) => l.isNotEmpty).toSet();
    final linesB = b.split('\n').map((l) => l.trim()).where((l) => l.isNotEmpty).toSet();

    final merged = [...linesA, ...linesB];
    return merged.join('\n');
  }

  Future<void> _saveToCloud(NoteModel note, AuthService auth) async {
    try {
      final user = auth.currentUser;
      if (user == null) return;

      final ref = _firestore
          .collection('users')
          .doc(user.uid)
          .collection('notes')
          .doc(note.id);

      await ref.set(note.toJson());
    } catch (e) {
      debugPrint('❌ _saveToCloud error: $e');
    }
  }

  Future<void> _uploadToGoogleDriveIfPossible(File file, AuthService auth) async {
    try {
      final uploaded = await auth.uploadNotesFileToDrive(file);
      if (uploaded) debugPrint('☁️ notes.json caricato su Google Drive');
    } catch (e) {
      debugPrint('❌ _uploadToGoogleDriveIfPossible error: $e');
    }
  }

  Future<void> _uploadToOneDriveIfPossible(File file, AuthService auth) async {
    try {
      debugPrint('ℹ️ _uploadToOneDriveIfPossible: non implementato');
    } catch (e) {
      debugPrint('❌ _uploadToOneDriveIfPossible error: $e');
    }
  }

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
 
