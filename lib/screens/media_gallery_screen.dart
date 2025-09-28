import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:colorslash/widgets/media_viewer.dart';
import 'package:colorslash/utils/app_colors.dart';

class MediaGalleryScreen extends StatefulWidget {
  const MediaGalleryScreen({super.key});

  @override
  State<MediaGalleryScreen> createState() => _MediaGalleryScreenState();
}

class _MediaGalleryScreenState extends State<MediaGalleryScreen> {
  List<Map<String, dynamic>> _media = [];

  @override
  void initState() {
    super.initState();
    _loadAllMedia();
  }

  Future<File> _getNotesFile() async {
    final dir = await getApplicationDocumentsDirectory();
    return File("${dir.path}/notes.json");
  }

  Future<void> _loadAllMedia() async {
    final file = await _getNotesFile();
    if (!await file.exists()) return;
    final notes = List<Map<String, dynamic>>.from(jsonDecode(await file.readAsString()));

    final allMedia = <Map<String, dynamic>>[];
    for (final note in notes) {
      if (note['media'] != null) {
        for (final m in List<Map<String, dynamic>>.from(note['media'])) {
          allMedia.add({
            'type': m['type'],
            'path': m['path'],
            'noteTitle': note['title'] ?? '',
          });
        }
      }
    }

    setState(() => _media = allMedia);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Galleria Media'),
        backgroundColor: AppColors.primaryDark,
      ),
      body: _media.isEmpty
          ? const Center(
              child: Text('Nessun contenuto multimediale trovato'),
            )
          : GridView.builder(
              padding: const EdgeInsets.all(10),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 6,
                mainAxisSpacing: 6,
              ),
              itemCount: _media.length,
              itemBuilder: (context, index) {
                final m = _media[index];
                Widget thumb;
                if (m['type'] == 'image') {
                  thumb = Image.file(File(m['path']), fit: BoxFit.cover);
                } else if (m['type'] == 'video') {
                  thumb = Container(
                    color: Colors.black26,
                    child: const Icon(Icons.videocam, color: Colors.white),
                  );
                } else if (m['type'] == 'audio') {
                  thumb = Container(
                    color: Colors.black45,
                    child: const Icon(Icons.audiotrack, color: Colors.white),
                  );
                } else {
                  thumb = Container(color: Colors.grey);
                }

                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => MediaViewer(
                          media: _media,
                          initialIndex: index,
                        ),
                      ),
                    );
                  },
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        thumb,
                        if (m['noteTitle'] != null && m['noteTitle'].isNotEmpty)
                          Align(
                            alignment: Alignment.bottomCenter,
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 4),
                              color: Colors.black45,
                              child: Text(
                                m['noteTitle'],
                                style: const TextStyle(color: Colors.white, fontSize: 10),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
