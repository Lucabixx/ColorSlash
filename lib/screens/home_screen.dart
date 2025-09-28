import 'package:colorslash/screens/media_gallery_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:colorslash/utils/app_colors.dart';
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
  String filterType = "tutti";

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
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF001F3F), Color(0xFF004080), Color(0xFF0074D9)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          children: [
            AppBar(
              title: const Text("ColorSlash"),
              backgroundColor: Colors.transparent,
              elevation: 0,
              actions: [
                IconButton(
                  icon: const Icon(Icons.photo_library_outlined),
                  tooltip: "Galleria Media",
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const MediaGalleryScreen()),
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
                  fillColor: AppColors.surface.withOpacity(0.5),
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
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 500),
                          curve: Curves.easeOut,
                          margin: const EdgeInsets.symmetric(vertical: 6),
                          decoration: BoxDecoration(
                            color: note.color.withOpacity(0.25),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: AppColors.metallicShadow,
                          ),
                          child: ListTile(
                            title: Text(
                              note.title,
                              style: const TextStyle(color: Colors.white),
                            ),
                            subtitle: Text(
                              note.content,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(color: Colors.white70),
                            ),
                            onTap: () => _addOrEditNote(note.toJson()),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
      floatingActionButton: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: AppColors.metallicShadow,
        ),
        child: FloatingActionButton(
          backgroundColor: AppColors.primary,
          elevation: 14,
          child: ShaderMask(
            shaderCallback: (bounds) => AppColors.metallicGradient.createShader(bounds),
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
                        leading: const Icon(Icons.note_add,
                            color: AppColors.primaryLight),
                        title: const Text('Nuova Nota'),
                        onTap: () {
                          Navigator.pop(ctx);
                          _addOrEditNote({'type': 'note'});
                        },
                      ),
                      ListTile(
                        leading: const Icon(Icons.checklist,
                            color: AppColors.primaryLight),
                        title: const Text('Nuova Lista'),
                        onTap: () {
                          Navigator.pop(ctx);
                          _addOrEditNote({'type': 'list'});
                        },
                      ),
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

  Future<void> _addOrEditNote(Map<String, dynamic> noteData) async {
    // TODO: collegare al tuo NoteEditorScreen
  }
}
