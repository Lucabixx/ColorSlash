// lib/pages/note_page.dart
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_player/video_player.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:file_picker/file_picker.dart';
import 'package:uuid/uuid.dart';
import '../services/storage_service.dart';
import 'drawing_page.dart';

class NotePage extends StatefulWidget {
  final String? existingId;
  final Map<String, dynamic>? existingData;
  const NotePage({super.key, this.existingId, this.existingData});
  @override
  State<NotePage> createState() => _NotePageState();
}

class _NotePageState extends State<NotePage> {
  final TextEditingController _controller = TextEditingController();
  final List<Map<String, dynamic>> _attachments = [];
  final ImagePicker _picker = ImagePicker();
  final recorder = FlutterSoundRecorder();
  final player = FlutterSoundPlayer();
  final String _id = const Uuid().v4();
  final List<VideoPlayerController> _videoControllers = [];

  @override
  void initState() {
    super.initState();
    _initAudio();
    if (widget.existingData != null) _loadExisting(widget.existingData!);
  }

  Future<void> _initAudio() async {
    await recorder.openRecorder();
    await player.openPlayer();
  }

  void _loadExisting(Map<String,dynamic> data) {
    _controller.text = data['text'] ?? '';
    final atts = (data['attachments'] ?? []) as List<dynamic>;
    for (var a in atts) {
      final m = Map<String,dynamic>.from(a);
      _attachments.add(m);
      if (m['type'] == 'video' && (m['url'] ?? m['localPath']) != null) {
        final p = (m['url'] ?? m['localPath']) as String;
        if (!p.startsWith('http')) {
          final vc = VideoPlayerController.file(File(p));
          _videoControllers.add(vc);
          vc.initialize().then((_) => setState(() {}));
        }
      }
    }
  }

  @override
  void dispose() {
    recorder.closeRecorder();
    player.closePlayer();
    for (var c in _videoControllers) c.dispose();
    _controller.dispose();
    super.dispose();
  }

  Future<String> _saveToAppDir(File f) async {
    final dir = await getApplicationDocumentsDirectory();
    final out = File('${dir.path}/${const Uuid().v4()}_${f.path.split('/').last}');
    await f.copy(out.path);
    return out.path;
  }

  Future<void> _addImage(ImageSource src) async {
    if (src == ImageSource.camera) {
      final cam = await Permission.camera.request();
      if (!cam.isGranted) return;
    } else {
      final ph = await Permission.photos.request();
      if (!ph.isGranted) return;
    }
    final file = await _picker.pickImage(source: src, imageQuality: 85);
    if (file == null) return;
    final saved = await _saveToAppDir(File(file.path));
    _attachments.add({'type': 'image', 'path': saved});
    await _saveNote();
    setState(() {});
  }

  Future<void> _addVideo(ImageSource src) async {
    if (src == ImageSource.camera) {
      final cam = await Permission.camera.request();
      if (!cam.isGranted) return;
    }
    final file = await _picker.pickVideo(source: src);
    if (file == null) return;
    final saved = await _saveToAppDir(File(file.path));
    final vc = VideoPlayerController.file(File(saved));
    await vc.initialize();
    _videoControllers.add(vc);
    _attachments.add({'type': 'video', 'path': saved});
    await _saveNote();
    setState(() {});
  }

  Future<void> _recordOrStopAudio() async {
    final mic = await Permission.microphone.request();
    if (!mic.isGranted) return;
    if (recorder.isRecording) {
      final p = await recorder.stopRecorder();
      if (p != null) {
        final saved = await _saveToAppDir(File(p));

_attachments.add({'type': 'audio', 'path': saved});
        await _saveNote();
      }
    } else {
      final dir = await getApplicationDocumentsDirectory();
      final p = '${dir.path}/${const Uuid().v4()}.aac';
      await recorder.startRecorder(toFile: p, codec: Codec.aacMP4);
    }
    setState(() {});
  }

