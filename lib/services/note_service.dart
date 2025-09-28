import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/note.dart';
import 'auth_service.dart';

class NoteService extends ChangeNotifier {
  final List<Note> _notes = [];
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<Note> get notes => List.unmodifiable(_notes);

  /// Carica le note locali all'avvio
  Future<void> loadNotes() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getStringList('notes') ?? [];
    _notes.clear();
    _notes.addAll(stored.map((json) => _fromJson(json)).toList());
    notifyListeners();
  }

  /// Aggiungi una nuova nota
  void addNote(Note note) {
    _notes.add(note);
    _saveLocal();
    notifyListeners();
  }

  /// Aggiorna una nota
  void updateNote(String id, Note updated) {
    final i = _notes.indexWhere((n) => n.id == id);
    if (i != -1) {
      _notes[i] = updated;
      _saveLocal();
      notifyListeners();
    }
  }

  /// Elimina una nota
  void deleteNote(String id, BuildContext context) {
    _notes.removeWhere((n) => n.id == id);
    _saveLocal();
    notifyListeners();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Nota eliminata"),
        duration: Duration(seconds: 2),
      ),
    );
  }

  /// 🔄 Sincronizza locale ↔️ cloud
  Future<void> syncNotes(AuthService auth) async {
    final user = auth.currentUser;
    if (user == null) return; // non loggato → solo locale

    try {
      final ref = _firestore.collection('users').doc(user.uid).collection('notes');

      // carica le note locali su Firestore
      for (var n in _notes) {
        await ref.doc(n.id).set(_toMap(n));
      }

      // scarica le note dal cloud (merge)
      final snapshot = await ref.get();
      for (var doc in snapshot.docs) {
        final cloudNote = _fromMap(doc.data());
        final exists = _notes.any((n) => n.id == cloudNote.id);
        if (!exists) _notes.add(cloudNote);
      }

      await _saveLocal();
      notifyListeners();
    } catch (e) {
      debugPrint("Errore sincronizzazione: $e");
    }
  }

  /// Salva tutto in locale
  Future<void> _saveLocal() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = _notes.map((n) => _toJson(n)).toList();
    await prefs.setStringList('notes', jsonList);
  }

  /// --- Utility JSON ---
  String _toJson(Note n) => jsonEncode({
        'id': n.id,
        'title': n.title,
        'content': n.content,
        'color': n.color.value,
      });

  Note _fromJson(String str) {
    final data = jsonDecode(str);
    return Note(
      id: data['id'],
      title: data['title'],
      content: data['content'],
      color: Color(data['color']),
    );
  }

  Map<String, dynamic> _toMap(Note n) => {
        'id': n.id,
        'title': n.title,
        'content': n.content,
        'color': n.color.value,
      };

  Note _fromMap(Map<String, dynamic> map) => Note(
        id: map['id'],
        title: map['title'],
        content: map['content'],
        color: Color(map['color']),
      );
}
