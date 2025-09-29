import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:path_provider/path_provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:uuid/uuid.dart';

import '../models/note_model.dart';
import '../services/note_service.dart';
import '../utils/app_colors.dart';
import '../widgets/media_viewer.dart';
import '../widgets/sketch_pad.dart';

class NoteEditorScreen extends StatefulWidget {
  final NoteModel? existingNote;
  final String type;

  const NoteEditorScreen({
    super.key,
    this.existingNote,
    required this.type,
  });

  @override
  State<NoteEditorScreen> createState() => _NoteEditorScreenState();
}

class _NoteEditorScreenState extends State<NoteEditorScreen> {
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  final _picker = ImagePicker();
  final _recorder = FlutterSoundRecorder();

  List<Attachment> _attachments = [];
  Color _color = Colors.white;
  bool _isRecording = false;

  @override
  void initState() {
    super.initState();
    _recorder.openRecorder();

    // se esiste nota precedente, caricala
    if (widget.existingNote != null) {
      final n = widget.existingNote!;
      _titleController.text = n.title;
      _contentController.text = n.content;
      _color = Color(int.tryParse(n.colorHex.replaceFirst('#', '0xFF')) ?? 0xFF1E1E1E);
      _attachments = List.from(n.attachments);
    }
  }

  @override
  void dispose() {
    if (_recorder.isRecording) _recorder.stopRecorder();
    _recorder.closeRecorder();
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _saveNote() async {
    final noteService = context.read<NoteService>();
    final id = widget.existingNote?.id ?? const Uuid().v4();

    final note = NoteModel(
      id: id,
      type: widget.type,
      title: _titleController.text.trim(),
      content: _contentController.text.trim(),
      colorHex: '#${_color.value.toRadixString(16).padLeft(8, '0')}',
      updatedAt: DateTime.now(),
      attachments: _attachments,
    );

    await noteService.addOrUpdate(note);
  }

  Future<void> _pickImage() async {
    final img = await _picker.pickImage(source: ImageSource.gallery);
    if (img != null) {
      setState(() => _attachments.add(Attachment(type: 'image', url: img.path)));
    }
  }

  Future<void> _pickVideo() async {
    final video = await _picker.pickVideo(source: ImageSource.gallery);
    if (video != null) {
      setState(() => _attachments.add(Attachment(type: 'video', url: video.path)));
    }
  }

  Future<void> _toggleRecording() async {
    if (_isRecording) {
      final path = await _recorder.stopRecorder();
      if (path != null) {
        setState(() => _attachments.add(Attachment(type: 'audio', url: path)));
      }
    } else {
      final dir = await getTemporaryDirectory();
      final filePath = "${dir.path}/${DateTime.now().millisecondsSinceEpoch}.aac";
      await _recorder.startRecorder(toFile: filePath);
    }
    setState(() => _isRecording = !_isRecording);
  }

  Future<void> _openColorPicker() async {
    final selected = await showDialog<Color>(
      context: context,
      builder: (ctx) {
        Color selectedColor = _color;
        return AlertDialog(
          title: const Text('Scegli colore nota'),
          content: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: AppColors.noteColors.map((c) {
              return GestureDetector(
                onTap: () => selectedColor = c,
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: c,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: selectedColor == c ? AppColors.primaryLight : Colors.grey,
                      width: 2,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, selectedColor),
              child: const Text('Conferma'),
            ),
          ],
        );
      },
    );

    if (selected != null) setState(() => _color = selected);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _color.withOpacity(0.1),
      appBar: AppBar(
        title: Text(
          widget.existingNote == null
              ? "Nuova ${widget.type == 'list' ? 'Lista' : 'Nota'}"
              : "Modifica ${widget.type == 'list' ? 'Lista' : 'Nota'}",
        ),
        actions: [
          IconButton(icon: const Icon(Icons.color_lens), onPressed: _openColorPicker),
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: () async {
              await _saveNote();
              if (context.mounted) Navigator.pop(context, true);
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _titleController,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              decoration: const InputDecoration(
                hintText: 'Titolo...',
                border: InputBorder.none,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _contentController,
              maxLines: null,
              decoration: const InputDecoration(
                hintText: 'Scrivi qui...',
                border: InputBorder.none,
              ),
            ),
            const SizedBox(height: 20),

            // anteprima allegati
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _attachments.map((a) {
                Widget preview;
                if (a.type == 'image') {
                  preview = Image.file(File(a.url), width: 100, height: 100, fit: BoxFit.cover);
                } else if (a.type == 'video') {
                  preview = const Icon(Icons.videocam, size: 80);
                } else if (a.type == 'audio') {
                  preview = const Icon(Icons.audiotrack, size: 80);
                } else {
                  preview = const Icon(Icons.insert_drive_file);
                }

                return GestureDetector(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => MediaViewer(
                        media: _attachments.map((e) => {'type': e.type, 'path': e.url}).toList(),
                        initialIndex: _attachments.indexOf(a),
                      ),
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      color: Colors.black26,
                      child: preview,
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
      floatingActionButton: Wrap(
        spacing: 10,
        children: [
          FloatingActionButton(
            heroTag: 'photo',
            backgroundColor: AppColors.primary,
            child: const Icon(Icons.photo),
            onPressed: _pickImage,
          ),
          FloatingActionButton(
            heroTag: 'video',
            backgroundColor: AppColors.primaryDark,
            child: const Icon(Icons.videocam),
            onPressed: _pickVideo,
          ),
          FloatingActionButton(
            heroTag: 'mic',
            backgroundColor: _isRecording ? Colors.redAccent : AppColors.accent,
            child: Icon(_isRecording ? Icons.stop : Icons.mic),
            onPressed: _toggleRecording,
          ),
          FloatingActionButton(
            heroTag: 'draw',
            backgroundColor: Colors.blueAccent,
            child: const Icon(Icons.brush),
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => SketchPad(
                    onSave: (data) async {
                      final dir = await getTemporaryDirectory();
                      final filePath =
                          "${dir.path}/${DateTime.now().millisecondsSinceEpoch}.png";
                      final file = File(filePath);
                      await file.writeAsBytes(data);
                      setState(() => _attachments
                          .add(Attachment(type: 'image', url: file.path)));
                    },
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
