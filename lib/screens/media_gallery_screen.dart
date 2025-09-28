import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:colorslash/utils/app_colors.dart';
import '../services/note_service.dart';
import '../models/note.dart';

class MediaGalleryScreen extends StatefulWidget {
  const MediaGalleryScreen({super.key});

  @override
  State<MediaGalleryScreen> createState() => _MediaGalleryScreenState();
}

class _MediaGalleryScreenState extends State<MediaGalleryScreen> {
  String search = "";
  String filterType = "tutti";

  @override
  Widget build(BuildContext context) {
    final noteService = Provider.of<NoteService>(context);

    // 🔹 Filtra note con media
    final allNotesWithMedia = noteService.notes.where((note) {
      final hasMedia = note.media != null && note.media!.isNotEmpty;
      if (!hasMedia) return false;

      final matchesSearch = note.title.toLowerCase().contains(search.toLowerCase()) ||
          note.content.toLowerCase().contains(search.toLowerCase());

      if (filterType == "tutti") return matchesSearch;

      final matchesType = note.media!.any((m) => m['type'] == filterType);
      return matchesSearch && matchesType;
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text("Galleria Media"),
        backgroundColor: AppColors.primaryDark,
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_alt_outlined),
            tooltip: "Filtra per tipo",
            onSelected: (val) => setState(() => filterType = val),
            itemBuilder: (_) => const [
              PopupMenuItem(value: "tutti", child: Text("Tutti")),
              PopupMenuItem(value: "image", child: Text("Solo Foto")),
              PopupMenuItem(value: "video", child: Text("Solo Video")),
              PopupMenuItem(value: "audio", child: Text("Solo Audio")),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // 🔹 Barra di ricerca
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              onChanged: (val) => setState(() => search = val),
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: "Cerca nelle note...",
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

          // 🔹 Galleria
          Expanded(
            child: allNotesWithMedia.isEmpty
                ? const Center(
                    child: Text(
                      "Nessun media trovato",
                      style: TextStyle(color: Colors.white54),
                    ),
                  )
                : GridView.builder(
                    padding: const EdgeInsets.all(12),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 0.9,
                    ),
                    itemCount: allNotesWithMedia.length,
                    itemBuilder: (context, i) {
                      final note = allNotesWithMedia[i];
                      final firstMedia = note.media!.first;

                      IconData icon;
                      switch (firstMedia['type']) {
                        case "image":
                          icon = Icons.image_outlined;
                          break;
                        case "video":
                          icon = Icons.videocam_outlined;
                          break;
                        case "audio":
                          icon = Icons.mic_none_outlined;
                          break;
                        default:
                          icon = Icons.insert_drive_file_outlined;
                      }

                      return GestureDetector(
                        onTap: () {
                          // 🔹 Qui potrai aprire il dettaglio o il visualizzatore media
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          decoration: BoxDecoration(
                            color: note.color.withOpacity(0.25),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: AppColors.primaryLight.withOpacity(0.4),
                              width: 1.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primaryDark.withOpacity(0.25),
                                blurRadius: 10,
                                offset: const Offset(2, 4),
                              ),
                            ],
                          ),
                          child: Stack(
                            children: [
                              Positioned.fill(
                                child: Padding(
                                  padding: const EdgeInsets.all(10),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(icon,
                                          color: AppColors.primaryLight, size: 48),
                                      const SizedBox(height: 10),
                                      Text(
                                        note.title,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        "${note.media!.length} elemento/i",
                                        style: const TextStyle(
                                          color: Colors.white54,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
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
    );
  }
}
