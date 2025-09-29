import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ColorSlash/models/note_model.dart';
import 'package:ColorSlash/services/auth_service.dart';
import 'package:ColorSlash/utils/app_colors.dart';
import 'package:ColorSlash/screens/note_editor_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final AuthService auth;
  late final FirebaseFirestore db;

  @override
  void initState() {
    super.initState();
    auth = context.read<AuthService>();
    db = FirebaseFirestore.instance;
  }

  Future<void> _createNewNote(BuildContext context) async {
    final newNote = NoteModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      type: 'note',
      title: '',
      content: '',
      colorHex: AppColors.noteColors.first.value.toRadixString(16),
      updatedAt: DateTime.now(),
      attachments: [],
    );

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => NoteEditorScreen(
          existingNote: newNote,
          type: 'note',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = auth.currentUser;

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: const Text("ColorSlash"),
        backgroundColor: AppColors.primary,
        actions: [
          IconButton(
            tooltip: "Sincronizza con il Cloud",
            icon: const Icon(Icons.cloud_sync),
            onPressed: () => auth.syncWithCloud(context),
          ),
          IconButton(
            tooltip: "Logout",
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await auth.signOut();
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Logout eseguito")),
              );
            },
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: db
            .collection('notes')
            .where('userId', isEqualTo: user?.uid ?? '')
            .orderBy('updatedAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(
              child: Text('❌ Errore nel caricamento delle note'),
            );
          }

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final notes = snapshot.data!.docs.map((d) => NoteModel.fromDoc(d)).toList();

          if (notes.isEmpty) {
            return const Center(child: Text('📝 Nessuna nota presente'));
          }

          return GridView.builder(
            padding: const EdgeInsets.all(12),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: notes.length,
            itemBuilder: (context, i) {
              final note = notes[i];
              final color = Color(
                int.tryParse(note.colorHex.replaceAll("#", "0xFF")) ?? 0xFF2979FF,
              );

              return GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => NoteEditorScreen(
                      existingNote: note,
                      type: note.type,
                    ),
                  ),
                ),
                child: Container(
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: AppColors.metallicShadow,
                  ),
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        note.title.isNotEmpty ? note.title : "(senza titolo)",
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Expanded(
                        child: Text(
                          note.content,
                          maxLines: 6,
                          overflow: TextOverflow.fade,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      if (note.attachments.isNotEmpty)
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: note.attachments.map((a) {
                            if (a.type == 'image' && a.url.isNotEmpty) {
                              try {
                                return ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.file(
                                    File(a.url),
                                    width: 40,
                                    height: 40,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) =>
                                        const Icon(Icons.broken_image, color: Colors.white),
                                  ),
                                );
                              } catch (_) {
                                return const Icon(Icons.broken_image, color: Colors.white);
                              }
                            } else {
                              return const Icon(Icons.attach_file, color: Colors.white);
                            }
                          }).toList(),
                        ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primary,
        onPressed: () => _createNewNote(context),
        child: const Icon(Icons.add),
      ),
    );
  }
}
