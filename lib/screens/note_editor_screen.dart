// lib/screens/note_editor_screen.dart
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:video_player/video_player.dart';
import 'package:path_provider/path_provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:signature/signature.dart';
import 'package:uuid/uuid.dart';

import '../services/cloud_service.dart';
import '../services/local_storage.dart';

class NoteEditorScreen extends StatefulWidget {
  final String noteId;
  final Map<String, dynamic>? existingData;

  const NoteEditorScreen({super.key, required this.noteId, this.existingData});

  @override
  State<NoteEditorScreen> createState() => _NoteEditorScreenState();
}

class _NoteEditorScreenState extends State<NoteEditorScreen> {
  final TextEditingController _controller = TextEditingController();
  final List<Map<String, dynamic>> _attachments = []; // {type, localPath, remoteUrl?, uploadProgress?}
  final ImagePicker _picker = ImagePicker();
  final FlutterSoundRecorder _recorder = FlutterSoundRecorder();
  final FlutterSoundPlayer _player = FlutterSoundPlayer();
  final List<VideoPlayerController> _videoControllers = [];
  final SignatureController _sigController = SignatureController(penStrokeWidth: 4, penColor: Colors.blueAccent);
  final String _id = Uuid().v4();
  bool _busy = false;
  bool _isRecording = false;

  @override
  void initState() {
    super.initState();
    _initAudio();
    if (widget.existingData != null) _loadExisting(widget.existingData!);
  }

  Future<void> _initAudio() async {
    await _recorder.openRecorder();
    await _player.openPlayer();
  }

  void _loadExisting(Map<String, dynamic> data) {
    _controller.text = data['text'] ?? '';
    final atts = (data['attachments'] ?? []) as List<dynamic>;
    for (var a in atts) {
      final m = Map<String, dynamic>.from(a);
      _attachments.add(m);
      if (m['type'] == 'video' && (m['localPath'] ?? m['remoteUrl']) != null) {
        final p = (m['localPath'] ?? m['remoteUrl']) as String;
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
    _controller.dispose();
    _recorder.closeRecorder();
    _player.closePlayer();
    for (var c in _videoControllers) c.dispose();
    _sigController.dispose();
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
    final XFile? picked = await _picker.pickImage(source: src, imageQuality: 80);
    if (picked == null) return;
    final saved = await _saveToAppDir(File(picked.path));
    setState(() => _attachments.add({'type': 'image', 'localPath': saved}));
    await _saveAndUpload();
  }

  Future<void> _addVideo(ImageSource src) async {
    if (src == ImageSource.camera) {
      final cam = await Permission.camera.request();
      if (!cam.isGranted) return;
    }
    final XFile? picked = await _picker.pickVideo(source: src);
    if (picked == null) return;
    final saved = await _saveToAppDir(File(picked.path));
    final vc = VideoPlayerController.file(File(saved));
    await vc.initialize();
    _videoControllers.add(vc);
    setState(() => _attachments.add({'type': 'video', 'localPath': saved}));
    await _saveAndUpload();
  }

  Future<void> _importAudio() async {
    final res = await FilePicker.platform.pickFiles(type: FileType.audio);
    if (res == null) return;
    final f = File(res.files.single.path!);
    final saved = await _saveToAppDir(f);
    setState(() => _attachments.add({'type': 'audio', 'localPath': saved}));
    await _saveAndUpload();
  }

  Future<void> _recordOrStopAudio() async {
    final mic = await Permission.microphone.request();
    if (!mic.isGranted) return;
    if (_isRecording) {
      final path = await _recorder.stopRecorder();
      _isRecording = false;
      if (path != null) {
        final saved = await _saveToAppDir(File(path));
        setState(() => _attachments.add({'type': 'audio', 'localPath': saved}));
        await _saveAndUpload();
      }
    } else {
      final dir = await getApplicationDocumentsDirectory();
      final target = '${dir.path}/${const Uuid().v4()}.aac';
      await _recorder.startRecorder(toFile: target, codec: Codec.aacMP4);
      _isRecording = true;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Registrazione avviata — premi di nuovo per fermare')));
    }
    setState(() {});
  }

  Future<void> _openDrawing() async {
    final bytes = await Navigator.push<Uint8List?>(context, MaterialPageRoute(builder: (_) => SignatureDrawingScreen(controller: _sigController)));
    if (bytes != null) {
      final dir = await getApplicationDocumentsDirectory();
      final out = File('${dir.path}/${const Uuid().v4()}.png');
      await out.writeAsBytes(bytes);
      setState(() => _attachments.add({'type': 'drawing', 'localPath': out.path}));
      await _saveAndUpload();
    }
  }

  Future<void> _saveAndUpload() async {
    if (_busy) return;
    setState(() => _busy = true);

    final noteData = {
      'id': widget.noteId,
      'type': 'nota',
      'text': _controller.text,
      'attachments': _attachments,
      'timestamp': DateTime.now().toIso8601String(),
    };

    // 1) save local
    await LocalStorage.saveNote(widget.noteId, noteData);

    // 2) upload attachments (with progress & retry)
    for (int i = 0; i < _attachments.length; i++) {
      final a = _attachments[i];
      if (a.containsKey('remoteUrl')) continue;
      final lp = a['localPath'] as String?;
      if (lp == null || lp.startsWith('http')) continue;

      // progress indicator
      try {
        final url = await CloudService.uploadMediaWithProgress(
          File(lp),
          widget.noteId,
          onProgress: (p) {
            setState(() => _attachments[i]['uploadProgress'] = p);
          },
        );
        a['remoteUrl'] = url;
        a.remove('uploadProgress');

        // update local note metadata
        await LocalStorage.saveNote(widget.noteId, {
          'id': widget.noteId,
          'type': 'nota',
          'text': _controller.text,
          'attachments': _attachments,
          'timestamp': DateTime.now().toIso8601String(),
        });
      } catch (e) {
        debugPrint('Upload failed for $lp - $e');
        setState(() => _attachments[i]['uploadProgress'] = -1.0);
      }
    }

    // 3) save metadata in cloud
    await CloudService.backupNote({
      'id': widget.noteId,
      'type': 'nota',
      'text': _controller.text,
      'attachments': _attachments,
      'timestamp': DateTime.now().toIso8601String(),
    });

    setState(() => _busy = false);
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Salvataggio completato')));
  }

  Future<void> _playAudio(String path) async {
    await _player.stopPlayer();
    await _player.startPlayer(fromURI: path);
  }

  Widget _buildAttachment(Map<String, dynamic> a, int idx) {
    final t = a['type'] as String?;
    final lp = a['localPath'] as String?;
    final ru = a['remoteUrl'] as String?;
    final prog = a['uploadProgress'];

    if (t == 'image') {
      final display = lp ?? ru;
      if (display == null) return const SizedBox.shrink();
      return Column(
        children: [
          Padding(padding: const EdgeInsets.all(8), child: InteractiveViewer(child: Image.file(File(display), height: 200))),
          if (prog != null)
            prog == -1.0
                ? const Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: Text('❌ Upload fallito — riprova', style: TextStyle(color: Colors.red)))
                : Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: LinearProgressIndicator(value: prog as double)),
        ],
      );
    } else if (t == 'video') {
      final display = lp ?? ru;
      if (display == null) return const SizedBox.shrink();
      final controllerIndex = _attachments.sublist(0, idx + 1).where((e) => e['type'] == 'video').length - 1;
      final controller = controllerIndex >= 0 && controllerIndex < _videoControllers.length ? _videoControllers[controllerIndex] : null;
      if (controller != null && controller.value.isInitialized) {
        return Column(
          children: [
            SizedBox(height: 200, child: VideoPlayer(controller)),
            if (prog != null)
              prog == -1.0 ? const Text('❌ Upload fallito', style: TextStyle(color: Colors.red)) : LinearProgressIndicator(value: prog as double),
          ],
        );
      } else {
        return ListTile(
          leading: const Icon(Icons.videocam),
          title: Text(display.split('/').last),
          subtitle: prog != null ? LinearProgressIndicator(value: prog as double) : null,
        );
      }
    } else if (t == 'audio') {
      final display = lp ?? ru;
      if (display == null) return const SizedBox.shrink();
      return ListTile(
        leading: const Icon(Icons.audiotrack),
        title: Text(display.split('/').last),
        subtitle: prog != null ? (prog == -1.0 ? const Text('❌ Upload fallito', style: TextStyle(color: Colors.red)) : LinearProgressIndicator(value: prog as double)) : null,
        trailing: IconButton(icon: const Icon(Icons.play_arrow), onPressed: () => _playAudio(display)),
      );
    } else if (t == 'drawing') {
      final display = lp ?? ru;
      if (display == null) return const SizedBox.shrink();
      return Column(children: [Padding(padding: const EdgeInsets.all(8), child: Image.file(File(display), height: 200))]);
    }
    return const SizedBox.shrink();
  }

