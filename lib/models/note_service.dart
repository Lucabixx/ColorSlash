import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/note_model.dart';

/// 🔹 Gestisce note locali e sincronizzazione cloud
class NoteService extends ChangeNotifier {
  final List<NoteModel> _notes = [];
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<NoteModel> get notes => List.unmodifiable(_notes);

  /// 🔸 Carica note dal device (SharedPreferences)
  Future<void> loadNotes() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('notes');
      if (raw != null) {
        final decoded = json.decode(raw) as List;
        _notes.clear();
        _notes.addAll(decoded.map((n) => NoteModel.fromJson(n)));
      }
      notifyListeners();
    } catch (e) {
      debugPrint("⚠️ Errore caricando note: $e");
    }
  }

  /// 🔸 Salva note in locale
  Future<void> _saveLocal() async {
    final prefs = await SharedPreferences.getInstance();
    final data = json.encode(_notes.map((n) => n.toJson()).toList());
    await prefs.setString('notes', data);
  }

  /// 🔹 Aggiunge o aggiorna una nota
  Future<void> upsertNote(NoteModel note) async {
    final index = _notes.indexWhere((n) => n.id == note.id);
    if (index >= 0) {
      _notes[index] = note;
    } else {
      _notes.add(note);
    }
    await _saveLocal();
    notifyListeners();
  }

  /// 🔹 Rimuove una nota
  Future<void> deleteNote(String id) async {
    _notes.removeWhere((n) => n.id == id);
    await _saveLocal();
    notifyListeners();
  }

  /// 🔹 Sincronizza con Firestore (upload locale → cloud)
  Future<void> syncToCloud(String uid) async {
    try {
      final ref = _firestore.collection('users').doc(uid).collection('notes');
      for (final note in _notes) {
        await ref.doc(note.id).set(note.toJson(), SetOptions(merge: true));
      }
      debugPrint("✅ Note sincronizzate con Firestore");
    } catch (e) {
      debugPrint("⚠️ Errore durante syncToCloud: $e");
    }
  }

  /// 🔹 Scarica note dal cloud e unisce con locali
  Future<void> syncFromCloud(String uid) async {
    try {
      final ref = _firestore.collection('users').doc(uid).collection('notes');
      final snap = await ref.get();

      final cloudNotes = snap.docs.map((d) => NoteModel.fromJson(d.data())).toList();

      // 🔁 Merge intelligente tra locale e cloud
      for (final n in cloudNotes) {
        final localIndex = _notes.indexWhere((x) => x.id == n.id);
        if (localIndex >= 0) {
          final local = _notes[localIndex];
          if (n.updatedAt.isAfter(local.updatedAt)) {
            _notes[localIndex] = n;
          }
        } else {
          _notes.add(n);
        }
      }

      await _saveLocal();
      notifyListeners();
      debugPrint("✅ Note sincronizzate dal Cloud");
    } catch (e) {
      debugPrint("⚠️ Errore durante syncFromCloud: $e");
    }
  }

  /// 🔹 Crea una nuova nota con ID univoco
  NoteModel createEmptyNote({
    String title = '',
    String content = '',
    String colorHex = '#FFFFFFFF',
  }) {
    final newNote = NoteModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      content: content,
      colorHex: colorHex,
      updatedAt: DateTime.now(),
      attachments: [],
    );
    return newNote;
  }
}
