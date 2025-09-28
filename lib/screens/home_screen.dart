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
    ),

floatingActionButton: Container(
  decoration: BoxDecoration(
    shape: BoxShape.circle,
    boxShadow: [
      BoxShadow(
        color: AppColors.primaryLight.withOpacity(0.8),
        blurRadius: 20,
        spreadRadius: 4,
      ),
      BoxShadow(
        color: AppColors.primaryDark.withOpacity(0.6),
        blurRadius: 40,
        spreadRadius: 10,
      ),
    ],
  ),
  child: FloatingActionButton(
    backgroundColor: AppColors.primary,
    elevation: 14,
    child: ShaderMask(
      shaderCallback: (bounds) => const LinearGradient(
        colors: [
          AppColors.primaryLight,
          AppColors.primary,
          AppColors.primaryDark,
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(bounds),
      child: const Icon(Icons.add, size: 34, color: Colors.white),
    ),
    onPressed: () {
      showModalBottomSheet(
        backgroundColor: AppColors.surface,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        context: context,
        builder: (ctx) {
          return Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.note_add, color: AppColors.primaryLight),
                  title: const Text('Nuova Nota'),
                  onTap: () {
                    Navigator.pop(ctx);
                    _addOrEditNote({'type': 'note'});
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.checklist, color: AppColors.primaryLight),
                  title: const Text('Nuova Lista'),
                  onTap: () {
                    Navigator.pop(ctx);
                    _addOrEditNote({'type': 'list'});
                  },
                ),
                const SizedBox(height: 10),
              ],
            ),
          );
        },
      );
    },
  ),
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