  Future<void> _importAudio() async {
    final res = await FilePicker.platform.pickFiles(type: FileType.audio);
    if (res == null) return;
    final f = File(res.files.single.path!);
    final saved = await _saveToAppDir(f);
    _attachments.add({'type': 'audio', 'path': saved});
    await _saveNote();
    setState(() {});
  }

  Future<void> _openDrawing() async {
    final bytes = await Navigator.push<Uint8List?>(context, MaterialPageRoute(builder: (_) => const DrawingPage()));
    if (bytes != null) {
      final dir = await getApplicationDocumentsDirectory();
      final out = File('${dir.path}/${const Uuid().v4()}.png');
      await out.writeAsBytes(bytes);
      _attachments.add({'type': 'drawing', 'path': out.path});
      await _saveNote();
      setState(() {});
    }
  }

  Future<void> _saveNote() async {
    final id = widget.existingId ?? _id;
    final data = {
      'id': id,
      'type': 'nota',
      'text': _controller.text,
      'attachments': _attachments,
    };
    await StorageService.saveNote(id, data);
  }

  Widget _buildAttachment(Map<String,dynamic> a, int idx) {
    final type = a['type'] as String?;
    final path = a['path'] as String?;
    if (type == 'image' && path != null) {
      return Padding(
        padding: const EdgeInsets.all(8.0),
        child: InteractiveViewer(child: Image.file(File(path), height: 200)),
      );
    }
    if (type == 'video' && path != null) {
      final vc = _videoControllers.length > idx ? _videoControllers[idx] : null;
      if (vc != null && vc.value.isInitialized) {
        return Padding(padding: const EdgeInsets.all(8.0), child: SizedBox(height: 200, child: VideoPlayer(vc)));
      }
    }
    if (type == 'audio' && path != null) {
      return ListTile(
        leading: const Icon(Icons.audiotrack),
        title: Text(path.split('/').last),
        trailing: IconButton(icon: const Icon(Icons.play_arrow), onPressed: () async => await player.startPlayer(fromURI: path)),
      );
    }
    if (type == 'drawing' && path != null) {
      return Padding(padding: const EdgeInsets.all(8.0), child: Image.file(File(path), height: 200));
    }
    return const SizedBox.shrink();
  }

  @override
  Widget build(BuildContext context) {
    final id = widget.existingId ?? _id;
    return Scaffold(
      appBar: AppBar(
        title: const Text("Nota"),
        actions: [IconButton(icon: const Icon(Icons.save), onPressed: _saveNote)],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(controller: _controller, maxLines: null, decoration: const InputDecoration(hintText: "Scrivi la nota..."), onChanged: (_) => _saveNote()),
          ),
          Expanded(
            child: ListView.builder(itemCount: _attachments.length, itemBuilder: (ctx,i) => _buildAttachment(_attachments[i], i)),
          )
        ],
      ),
      bottomNavigationBar: BottomAppBar(
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
          IconButton(icon: const Icon(Icons.mic), onPressed: _recordOrStopAudio),
          IconButton(icon: const Icon(Icons.image), onPressed: () => _showImageDialog()),
          IconButton(icon: const Icon(Icons.videocam), onPressed: () => _showVideoDialog()),
          IconButton(icon: const Icon(Icons.brush), onPressed: _openDrawing),
        ]),
      ),
    );
  }

  void _showImageDialog() {
    showDialog(context: context, builder: (_) => AlertDialog(title: const Text("Aggiungi immagine"), actions: [

TextButton(onPressed: () { Navigator.pop(context); _addImage(ImageSource.camera); }, child: const Text("Scatta")),
      TextButton(onPressed: () { Navigator.pop(context); _addImage(ImageSource.gallery); }, child: const Text("Galleria")),
    ]));
  }

  void _showVideoDialog() {
    showDialog(context: context, builder: (_) => AlertDialog(title: const Text("Aggiungi video"), actions: [
      TextButton(onPressed: () { Navigator.pop(context); _addVideo(ImageSource.camera); }, child: const Text("Registra")),
      TextButton(onPressed: () { Navigator.pop(context); _addVideo(ImageSource.gallery); }, child: const Text("Galleria")),
    ]));
  }
}