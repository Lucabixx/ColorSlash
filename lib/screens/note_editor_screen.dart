import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:colorslash/utils/app_colors.dart';
import 'package:colorslash/widgets/media_viewer.dart';
import 'package:colorslash/widgets/sketch_pad.dart';

class NoteEditorScreen extends StatefulWidget {
  final String? noteId;
  final String type; // "note" o "list"

  const NoteEditorScreen({
    super.key,
    this.noteId,
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

  List<Map<String, dynamic>> _media = [];
  Color _color = Colors.white;
  bool _isRecording = false;
  bool _isNew = true;

  @override
  void initState() {
    super.initState();
    _recorder.openRecorder();
    if (widget.noteId != null) {
      _isNew = false;
      _loadNote();
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _recorder.closeRecorder();
    super.dispose();
  }

  Future<File> _getNotesFile() async {
    final dir = await getApplicationDocumentsDirectory();
    return File("${dir.path}/notes.json");
  }

  /// 🔹 Crea un ID univoco
  String _generateId() => DateTime.now().millisecondsSinceEpoch.toString();

  /// 🔹 Carica una nota esistente dal file
  Future<void> _loadNote() async {
    final file = await _getNotesFile();
    if (!await file.exists()) return;
    final notes = List<Map<String, dynamic>>.from(jsonDecode(await file.readAsString()));
    final note = notes.firstWhere(
      (n) => n['id'] == widget.noteId,
      orElse: () => {},
    );
    if (note.isNotEmpty) {
      setState(() {
        _titleController.text = note['title'] ?? '';
        _contentController.text = note['content'] ?? '';
        _color = Color(note['color'] ?? Colors.white.value);
        _media = List<Map<String, dynamic>>.from(note['media'] ?? []);
      });
    }
  }

  /// 💾 Salva o aggiorna la nota
  Future<void> _saveNote() async {
    final file = await _getNotesFile();
    final notes = await file.exists()
        ? List<Map<String, dynamic>>.from(jsonDecode(await file.readAsString()))
        : [];

    final noteId = widget.noteId ?? _generateId();
    final note = {
      'id': noteId,
      'type': widget.type,
      'title': _titleController.text.trim(),
      'content': _contentController.text.trim(),
      'color': _color.value,
      'updatedAt': DateTime.now().millisecondsSinceEpoch,
      'media': _media,
    };

    final index = notes.indexWhere((n) => n['id'] == noteId);
    if (index != -1) {
      notes[index] = note;
    } else {
      notes.add(note);
    }

    await file.writeAsString(jsonEncode(notes));
  }

  /// 🖼️ Scelta immagine
  Future<void> _pickImage() async {
    final img = await _picker.pickImage(source: ImageSource.gallery);
    if (img != null) {
      setState(() => _media.add({'type': 'image', 'path': img.path}));
    }
  }

  /// 🎥 Scelta video
  Future<void> _pickVideo() async {
    final video = await _picker.pickVideo(source: ImageSource.gallery);
    if (video != null) {
      setState(() => _media.add({'type': 'video', 'path': video.path}));
    }
  }

  /// 🎙️ Registra o ferma audio
  Future<void> _toggleRecording() async {
    if (_isRecording) {
      final path = await _recorder.stopRecorder();
      if (path != null) {
        setState(() => _media.add({'type': 'audio', 'path': path}));
      }
    } else {
      final dir = await getTemporaryDirectory();
      final filePath = "${dir.path}/${DateTime.now().millisecondsSinceEpoch}.aac";
      await _recorder.startRecorder(toFile: filePath);
    }
    setState(() => _isRecording = !_isRecording);
  }

  /// 🎨 Cambia colore
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
            children: AppColors.noteColors.map(
              (c) {
                final isSelected = selectedColor == c;
                return GestureDetector(
                  onTap: () => setState(() => selectedColor = c),
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: c,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected ? AppColors.primaryLight : Colors.grey,
                        width: 2,
                      ),
                    ),
                  ),
                );
              },
            ).toList(),
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
    if (selected != null) {
      setState(() => _color = selected);
    }
  }

  /// ✏️ Salvataggio automatico ogni volta che cambia contenuto
  void _autoSave() {
    _saveNote();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _color.withOpacity(0.08),
      appBar: AppBar(
        title: Text(widget.type == 'note'
            ? (_isNew ? 'Nuova Nota' : 'Modifica Nota')
            : (_isNew ? 'Nuova Lista' : 'Modifica Lista')),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: () async {
              await _saveNote();
              if (context.mounted) Navigator.pop(context, true);
            },
          ),
          IconButton(
            icon: const Icon(Icons.color_lens),
            onPressed: _openColorPicker,
          ),
        ],
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            /// Titolo
            TextField(
              controller: _titleController,
              onChanged: (_) => _autoSave(),
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              decoration: const InputDecoration(
                hintText: 'Titolo...',
                border: InputBorder.none,
              ),
            ),
            const SizedBox(height: 12),

            /// Contenuto
            TextField(
              controller: _contentController,
              onChanged: (_) => _autoSave(),
              decoration: const InputDecoration(
                hintText: 'Scrivi qui...',
                border: InputBorder.none,
              ),
              maxLines: null,
            ),
            const SizedBox(height: 20),

            /// Sezione media
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _media.map((m) {
                Widget preview;
                if (m['type'] == 'image') {
                  preview = Image.file(File(m['path']),
                      width: 100, height: 100, fit: BoxFit.cover);
                } else if (m['type'] == 'video') {
                  preview = Container(
                    width: 100,
                    height: 100,
                    color: Colors.black26,
                    child: const Icon(Icons.videocam, color: Colors.white),
                  );
                } else if (m['type'] == 'audio') {
                  preview = Container(
                    width: 100,
                    height: 100,
                    color: Colors.black26,
                    child: const Icon(Icons.audiotrack, color: Colors.white),
                  );
                } else {
                  preview = Container(width: 100, height: 100, color: Colors.grey);
                }

                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => MediaViewer(
                          media: _media,
                          initialIndex: _media.indexOf(m),
                        ),
                      ),
                    );
                  },
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: preview,
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),

      /// Floating Buttons
      floatingActionButton: Wrap(
        spacing: 10,
        direction: Axis.horizontal,
        children: [
          FloatingActionButton(
            heroTag: 'photo',
            onPressed: _pickImage,
            backgroundColor: AppColors.primary,
            child: const Icon(Icons.photo),
          ),
          FloatingActionButton(
            heroTag: 'video',
            onPressed: _pickVideo,
            backgroundColor: AppColors.primaryDark,
            child: const Icon(Icons.videocam),
          ),
          FloatingActionButton(
            heroTag: 'mic',
            onPressed: _toggleRecording,
            backgroundColor: _isRecording ? Colors.redAccent : AppColors.accent,
            child: Icon(_isRecording ? Icons.stop : Icons.mic),
          ),
          FloatingActionButton(
            heroTag: 'draw',
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
                      setState(() =>
                          _media.add({'type': 'image', 'path': file.path}));
                      _autoSave();
                    },
                  ),
                ),
              );
            },
            backgroundColor: Colors.blueAccent,
            child: const Icon(Icons.brush),
          ),
        ],
      ),
    );
  }
}
