import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:path_provider/path_provider.dart';

class NoteService extends ChangeNotifier {
  final _auth = FirebaseAuth.instance;
  final _db = FirebaseFirestore.instance;

  List<Map<String, dynamic>> _notes = [];

  List<Map<String, dynamic>> get notes => List.unmodifiable(_notes);

  Future<File> _getNotesFile() async {
    final dir = await getApplicationDocumentsDirectory();
    return File("${dir.path}/notes.json");
  }

  Future<void> loadNotes() async {
    try {
      final file = await _getNotesFile();
      if (await file.exists()) {
        final data = jsonDecode(await file.readAsString());
        _notes = List<Map<String, dynamic>>.from(data);
      } else {
        _notes = [];
      }
      notifyListeners();
    } catch (e) {
      debugPrint("Errore caricamento note: $e");
    }
  }

  Future<void> saveNotes() async {
    try {
      final file = await _getNotesFile();
      await file.writeAsString(jsonEncode(_notes));
    } catch (e) {
      debugPrint("Errore salvataggio locale: $e");
    }
  }

  Future<void> addOrUpdate(Map<String, dynamic> note) async {
    final index = _notes.indexWhere((n) => n['id'] == note['id']);
    if (index != -1) {
      _notes[index] = note;
    } else {
      _notes.add(note);
    }
    await saveNotes();
    notifyListeners();
  }

  Future<void> delete(String id) async {
    _notes.removeWhere((n) => n['id'] == id);
    await saveNotes();
    notifyListeners();
  }

  Future<void> syncNotes(BuildContext context) async {
    final user = _auth.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Nessun utente loggato")),
      );
      return;
    }

    try {
      final localNotes = _notes;
      final cloudSnap = await _db
          .collection('users')
          .doc(user.uid)
          .collection('notes')
          .get();

      final cloudNotes =
          cloudSnap.docs.map((d) => d.data()..['id'] = d.id).toList();

      final localMap = {for (var n in localNotes) n['id']: n};
      final cloudMap = {for (var n in cloudNotes) n['id']: n};

      for (var id in {...localMap.keys, ...cloudMap.keys}) {
        final local = localMap[id];
        final cloud = cloudMap[id];

        if (local == null && cloud != null) {
          localNotes.add(cloud);
        } else if (cloud == null && local != null) {
          await _db
              .collection('users')
              .doc(user.uid)
              .collection('notes')
              .doc(local['id'])
              .set(local);
        } else if (local != null && cloud != null) {
          final localTime = local['updatedAt'] ?? 0;
          final cloudTime = cloud['updatedAt'] ?? 0;
          if (localTime > cloudTime) {
            await _db
                .collection('users')
                .doc(user.uid)
                .collection('notes')
                .doc(local['id'])
                .set(local);
          } else if (cloudTime > localTime) {
            final index = localNotes.indexWhere((n) => n['id'] == id);
            if (index != -1) localNotes[index] = cloud;
          }
        }
      }

      _notes = localNotes;
      await saveNotes();
      notifyListeners();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("✅ Sincronizzazione completata")),
      );
    } catch (e) {
      debugPrint("Errore sync: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Errore sincronizzazione: $e")),
      );
    }
  }
}
