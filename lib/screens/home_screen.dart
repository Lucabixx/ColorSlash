import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/note_service.dart';
import '../models/note.dart';
import 'login_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String search = "";

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthService>(context);
    final noteService = Provider.of<NoteService>(context);

    final filteredNotes = noteService.notes
        .where((n) =>
            n.title.toLowerCase().contains(search.toLowerCase()) ||
            n.content.toLowerCase().contains(search.toLowerCase()))
        .toList();

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        title: const Text("Color Slash"),
        backgroundColor: Colors.deepPurpleAccent,
        actions: [
          IconButton(
            icon: const Icon(Icons.sync),
            tooltip: "Sincronizza con Cloud",
            onPressed: () => auth.syncWithCloud(context),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: "Esci",
            onPressed: () async {
              await auth.signOut();
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const LoginScreen()),
                (_) => false,
              );
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.redAccent,
        child: const Icon(Icons.add, size: 30),
        onPressed: () async {
          final newNote = await _showNoteDialog(context);
          if (newNote != null) noteService.addNote(newNote);
        },
      ),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            TextField(
              decoration: InputDecoration(
                hintText: "Cerca note...",
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.white10,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide.none,
                ),
              ),
              style: const TextStyle(color: Colors.white),
              onChanged: (val) => setState(() => search = val),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: filteredNotes.isEmpty
                  ? const Center(
                      child: Text(
                        "Nessuna nota trovata.\nTocca '+' per aggiungerne una!",
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white70, fontSize: 16),
                      ),
                    )
                  : GridView.builder(
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 4 / 3,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                      ),
                      itemCount: filteredNotes.length,
                      itemBuilder: (context, index) {
                        final note = filteredNotes[index];
                        return GestureDetector(
                          onTap: () async {
                            final updated = await _showNoteDialog(
                              context,
                              existing: note,
                            );
                            if (updated != null) {
                              noteService.updateNote(note.id, updated);
                            }
                          },
                          onLongPress: () =>
                              noteService.deleteNote(note.id, context),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: note.color,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: note.color.withOpacity(0.3),
                                  blurRadius: 8,
                                  spreadRadius: 2,
                                )
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _highlight(note.title, search),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Expanded(
                                  child: SingleChildScrollView(
                                    child: Text(
                                      _highlight(note.content, search),
                                      style: const TextStyle(
                                        color: Colors.white70,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  /// Mostra un dialog per creare o modificare una nota
  Future<Note?> _showNoteDialog(BuildContext context, {Note? existing}) {
    final titleCtrl = TextEditingController(text: existing?.title ?? '');
    final contentCtrl = TextEditingController(text: existing?.content ?? '');
    Color color = existing?.color ?? Colors.deepPurpleAccent;

    return showDialog<Note>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1E1E2C),
          title: Text(
            existing == null ? "Nuova nota" : "Modifica nota",
            style: const TextStyle(color: Colors.white),
          ),
          content: SingleChildScrollView(
            child: Column(
              children: [
                TextField(
                  controller: titleCtrl,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    hintText: "Titolo",
                    hintStyle: TextStyle(color: Colors.white54),
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: contentCtrl,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    hintText: "Contenuto",
                    hintStyle: TextStyle(color: Colors.white54),
                  ),
                  maxLines: 5,
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 10,
                  children: [
                    for (final c in [
                      Colors.deepPurpleAccent,
                      Colors.tealAccent,
                      Colors.pinkAccent,
                      Colors.amberAccent,
                      Colors.blueAccent,
                      Colors.greenAccent,
                      Colors.redAccent,
                    ])
                      GestureDetector(
                        onTap: () => setState(() => color = c),
                        child: CircleAvatar(
                          backgroundColor: c,
                          radius: 14,
                          child: color == c
                              ? const Icon(Icons.check, color: Colors.black)
                              : null,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Annulla", style: TextStyle(color: Colors.white54)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurpleAccent,
              ),
              onPressed: () {
                if (titleCtrl.text.isEmpty) return;
                Navigator.pop(
                  context,
                  Note(
                    id: existing?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
                    title: titleCtrl.text,
                    content: contentCtrl.text,
                    color: color,
                  ),
                );
              },
              child: Text(existing == null ? "Crea" : "Salva"),
            ),
          ],
        );
      },
    );
  }

  /// Evidenzia la parte cercata
  String _highlight(String text, String query) {
    if (query.isEmpty) return text;
    final regex = RegExp(query, caseSensitive: false);
    return text.replaceAllMapped(
      regex,
      (match) => '🔍${match.group(0)}',
    );
  }
}
