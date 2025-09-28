import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/note_service.dart';

class NoteEditorScreen extends StatefulWidget {
  final String noteId;
  final String type;

  const NoteEditorScreen({
    super.key,
    required this.noteId,
    required this.type,
  });

  @override
  State<NoteEditorScreen> createState() => _NoteEditorScreenState();
}

class _NoteEditorScreenState extends State<NoteEditorScreen> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();
  Color _selectedColor = Colors.white;

  @override
  void initState() {
    super.initState();
    final noteService = Provider.of<NoteService>(context, listen: false);
    final existing = noteService.notes.firstWhere(
      (n) => n['id'] == widget.noteId,
      orElse: () => {},
    );
    if (existing.isNotEmpty) {
      _titleController.text = existing['title'] ?? '';
      _contentController.text = existing['content'] ?? '';
      _selectedColor = Color(existing['color'] ?? Colors.white.value);
    }
  }

  Future<void> _saveNote() async {
    final noteService = Provider.of<NoteService>(context, listen: false);
    final now = DateTime.now().millisecondsSinceEpoch;

    final note = {
      'id': widget.noteId,
      'type': widget.type,
      'title': _titleController.text.trim(),
      'content': _contentController.text.trim(),
      'color': _selectedColor.value,
      'updatedAt': now,
    };

    await noteService.addOrUpdate(note);
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.type == 'note' ? "Modifica Nota" : "Modifica Lista"),
        actions: [
          IconButton(icon: const Icon(Icons.save), onPressed: _saveNote),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: "Titolo"),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: TextField(
                controller: _contentController,
                decoration: const InputDecoration(labelText: "Contenuto"),
                maxLines: null,
                expands: true,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: [
                for (final c in [
                  Colors.white,
                  Colors.red,
                  Colors.green,
                  Colors.blue,
                  Colors.yellow,
                  Colors.purple
                ])
                  GestureDetector(
                    onTap: () => setState(() => _selectedColor = c),
                    child: Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        color: c,
                        shape: BoxShape.circle,
                        border: Border.all(
                            color: _selectedColor == c ? Colors.black : Colors.grey,
                            width: 2),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
