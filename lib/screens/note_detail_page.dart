import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/note_model.dart';
import '../services/storage_service.dart';
import '../services/firebase_service.dart';

class NoteDetailPage extends StatefulWidget {
  final NoteModel? note;
  final FirebaseService firebaseService;
  const NoteDetailPage({super.key, this.note, required this.firebaseService});

  @override
  State<NoteDetailPage> createState() => _NoteDetailPageState();
}

class _NoteDetailPageState extends State<NoteDetailPage> {
  final _titleCtrl = TextEditingController();
  final _contentCtrl = TextEditingController();
  final _picker = ImagePicker();
  final _storage = StorageService();
  NoteModel? _note;

  @override
  void initState() {
    super.initState();
    _note = widget.note;
    if (_note != null) {
      _titleCtrl.text = _note!.title;
      _contentCtrl.text = _note!.content;
    }
  }

  Future<void> _pickImage() async {
    final XFile? file = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (file == null) return;
    final local = File(file.path);
    final path = 'notes/${_note?.id ?? DateTime.now().millisecondsSinceEpoch}/${file.name}';
    final url = await _storage.uploadFile(local, path);
    final attachment = Attachment(type: 'image', url: url);

    setState(() {
      _note ??= widget.firebaseService.createEmptyNote();
      _note!.attachments.add(attachment);
    });
  }

  Future<void> _saveAndUpload() async {
    final noteToSave = NoteModel(
      id: _note?.id ?? widget.firebaseService.createEmptyNote().id,
      title: _titleCtrl.text,
      content: _contentCtrl.text,
      colorHex: _note?.colorHex ?? '#FFFFFFFF',
      updatedAt: DateTime.now().toUtc(),
      attachments: _note?.attachments ?? [],
    );

    // upload to cloud
    await widget.firebaseService.upsertNote(noteToSave);

    Navigator.pop(context, noteToSave);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.note == null ? 'Nuova Nota' : 'Modifica Nota'),
        actions: [
          IconButton(icon: const Icon(Icons.photo), onPressed: _pickImage),
          IconButton(icon: const Icon(Icons.save), onPressed: _saveAndUpload),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            TextField(controller: _titleCtrl, decoration: const InputDecoration(hintText: 'Titolo')),
            const SizedBox(height: 8),
            Expanded(child: TextField(controller: _contentCtrl, maxLines: null, expands: true)),
            const SizedBox(height: 12),
            if ((_note?.attachments ?? []).isNotEmpty)
              SizedBox(
                height: 100,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: _note!.attachments.map((a) {
                    if (a.type == 'image') {
                      return Padding(
                        padding: const EdgeInsets.all(6.0),
                        child: Image.network(a.url, width: 120, fit: BoxFit.cover),
                      );
                    }
                    return const SizedBox();
                  }).toList(),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
