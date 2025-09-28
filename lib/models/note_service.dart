import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/note_model.dart';
import 'auth_service.dart';

class NoteService extends ChangeNotifier {
  final List<NoteModel> _notes = [];
  List<NoteModel> get notes => List.unmodifiable(_notes);

  final _firestore = FirebaseFirestore.instance;

  /// Carica le note da file locale
  Future<void> loadLocalNotes() async {
    try {
      final file = await _getNotesFile();
      if (!await file.exists()) return;
      final data = jsonDecode(await file.readAsString());
      _notes.clear();
      _notes.addAll((data as List).map((e) => NoteModel.fromJson(e)));
      notifyListeners();
    } catch (e) {
      debugPrint("Errore caricamento locale: $e");
    }
  }

  /// Salva tutte le note in JSON locale
  Future<void> _saveLocalNotes() async {
    final file = await _getNotesFile();
    final jsonData = jsonEncode(_notes.map((n) => n.toJson()).toList());
    await file.writeAsString(jsonData);
  }

  /// Percorso file JSON
  Future<File> _getNotesFile() async {
    final dir = await getApplicationDocumentsDirectory();
    return File("${dir.path}/notes.json");
  }

  /// Aggiunge o aggiorna una nota
  Future<void> addOrUpdate(NoteModel note, {bool sync = true}) async {
    final index = _notes.indexWhere((n) => n.id == note.id);
    if (index != -1) {
      _notes[index] = note;
    } else {
      _notes.add(note);
    }
    await _saveLocalNotes();

    if (sync) await _saveToCloud(note);
    notifyListeners();
  }

  /// Rimuove una nota
  Future<void> delete(String id) async {
    _notes.removeWhere((n) => n.id == id);
    await _saveLocalNotes();
    notifyListeners();
  }

  /// Sincronizza con Firestore
  Future<void> syncWithCloud(AuthService auth) async {
    final user = auth.currentUser;
    if (user == null) return;

    final ref = _firestore.collection('users').doc(user.uid).collection('notes');

    // 🔄 Scarica dal cloud
    final snapshot = await ref.get();
    for (var doc in snapshot.docs) {
      final cloudNote = NoteModel.fromDoc(doc);
      final localIndex = _notes.indexWhere((n) => n.id == cloudNote.id);

      // Se locale è più vecchia → aggiorna con cloud
      if (localIndex == -1 ||
          cloudNote.updatedAt.isAfter(_notes[localIndex].updatedAt)) {
        if (localIndex == -1) {
          _notes.add(cloudNote);
        } else {
          _notes[localIndex] = cloudNote;
        }
      }
    }

    // 🔼 Carica note locali non presenti su cloud
    for (var note in _notes) {
      await _saveToCloud(note);
    }

    await _saveLocalNotes();
    notifyListeners();
  }

  /// Salva singola nota su Firestore
  Future<void> _saveToCloud(NoteModel note) async {
    try {
      final user = await AuthService().getUser();
      if (user == null) return;

      final ref = _firestore
          .collection('users')
          .doc(user.uid)
          .collection('notes')
          .doc(note.id);

      await ref.set(note.toJson());
    } catch (e) {
      debugPrint("Errore salvataggio cloud: $e");
    }
  }
}