  @override
  Widget build(BuildContext context) {
    final id = widget.noteId;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nota — ColorSlash'),
        actions: [IconButton(icon: const Icon(Icons.save), onPressed: _saveAndUpload)],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(padding: const EdgeInsets.all(12), child: TextField(controller: _controller, maxLines: null, decoration: const InputDecoration(hintText: 'Scrivi qui...'), onChanged: (_) => _saveAndUpload())),
            if (_busy) const LinearProgressIndicator(),
            Expanded(child: ListView.builder(itemCount: _attachments.length, itemBuilder: (c, i) => _buildAttachment(_attachments[i], i))),
          ],
        ),
      ),
      bottomNavigationBar: BottomAppBar(
        child: SafeArea(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
              IconButton(icon: Icon(_isRecording ? Icons.mic_off : Icons.mic), onPressed: _recordOrStopAudio),
              IconButton(icon: const Icon(Icons.library_music), onPressed: _importAudio),
              IconButton(icon: const Icon(Icons.image, color: Colors.green), onPressed: () => _addImage(ImageSource.gallery)),
              IconButton(icon: const Icon(Icons.camera_alt, color: Colors.cyan), onPressed: () => _addImage(ImageSource.camera)),
              IconButton(icon: const Icon(Icons.videocam, color: Colors.deepPurple), onPressed: () => _addVideo(ImageSource.gallery)),
              IconButton(icon: const Icon(Icons.videocam_outlined), onPressed: () => _addVideo(ImageSource.camera)),
              IconButton(icon: const Icon(Icons.brush, color: Colors.orange), onPressed: _openDrawing),
            ]),
          ),
        ),
      ),
    );
  }
}

/// Drawing screen returning PNG bytes
class SignatureDrawingScreen extends StatelessWidget {
  final SignatureController controller;
  const SignatureDrawingScreen({super.key, required this.controller});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Disegna'),
        actions: [
          IconButton(icon: const Icon(Icons.check), onPressed: () async {
            final bytes = await controller.toPngBytes();
            Navigator.of(context).pop(bytes);
          })
        ],
      ),
      body: Column(
        children: [
          Expanded(child: Signature(controller: controller, backgroundColor: Colors.white)),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            TextButton(onPressed: () => controller.clear(), child: const Text('Cancella')),
          ])
        ],
      ),
    );
  }
}
