import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:colorslash/utils/app_colors.dart';
import 'package:colorslash/screens/media_gallery_screen.dart';
import 'package:colorslash/screens/note_editor_screen.dart';
import '../services/auth_service.dart';
import '../services/note_service.dart';
import '../models/note_model.dart';
import 'login_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String search = "";
  String filterType = "tutti";
  bool _isSyncing = false;

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthService>(context);
    final noteService = Provider.of<NoteService>(context);

    final filteredNotes = noteService.notes.where((n) {
      final matchesSearch = n.title.toLowerCase().contains(search.toLowerCase()) ||
          n.content.toLowerCase().contains(search.toLowerCase());
      final matchesType = filterType == "tutti" || n.type == filterType;
      return matchesSearch && matchesType;
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text("ColorSlash"),
        backgroundColor: AppColors.primaryDark,
        actions: [
          IconButton(
            icon: const Icon(Icons.photo_library_outlined),
            tooltip: "Galleria Media",
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const MediaGalleryScreen()),
              );
            },
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_alt_outlined),
            onSelected: (val) => setState(() => filterType = val),
            itemBuilder: (_) => const [
              PopupMenuItem(value: "tutti", child: Text("Tutti")),
              PopupMenuItem(value: "note", child: Text("Solo Note")),
              PopupMenuItem(value: "list", child: Text("Solo Liste")),
            ],
          ),
          if (auth.currentUser != null)
            IconButton(
              icon: _isSyncing
                  ? const Padding(
                      padding: EdgeInsets.all(8.0),
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.sync),
              tooltip: "Sincronizza con Cloud",
              onPressed: () async {
                setState(() => _isSyncing = true);
                await noteService.syncWithCloud(auth);
                setState(() => _isSyncing = false);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Sincronizzazione completata")),
                  );
                }
              },
            ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: "Esci",
            onPressed: () async {
              await auth.signOut();
              if (context.mounted) {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                  (_) => false,
                );
              }
            },
          ),
        ],
      ),

      // 🔹 Corpo principale
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              onChanged: (val) => setState(() => search = val),
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: "Cerca note o liste...",
                hintStyle: const TextStyle(color: Colors.white54),
                prefixIcon: const Icon(Icons.search, color: Colors.white70),
                filled: true,
                fillColor: AppColors.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),

          Expanded(
            child: filteredNotes.isEmpty
                ? const Center(
                    child: Text(
                      "Nessuna nota trovata",
                      style: TextStyle(color: Colors.white54),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(10),
                    itemCount: filteredNotes.length,
                    itemBuilder: (context, i) {
                      final note = filteredNotes[i];
                      final color = Color(
                        int.parse(note.colorHex.replaceFirst('#', '0x')),
                      );

                      return Card(
                        color: color.withOpacity(0.25),
                        margin: const EdgeInsets.symmetric(vertical: 6),
                        child: ListTile(
                          title: Text(
                            note.title.isEmpty ? "(Senza titolo)" : note.title,
                            style: const TextStyle(color: Colors.white, fontSize: 18),
                          ),
                          subtitle: Text(
                            note.content.isEmpty
                                ? "Nessun contenuto"
                                : note.content.split('\n').take(2).join('\n'),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: Colors.white70),
                          ),

                          // 👆 Tocco singolo → apre l’editor
                          onTap: () => _openEditor(note),

                          // ✋ Pressione lunga → anteprima
                          onLongPress: () => _showPreview(note),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),

      // 🔹 Floating Action Button (nuova nota/lista)
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
                          _createNewNote("note");
                        },
                      ),
                      ListTile(
                        leading: const Icon(Icons.checklist, color: AppColors.primaryLight),
                        title: const Text('Nuova Lista'),
                        onTap: () {
                          Navigator.pop(ctx);
                          _createNewNote("list");
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
    );
  }

  /// 🔹 Crea una nuova nota
  Future<void> _createNewNote(String type) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => NoteEditorScreen(type: type),
      ),
    );
  }

  /// 🔹 Apre una nota esistente
  Future<void> _openEditor(NoteModel note) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => NoteEditorScreen(
          existingNote: note,
          type: note.type,
        ),
      ),
    );
  }

  /// 🔹 Mostra anteprima (brevi contenuti + immagini)
  void _showPreview(NoteModel note) {
    showModalBottomSheet(
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      context: context,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                note.title.isEmpty ? "(Senza titolo)" : note.title,
                style: const TextStyle(
                  color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              Text(
                note.content.isEmpty
                    ? "Nessun contenuto"
                    : note.content.split('\n').take(6).join('\n'),
                style: const TextStyle(color: Colors.white70, fontSize: 16),
              ),
              const SizedBox(height: 16),

              if (note.attachments.isNotEmpty)
                SizedBox(
                  height: 100,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: note.attachments
                        .where((a) => a.type == "image")
                        .map((a) => Padding(
                              padding: const EdgeInsets.only(right: 10),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: File(a.url).existsSync()
                                    ? Image.file(
                                        File(a.url),
                                        height: 100,
                                        width: 100,
                                        fit: BoxFit.cover,
                                      )
                                    : Container(
                                        height: 100,
                                        width: 100,
                                        color: Colors.grey[800],
                                        child: const Icon(Icons.broken_image,
                                            color: Colors.white38),
                                      ),
                              ),
                            ))
                        .toList(),
                  ),
                ),

              const SizedBox(height: 20),
              Center(
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.open_in_new),
                  label: const Text("Apri nota completa"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: () {
                    Navigator.pop(ctx);
                    _openEditor(note);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
