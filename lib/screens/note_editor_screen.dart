// lib/screens/note_editor_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:audioplayers/audioplayers.dart';
import '../services/cloud_service.dart';
import '../services/local_storage.dart';

class NoteEditorScreen extends StatefulWidget {
  final String noteId;
  final bool isList;

  const NoteEditorScreen({
    super.key,
    required this.noteId,
    this.isList = false,
  });

  @override
  State<NoteEditorScreen> createState() => _NoteEditorScreenState();
}

class _NoteEditorScreenState extends State<NoteEditorScreen> {
  final TextEditingController _controller = TextEditingController();
  final List<Map<String, dynamic>> _attachments = [];
  bool _busy = false;
  late final String _id;
  final AudioPlayer _player = AudioPlayer();

  @override
  void initState() {
    super.initState();
    _id = widget.noteId;
    _loadNote();
  }

  Future<void> _loadNote() async {
    final note = await LocalStorage.loadNote(_id);
    if (note != null) {
      _controller.text = note['text'] ?? '';
      final atts = note['attachments'];
      if (atts is List) {
        setState(() {
          _attachments.addAll(List<Map<String, dynamic>>.from(atts));
        });
      }
    }
  }

  Future<void> _pickMedia({required String type}) async {
    final picker = ImagePicker();
    XFile? file;

    try {
      if (type == 'image') {
        file = await picker.pickImage(source: ImageSource.gallery);
      } else if (type == 'camera') {
        file = await picker.pickImage(source: ImageSource.camera);
      } else if (type == 'video') {
        file = await picker.pickVideo(source: ImageSource.gallery);
      } else if (type == 'record') {
        // TODO: Implementare audio recorder
        return;
      }
    } catch (e) {
      _showSnack("Errore durante la selezione: $e");
      return;
    }

    if (file == null) return;

    setState(() {
      _attachments.add({'type': type, 'localPath': file!.path});
    });
  }

  Future<void> _saveAndUpload() async {
    if (_busy) return;
    setState(() => _busy = true);

    final noteData = {
      'id': _id,
      'type': 'nota',
      'text': _controller.text,
      'attachments': _attachments,
      'timestamp': DateTime.now().toIso8601String(),
    };

    await LocalStorage.saveNote(_id, noteData);

    // Upload di ogni media
    for (int i = 0; i < _attachments.length; i++) {
      final a = _attachments[i];
      if (a.containsKey('remoteUrl')) continue;

      final lp = a['localPath'] as String?;
      if (lp == null) continue;

      double progress = 0.0;
      try {
        final url = await CloudService.uploadMedia(
          File(lp),
          _id,
          onProgress: (p) {
            progress = p;
            setState(() => _attachments[i]['uploadProgress'] = progress);
          },
        );
        a['remoteUrl'] = url;
        a.remove('uploadProgress');
        await LocalStorage.saveNote(_id, {
          'id': _id,
          'type': 'nota',
          'text': _controller.text,
          'attachments': _attachments,
          'timestamp': DateTime.now().toIso8601String(),
        });
      } catch (e) {
        _attachments[i]['uploadProgress'] = -1.0;
        debugPrint("Upload fallito per $lp : $e");
      }
    }

    await CloudService.backupNote({
      'id': _id,
      'type': 'nota',
      'text': _controller.text,
      'attachments': _attachments,
      'timestamp': DateTime.now().toIso8601String(),
    });

    setState(() => _busy = false);
    _showSnack("Salvataggio e upload completati ✅");
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: Colors.blueGrey.shade700,
    ));
  }

  Widget _buildAttachment(Map<String, dynamic> a, int index) {
    final type = a['type'] ?? '';
    final lp = a['localPath'] as String?;
    final url = a['remoteUrl'] as String?;
    final progress = a['uploadProgress'];

    Widget? content;
    if (type == 'image' || type == 'camera') {
      content = Image.file(File(lp!), fit: BoxFit.cover, height: 150);
    } else if (type == 'video') {
      content = Container(
        height: 150,
        color: Colors.black26,
        alignment: Alignment.center,
        child: const Icon(Icons.videocam, size: 48, color: Colors.white),
      );
    } else if (type == 'record') {
      content = IconButton(
        icon: const Icon(Icons.play_arrow),
        onPressed: () {
          if (lp != null) _player.play(DeviceFileSource(lp));
        },
      );
    }

    return Column(
      children: [
        ListTile(
          leading: Icon(Icons.attach_file, color: Colors.blueGrey.shade600),
          title: content,
          subtitle: progress != null
              ? (progress == -1.0
                  ? const Text("❌ Upload fallito — riprova", style: TextStyle(color: Colors.red))
                  : LinearProgressIndicator(value: progress))
              : (url != null ? Text("✅ Upload completato") : null),
          trailing: IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () => setState(() => _attachments.removeAt(index)),
          ),
        ),
        const Divider(height: 1),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Modifica Nota"),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveAndUpload,
          ),
        ],
      ),
      body: Stack(
        children: [
          Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      TextField(
                        controller: _controller,
                        maxLines: null,
                        decoration: const InputDecoration(
                          hintText: "Scrivi qui la tua nota...",
                          border: InputBorder.none,
                        ),
                      ),
                      const SizedBox(height: 12),
                      for (int i = 0; i < _attachments.length; i++)
                        _buildAttachment(_attachments[i], i),
                    ],
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                color: Colors.blueGrey.shade100,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    IconButton(
                      tooltip: 'Immagine',
                      icon: const Icon(Icons.image),
                      onPressed: () => _pickMedia(type: 'image'),
                    ),
                    IconButton(
                      tooltip: 'Fotocamera',
                      icon: const Icon(Icons.camera_alt),
                      onPressed: () => _pickMedia(type: 'camera'),
                    ),
                    IconButton(
                      tooltip: 'Video',
                      icon: const Icon(Icons.videocam),
                      onPressed: () => _pickMedia(type: 'video'),
                    ),
                    IconButton(
                      tooltip: 'Audio',
                      icon: const Icon(Icons.mic),
                      onPressed: () => _pickMedia(type: 'record'),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (_busy)
            Container(
              color: Colors.black45,
              child: const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
            ),
        ],
      ),
    );
  }
}
