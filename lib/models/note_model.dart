import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/note_model.dart';

class NoteService extends ChangeNotifier {
  final List<NoteModel> _notes = [];

  List<NoteModel> get notes => List.unmodifiable(_notes);

  /// 📁 Ritorna il file locale
  Future<File> _getNotesFile() async {
    final dir = await getApplicationDocumentsDirectory();
    return File("${dir.path}/notes.json");
  }

  /// 🔄 Carica le note dal file locale
  Future<void> loadNotes() async {
    try {
      final file = await _getNotesFile();
      if (!await file.exists()) return;

      final jsonData = await file.readAsString();
      final List<dynamic> list = jsonDecode(jsonData);

      _notes
        ..clear()
        ..addAll(list.map((e) => NoteModel.fromJson(e as Map<String, dynamic>)));
      notifyListeners();
    } catch (e) {
      debugPrint("❌ Errore caricamento note: $e");
    }
  }

  /// 💾 Salva note in locale
  Future<void> _saveToFile() async {
    try {
      final file = await _getNotesFile();
      final jsonData = jsonEncode(_notes.map((n) => n.toJson()).toList());
      await file.writeAsString(jsonData);
    } catch (e) {
      debugPrint("❌ Errore salvataggio note: $e");
    }
  }

  /// ➕ Aggiunge o aggiorna una nota
  Future<void> saveNote(NoteModel note) async {
    final index = _notes.indexWhere((n) => n.id == note.id);
    if (index == -1) {
      _notes.add(note);
    } else {
      _notes[index] = note;
    }
    await _saveToFile();
    notifyListeners();
  }

  /// ❌ Elimina nota
  Future<void> deleteNote(String id) async {
    _notes.removeWhere((n) => n.id == id);
    await _saveToFile();
    notifyListeners();
  }

  /// 🔍 Ottieni nota per ID
  NoteModel? getNoteById(String id) {
    try {
      return _notes.firstWhere((n) => n.id == id);
    } catch (_) {
      return null;
    }
  }

  /// ☁️ Sincronizza con Firestore
  Future<void> syncWithCloud(String userId) async {
    final firestore = FirebaseFirestore.instance.collection('users').doc(userId).collection('notes');

    try {
      // 🔹 Upload note locali
      for (final note in _notes) {
        await firestore.doc(note.id).set(note.toJson(), SetOptions(merge: true));
      }

      // 🔹 Scarica note remote
      final snapshot = await firestore.get();
      final cloudNotes = snapshot.docs.map((doc) => NoteModel.fromDoc(doc)).toList();

      // 🔄 Unisci con note locali
      for (final cloudNote in cloudNotes) {
        final localIndex = _notes.indexWhere((n) => n.id == cloudNote.id);
        if (localIndex == -1) {
          _notes.add(cloudNote);
        } else if (cloudNote.updatedAt.isAfter(_notes[localIndex].updatedAt)) {
          _notes[localIndex] = cloudNote;
        }
      }

      await _saveToFile();
      notifyListeners();
    } catch (e) {
      debugPrint("⚠️ Errore sincronizzazione Firestore: $e");
    }
  }

  /// 🧹 Cancella tutte le note
  Future<void> clearAll() async {
    _notes.clear();
    await _saveToFile();
    notifyListeners();
  }
}
