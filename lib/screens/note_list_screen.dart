import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/note_service.dart';
import 'note_editor_screen.dart';

class NoteListScreen extends StatefulWidget {
  const NoteListScreen({super.key});
  @override
  State<NoteListScreen> createState() => _NoteListScreenState();
}

class _NoteListScreenState extends State<NoteListScreen> {
  String _searchQuery = '';

  Widget _highlightText(String text, String query) {
    if (query.isEmpty) return Text(text);
    final lowerText = text.toLowerCase();
    final lowerQuery = query.toLowerCase();
    final spans = <TextSpan>[];
    int start = 0;
    while (true) {
      final idx = lowerText.indexOf(lowerQuery, start);
      if (idx == -1) {
        spans.add(TextSpan(text: text.substring(start)));
        break;
      }
      if (idx > start) spans.add(TextSpan(text: text.substring(start, idx)));
      spans.add(TextSpan(
        text: text.substring(idx, idx + query.length),
        style: const TextStyle(
          backgroundColor: Colors.yellow,
          fontWeight: FontWeight.bold,
        ),
      ));
      start = idx + query.length;
    }
    return RichText(text: TextSpan(style: const TextStyle(color: Colors.white), children: spans));
  }

  @override
  Widget build(BuildContext context) {
    final noteService = Provider.of<NoteService>(context);
    final notes = noteService.notes.where((n) {
      final q = _searchQuery.toLowerCase();
      final title = (n['title'] ?? '').toString().toLowerCase();
      final content = (n['content'] ?? '').toString().toLowerCase();
      return title.contains(q) || content.contains(q);
    }).toList();

    return Scaffold(
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: 'Cerca...',
              ),
              onChanged: (v) => setState(() => _searchQuery = v),
            ),
          ),
          Expanded(
            child: notes.isEmpty
                ? const Center(child: Text('Nessuna nota trovata'))
                : ListView.builder(
                    itemCount: notes.length,
                    itemBuilder: (context, i) {
                      final n = notes[i];
                      return ListTile(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => NoteEditorScreen(
                                noteId: n['id'],
                                type: n['type'] ?? 'note',
                              ),
                            ),
                          );
                        },
                        leading: CircleAvatar(
                          backgroundColor: Color(n['color'] ?? Colors.white.value),
                        ),
                        title: _highlightText(n['title'] ?? '', _searchQuery),
                        subtitle: _highlightText(n['content'] ?? '', _searchQuery),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () {
                            noteService.delete(n['id']);
                          },
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: PopupMenuButton<String>(
        icon: const Icon(Icons.add),
        onSelected: (type) {
          final id = DateTime.now().millisecondsSinceEpoch.toString();
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => NoteEditorScreen(noteId: id, type: type),
            ),
          );
        },
        itemBuilder: (_) => const [
          PopupMenuItem(value: 'note', child: Text("Nuova Nota")),
          PopupMenuItem(value: 'list', child: Text("Nuova Lista")),
        ],
      ),
    );
  }
}
