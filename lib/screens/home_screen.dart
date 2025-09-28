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
  String filterType = "tutti"; // 🔹 filtro media

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
          // 🔹 Galleria media
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

          // 🔹 Filtro per tipo
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_alt_outlined),
            onSelected: (val) => setState(() => filterType = val),
            itemBuilder: (_) => [
              const PopupMenuItem(value: "tutti", child: Text("Tutti")),
              const PopupMenuItem(value: "note", child: Text("Solo Note")),
              const PopupMenuItem(value: "list", child: Text("Solo Liste")),
            ],
          ),

          // 🔹 Sincronizza
          IconButton(
            icon: const Icon(Icons.sync),
            tooltip: "Sincronizza con Cloud",
            onPressed: () => auth.syncWithCloud(context),
          ),

          // 🔹 Logout
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

      // 🔹 Corpo
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
                      return Card(
                        color: note.color.withOpacity(0.25),
                        margin: const EdgeInsets.symmetric(vertical: 6),
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

      // 🔹 FAB con ombre 3D
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
    );
  }

  /// 🔹 Crea o modifica nota
  Future<void> _addOrEditNote(Map<String, dynamic> noteData) async {
    // Apri l’editor (usa il tuo NoteEditorScreen)
    // Navigator.push(...);
  }
}
