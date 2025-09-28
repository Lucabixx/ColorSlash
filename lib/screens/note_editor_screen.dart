import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

class NoteEditorScreen extends StatefulWidget {
  final String noteId;
  const NoteEditorScreen({super.key, required this.noteId});

  @override
  State<NoteEditorScreen> createState() => _NoteEditorScreenState();
}

class _NoteEditorScreenState extends State<NoteEditorScreen> {
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  bool _isNew = true;

  @override
  void initState() {
    super.initState();
    _loadNote();
  }

  Future<File> _getLocalFile() async {
    final dir = await getApplicationDocumentsDirectory();
    return File("${dir.path}/notes.json");
  }

  Future<List<Map<String, dynamic>>> _loadLocalNotes() async {
    final file = await _getLocalFile();
    if (!await file.exists()) return [];
    final content = await file.readAsString();
    final List data = jsonDecode(content);
    return data.cast<Map<String, dynamic>>();
  }

  Future<void> _saveLocalNotes(List<Map<String, dynamic>> notes) async {
    final file = await _getLocalFile();
    await file.writeAsString(jsonEncode(notes));
  }

  Future<void> _loadNote() async {
    final notes = await _loadLocalNotes();
    final existing = notes.firstWhere(
      (n) => n['id'] == widget.noteId,
      orElse: () => {},
    );

    if (existing.isNotEmpty) {
      setState(() {
        _isNew = false;
        _titleController.text = existing['title'] ?? '';
        _contentController.text = existing['content'] ?? '';
      });
    }
  }

  Future<void> _saveNote() async {
    final title = _titleController.text.trim();
    final content = _contentController.text.trim();
    if (title.isEmpty && content.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Nota vuota, nessun salvataggio")),
      );
      return;
    }

    final notes = await _loadLocalNotes();
    final timestamp = DateTime.now().millisecondsSinceEpoch;

    if (_isNew) {
      final id = const Uuid().v4();
      notes.add({
        "id": id,
        "title": title,
        "content": content,
        "updatedAt": timestamp,
      });
    } else {
      final index = notes.indexWhere((n) => n['id'] == widget.noteId);
      if (index != -1) {
        notes[index] = {
          "id": widget.noteId,
          "title": title,
          "content": content,
          "updatedAt": timestamp,
        };
      }
    }

    await _saveLocalNotes(notes);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Nota salvata localmente 💾")),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isNew ? "Nuova nota" : "Modifica nota"),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveNote,
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                hintText: "Titolo",
                border: InputBorder.none,
              ),
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const Divider(),
            Expanded(
              child: TextField(
                controller: _contentController,
                decoration: const InputDecoration(
                  hintText: "Scrivi qui...",
                  border: InputBorder.none,
                ),
                maxLines: null,
                expands: true,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
