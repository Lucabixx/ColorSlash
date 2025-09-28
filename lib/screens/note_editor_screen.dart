import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

class NoteEditorScreen extends StatefulWidget {
  final String noteId;
  final String type; // "note" o "list"

  const NoteEditorScreen({super.key, required this.noteId, required this.type});

  @override
  State<NoteEditorScreen> createState() => _NoteEditorScreenState();
}

class _NoteEditorScreenState extends State<NoteEditorScreen> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();
  List<String> _listItems = [];
  Color _noteColor = Colors.white;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadNote();
  }

  Future<File> _getNotesFile() async {
    final dir = await getApplicationDocumentsDirectory();
    return File("${dir.path}/notes.json");
  }

  Future<void> _loadNote() async {
    try {
      final file = await _getNotesFile();
      if (!await file.exists()) return;

      final decoded = jsonDecode(await file.readAsString());
      final notes = List<Map<String, dynamic>>.from(decoded);

      final existing = notes.firstWhere(
        (n) => n['id'] == widget.noteId,
        orElse: () => {},
      );

      if (existing.isNotEmpty) {
        setState(() {
          _titleController.text = existing['title'] ?? '';
          _contentController.text = existing['content'] ?? '';
          _noteColor = Color(existing['color'] ?? Colors.white.value);
          _listItems = List<String>.from(existing['listItems'] ?? []);
        });
      }
    } catch (e) {
      debugPrint("Errore caricamento nota: $e");
    }
  }

  Future<void> _saveNote() async {
    setState(() => _isLoading = true);

    final file = await _getNotesFile();
    List<Map<String, dynamic>> notes = [];

    if (await file.exists()) {
      try {
        final decoded = jsonDecode(await file.readAsString());
        notes = List<Map<String, dynamic>>.from(decoded);
      } catch (e) {
        notes = [];
      }
    }

    final newNote = {
      "id": widget.noteId,
      "type": widget.type,
      "title": _titleController.text.trim(),
      "content": _contentController.text.trim(),
      "listItems": _listItems,
      "color": _noteColor.value,
      "lastModified": DateTime.now().toIso8601String(),
    };

    // Se esiste, aggiorna — altrimenti aggiungi
    final index = notes.indexWhere((n) => n['id'] == widget.noteId);
    if (index != -1) {
      notes[index] = newNote;
    } else {
      notes.add(newNote);
    }

    await file.writeAsString(jsonEncode(notes));

    setState(() => _isLoading = false);

    if (context.mounted) {
      Navigator.pop(context, true);
    }
  }

  void _addListItem() {
    setState(() {
      _listItems.add("");
    });
  }

  Future<void> _pickColor() async {
    final selected = await showDialog<Color>(
      context: context,
      builder: (ctx) {
        Color current = _noteColor;
        return AlertDialog(
          title: const Text("Scegli un colore"),
          content: SingleChildScrollView(
            child: BlockPicker(
              pickerColor: current,
              onColorChanged: (c) => current = c,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, current),
              child: const Text("OK"),
            ),
          ],
        );
      },
    );

    if (selected != null) {
      setState(() => _noteColor = selected);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _noteColor.withOpacity(0.2),
      appBar: AppBar(
        title: Text(widget.type == "note" ? "Modifica Nota" : "Modifica Lista"),
        actions: [
          IconButton(
            icon: const Icon(Icons.color_lens),
            tooltip: "Cambia colore",
            onPressed: _pickColor,
          ),
          IconButton(
            icon: const Icon(Icons.save),
            tooltip: "Salva",
            onPressed: _isLoading ? null : _saveNote,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    TextField(
                      controller: _titleController,
                      decoration: const InputDecoration(
                        labelText: "Titolo",
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (widget.type == "note")
                      TextField(
                        controller: _contentController,
                        maxLines: 10,
                        decoration: const InputDecoration(
                          labelText: "Contenuto",
                          border: OutlineInputBorder(),
                        ),
                      )
                    else
                      Column(
                        children: [
                          for (int i = 0; i < _listItems.length; i++)
                            Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    onChanged: (v) =>
                                        _listItems[i] = v.trim(),
                                    decoration: InputDecoration(
                                      hintText: "Elemento ${i + 1}",
                                      border: const OutlineInputBorder(),
                                    ),
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete,
                                      color: Colors.redAccent),
                                  onPressed: () {
                                    setState(() {
                                      _listItems.removeAt(i);
                                    });
                                  },
                                ),
                              ],
                            ),
                          const SizedBox(height: 10),
                          ElevatedButton.icon(
                            onPressed: _addListItem,
                            icon: const Icon(Icons.add),
                            label: const Text("Aggiungi elemento"),
                          ),
                        ],
                      ),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      onPressed: _isLoading ? null : _saveNote,
                      icon: const Icon(Icons.check),
                      label: const Text("Salva"),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

// 🔹 Blocchi di colore per la selezione rapida
class BlockPicker extends StatelessWidget {
  final Color pickerColor;
  final ValueChanged<Color> onColorChanged;

  const BlockPicker({
    super.key,
    required this.pickerColor,
    required this.onColorChanged,
  });

  @override
  Widget build(BuildContext context) {
    final colors = [
      Colors.white,
      Colors.red,
      Colors.green,
      Colors.blue,
      Colors.yellow,
      Colors.orange,
      Colors.purple,
      Colors.teal,
      Colors.pink,
      Colors.cyan,
      Colors.grey,
    ];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: colors.map((color) {
        return GestureDetector(
          onTap: () => onColorChanged(color),
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color,
              border: Border.all(
                color: pickerColor == color ? Colors.black : Colors.grey,
                width: 2,
              ),
              borderRadius: BorderRadius.circular(6),
            ),
          ),
        );
      }).toList(),
    );
  }
}
