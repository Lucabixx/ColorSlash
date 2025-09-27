import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:signature/signature.dart';
import 'package:video_player/video_player.dart';
import '../services/cloud_service.dart';
import '../services/local_storage.dart';

class NoteEditorScreen extends StatefulWidget {
  final String type; // "note" o "list"
  const NoteEditorScreen({super.key, required this.type});

  @override
  State<NoteEditorScreen> createState() => _NoteEditorScreenState();
}

class _NoteEditorScreenState extends State<NoteEditorScreen> {
  final TextEditingController _controller = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  final FlutterSoundRecorder _recorder = FlutterSoundRecorder();
  final List<File> _media = [];
  late SignatureController _sigController;

  @override
  void initState() {
    super.initState();
    _sigController = SignatureController(penColor: Colors.blueAccent);
    _recorder.openRecorder();
  }

  @override
  void dispose() {
    _sigController.dispose();
    _recorder.closeRecorder();
    super.dispose();
  }

  Future<void> _addImage() async {
    final XFile? picked =
        await _picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() => _media.add(File(picked.path)));
      await CloudService.uploadMedia(File(picked.path));
    }
  }

  Future<void> _addVideo() async {
    final XFile? picked =
        await _picker.pickVideo(source: ImageSource.gallery);
    if (picked != null) {
      setState(() => _media.add(File(picked.path)));
      await CloudService.uploadMedia(File(picked.path));
    }
  }

  Future<void> _recordAudio() async {
    final tempDir = Directory.systemTemp;
    final filePath = '${tempDir.path}/record_${DateTime.now().millisecondsSinceEpoch}.aac';
    await _recorder.startRecorder(toFile: filePath);
    await Future.delayed(const Duration(seconds: 3));
    await _recorder.stopRecorder();
    setState(() => _media.add(File(filePath)));
    await CloudService.uploadMedia(File(filePath));
  }

  void _saveNote() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    LocalStorage.saveNote({
      'text': text,
      'type': widget.type,
      'timestamp': DateTime.now().toIso8601String(),
    });
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.type == "note" ? "Nuova Nota" : "Nuova Lista"),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveNote,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _controller,
              maxLines: null,
              decoration: const InputDecoration(
                hintText: "Scrivi qui...",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              children: [
                IconButton(
                  icon: const Icon(Icons.mic, color: Colors.red),
                  onPressed: _recordAudio,
                ),
                IconButton(
                  icon: const Icon(Icons.image, color: Colors.green),
                  onPressed: _addImage,
                ),
                IconButton(
                  icon: const Icon(Icons.videocam, color: Colors.blue),
                  onPressed: _addVideo,
                ),
                IconButton(
                  icon: const Icon(Icons.edit, color: Colors.orange),
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (_) => AlertDialog(
                        content: SizedBox(
                          width: double.infinity,
                          height: 300,
                          child: Signature(
                            controller: _sigController,
                            backgroundColor: Colors.white,
                          ),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () async {
                              final data = await _sigController.toPngBytes();
                              if (data != null) {
                                final file = File(
                                    '${Directory.systemTemp.path}/sketch_${DateTime.now().millisecondsSinceEpoch}.png');
                                await file.writeAsBytes(data);
                                setState(() => _media.add(file));
                                await CloudService.uploadMedia(file);
                              }
                              Navigator.pop(context);
                            },
                            child: const Text("Salva"),
                          )
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            ..._media.map((f) {
              if (f.path.endsWith(".png") || f.path.endsWith(".jpg")) {
                return Image.file(f, height: 150);
              } else if (f.path.endsWith(".mp4")) {
                final controller = VideoPlayerController.file(f);
                controller.initialize();
                return SizedBox(
                    height: 150,
                    child: VideoPlayer(controller)
                );
              } else {
                return ListTile(
                  leading: const Icon(Icons.audiotrack),
                  title: Text(f.path.split("/").last),
                );
              }
            }).toList(),
          ],
        ),
      ),
    );
  }
}
