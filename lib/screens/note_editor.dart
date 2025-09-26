import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../services/db_service.dart';
import '../services/firebase_service.dart';

class NoteEditor extends StatefulWidget { const NoteEditor({super.key}); @override State<NoteEditor> createState() => _NoteEditorState(); }
class _NoteEditorState extends State<NoteEditor> {
  final _t=TextEditingController();
  final _c=TextEditingController();
  void _save() async {
    final id = const Uuid().v4();
    final note = {'id': id, 'title': _t.text, 'content': _c.text, 'color': 'yellow', 'lastModified': DateTime.now().millisecondsSinceEpoch};
    await DBService.instance.upsertNote(note);
    // sync remote
    await FirebaseService.instance.upsertNoteRemote(note);
    Navigator.of(context).pop(note);
  }
  @override Widget build(BuildContext c)=>Scaffold(appBar: AppBar(title: const Text('Nuova nota')), body: Padding(padding: const EdgeInsets.all(12), child: Column(children:[ TextField(controller: _t, decoration: const InputDecoration(hintText:'Titolo')), const SizedBox(height:8), Expanded(child: TextField(controller:_c, decoration: const InputDecoration(hintText:'Contenuto'), maxLines:null, expands:true)), ElevatedButton(onPressed:_save, child: const Text('Salva')) ]))); }
