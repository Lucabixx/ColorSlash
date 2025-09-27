// lib/screens/note_editor_screen.dart
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:video_player/video_player.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:file_picker/file_picker.dart';
import 'package:signature/signature.dart';
import 'package:uuid/uuid.dart';

import '../services/cloud_service.dart';
import '../services/local_storage.dart';

class NoteEditorScreen extends StatefulWidget {
  final String? existingId;
  final Map<String, dynamic>? existingData;
  const NoteEditorScreen({super.key, this.existingId, this.existingData});

  @override
  State<NoteEditorScreen> createState() => _NoteEditorScreenState();
}

class _NoteEditorScreenState extends State<NoteEditorScreen> {
  final TextEditingController _controller = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  final recorder = FlutterSoundRecorder();
  final player = FlutterSoundPlayer();
  final SignatureController _sigController = SignatureController(penStrokeWidth: 4, penColor: Colors.blueAccent);
  final List<Map<String, dynamic>> _attachments = []; // {type: 'image'|'video'|'audio'|'drawing', path: localPath, url?:storageUrl}
  final List<VideoPlayerController> _videoControllers = [];
  final _id = widget.existingId ?? const Uuid().v4();
  bool _isRecording = false;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _initAudio();
    if (widget.existingData != null) {
      _loadExisting(widget.existingData!);
    }
  }

  Future<void> _initAudio() async {
    await recorder.openRecorder();
    await player.openPlayer();
  }

  void _loadExisting(Map<String, dynamic> data) {
    _controller.text = data['text'] ?? '';
    final atts = (data['attachments'] ?? []) as List<dynamic>;
    for (var a in atts) {
      final m = Map<String, dynamic>.from(a);
      _attachments.add(m);
      if (m['type'] == 'video' && (m['path'] ?? m['localPath']) != null) {
        final p = (m['path'] ?? m['localPath']) as String;
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
    recorder.closeRecorder();
    player.closePlayer();
    _sigController.dispose();
    for (var c in _videoControllers) {
      c.dispose();
    }
    super.dispose();
  }

  // ---------- helpers ----------
  Future<String> _saveToAppDir(File f) async {
    final dir = await getApplicationDocumentsDirectory();
    final out = File('${dir.path}/${const Uuid().v4()}_${f.path.split('/').last}');
    await f.copy(out.path);
    return out.path;
  }

  Future<void> _addImage(ImageSource src) async {
    try {
      if (src == ImageSource.camera) {
        final cam = await Permission.camera.request();
        if (!cam.isGranted) { _showSnack("Permesso camera negato"); return; }
      } else {
        final ph = await Permission.photos.request();
        if (!ph.isGranted) { _showSnack("Permesso galleria negato"); return; }
      }

      final XFile? picked = await _picker.pickImage(source: src, imageQuality: 80);
      if (picked == null) return;
      final saved = await _saveToAppDir(File(picked.path));
      final att = {'type': 'image', 'localPath': saved};
      setState(() => _attachments.add(att));
      await _saveAndUpload(); // salva e prova ad uploadare (se loggato)
    } catch (e) {
      _showSnack("Errore immagine: $e");
    }
  }

  Future<void> _addVideo(ImageSource src) async {
    try {
      if (src == ImageSource.camera) {
        final cam = await Permission.camera.request();
        if (!cam.isGranted) { _showSnack("Permesso camera negato"); return; }
      }
      final XFile? picked = await _picker.pickVideo(source: src);
      if (picked == null) return;
      final saved = await _saveToAppDir(File(picked.path));
      final vc = VideoPlayerController.file(File(saved));
      await vc.initialize();
      _videoControllers.add(vc);
      setState(() => _attachments.add({'type': 'video', 'localPath': saved}));
      await _saveAndUpload();
    } catch (e) {
      _showSnack("Errore video: $e");
    }
  }

  Future<void> _recordOrStopAudio() async {
    try {
      final mic = await Permission.microphone.request();
      if (!mic.isGranted) { _showSnack("Permesso microfono negato"); return; }

      if (_isRecording) {
        final path = await recorder.stopRecorder();
        _isRecording = false;
        if (path != null) {
          final saved = await _saveToAppDir(File(path));
          setState(() => _attachments.add({'type': 'audio', 'localPath': saved}));
          await _saveAndUpload();
        }
      } else {
        final dir = await getApplicationDocumentsDirectory();
        final target = '${dir.path}/${const Uuid().v4()}.aac';
        await recorder.startRecorder(toFile: target, codec: Codec.aacMP4);
        _isRecording = true;
        _showSnack("Registrazione avviata — premi di nuovo per fermare");
      }
      setState(() {});
    } catch (e) {
      _showSnack("Errore registrazione: $e");
    }
  }

  Future<void> _importAudio() async {
    try {
      final res = await FilePicker.platform.pickFiles(type: FileType.audio);
      if (res == null) return;
      final f = File(res.files.single.path!);
      final saved = await _saveToAppDir(f);
      setState(() => _attachments.add({'type': 'audio', 'localPath': saved}));
      await _saveAndUpload();
    } catch (e) {
      _showSnack("Errore import audio: $e");
    }
  }

  Future<void> _openDrawing() async {
    final bytes = await Navigator.push<Uint8List?>(
      context,
      MaterialPageRoute(builder: (_) => SignatureDrawingScreen(controller: _sigController)),
    );
    // Note: our SignatureDrawingScreen returns PNG bytes when user salva.
    if (bytes != null) {
      final dir = await getApplicationDocumentsDirectory();
      final out = File('${dir.path}/${const Uuid().v4()}.png');
      await out.writeAsBytes(bytes);
      setState(() => _attachments.add({'type': 'drawing', 'localPath': out.path}));
      await _saveAndUpload();
    }
  }

  Future<void> _playAudio(String path) async {
    try {
      if (player.isPlaying) await player.stopPlayer();
      await player.startPlayer(fromURI: path);
    } catch (e) {
      _showSnack("Errore riproduzione audio: $e");
    }
  }

  // ---------- save & upload ----------
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

    // 1) salva localmente
    await LocalStorage.saveNote(_id, noteData);

    // 2) per ogni attachment con localPath, prova a fare upload e salva url nel metadata
    for (int i = 0; i < _attachments.length; i++) {
      final a = _attachments[i];
      if (a.containsKey('remoteUrl')) continue; // già uploadato
      final lp = a['localPath'] as String?;
      if (lp == null) continue;
      try {
        final url = await CloudService.uploadMedia(File(lp), _id);
        // aggiorna attachment sia in lista che nel salvataggio
        a['remoteUrl'] = url;
        // aggiorna anche local store
        await LocalStorage.saveNote(_id, {
          'id': _id,
          'type': 'nota',
          'text': _controller.text,
          'attachments': _attachments,
          'timestamp': DateTime.now().toIso8601String(),
        });
      } catch (e) {
        // se upload fallisce, mantieni solo localPath
        debugPrint("Upload fallito per $lp : $e");
      }
    }

    // 3) salva metadata nota su Firestore (via CloudService)
    await CloudService.backupNote({
      'id': _id,
      'type': 'nota',
      'text': _controller.text,
      'attachments': _attachments,
      'timestamp': DateTime.now().toIso8601String(),
    });

    setState(() => _busy = false);
  }

  void _showSnack(String message) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));

  // ---------- UI ----------
  Widget _buildAttachment(Map<String, dynamic> a, int idx) {
    final type = a['type'] as String?;
    final local = a['localPath'] as String?;
    final remote = a['remoteUrl'] as String?;
    if (type == 'image') {
      final displayPath = local ?? remote;
      if (displayPath == null) return const SizedBox.shrink();
      return Padding(
        padding: const EdgeInsets.all(8.0),
        child: InteractiveViewer(child: Image.file(File(displayPath), height: 200, fit: BoxFit.contain)),
      );
    }
    if (type == 'video') {
      final p = local ?? remote;
      if (p == null) return const SizedBox.shrink();
      final controller = (idx < _videoControllers.length) ? _videoControllers[idx] : null;
      if (controller != null && controller.value.isInitialized) {
        return Padding(
          padding: const EdgeInsets.all(8.0),
          child: SizedBox(height: 200, child: VideoPlayer(controller)),
        );
      } else if (p.startsWith('http')) {
        // remote video : show simple button to open/play externally
        return ListTile(
          leading: const Icon(Icons.videocam),
          title: Text(p.split('/').last),
          subtitle: const Text("Video (cloud)"),
        );
      } else {
        return ListTile(leading: const Icon(Icons.videocam), title: Text(p.split('/').last));
      }
    }
    if (type == 'audio') {
      final p = local ?? remote;
      if (p == null) return const SizedBox.shrink();
      return ListTile(
        leading: const Icon(Icons.audiotrack),
        title: Text(p.split('/').last),
        subtitle: remote != null ? const Text("Audio (cloud)") : null,
        trailing: IconButton(icon: const Icon(Icons.play_arrow), onPressed: () => _playAudio(p)),
      );
    }
    if (type == 'drawing') {
      final p = local ?? remote;
      if (p == null) return const SizedBox.shrink();
      return Padding(
        padding: const EdgeInsets.all(8.0),
        child: Image.file(File(p), height: 200),
      );
    }
    return const SizedBox.shrink();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Nota — ColorSlash"),
        actions: [
          IconButton(icon: const Icon(Icons.save), onPressed: _saveAndUpload),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: TextField(
                controller: _controller,
                maxLines: null,
                decoration: const InputDecoration(border: OutlineInputBorder(), hintText: "Scrivi qui..."),
                onChanged: (_) => _saveAndUpload(),
              ),
            ),
            if (_busy) const LinearProgressIndicator(),
            Expanded(
              child: ListView.builder(
                itemCount: _attachments.length,
                itemBuilder: (ctx, i) => _buildAttachment(_attachments[i], i),
              ),
            )
          ],
        ),
      ),
      bottomNavigationBar: BottomAppBar(
        child: SafeArea(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              IconButton(icon: Icon(_isRecording ? Icons.mic_off : Icons.mic), onPressed: _recordOrStopAudio),
              IconButton(icon: const Icon(Icons.library_music), onPressed: _importAudio),
              IconButton(icon: const Icon(Icons.image, color: Colors.green), onPressed: () => _addImage(ImageSource.gallery)),
              IconButton(icon: const Icon(Icons.camera_alt, color: Colors.cyan), onPressed: () => _addImage(ImageSource.camera)),
              IconButton(icon: const Icon(Icons.videocam, color: Colors.deepPurple), onPressed: () => _addVideo(ImageSource.gallery)),
              IconButton(icon: const Icon(Icons.videocam_outlined), onPressed: () => _addVideo(ImageSource.camera)),
              IconButton(icon: const Icon(Icons.brush, color: Colors.orange), onPressed: _openDrawing),
            ],
          ),
        ),
      ),
    );
  }
}

/// small drawing screen wrapper that returns PNG bytes when user presses save
class SignatureDrawingScreen extends StatelessWidget {
  final SignatureController controller;
  const SignatureDrawingScreen({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Disegna"),
        actions: [
          IconButton(icon: const Icon(Icons.check), onPressed: () async {
            final bytes = await controller.toPngBytes();
            Navigator.pop(context, bytes);
          })
        ],
      ),
      body: Column(
        children: [
          Expanded(child: Signature(controller: controller, backgroundColor: Colors.white)),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextButton(onPressed: () => controller.clear(), child: const Text("Cancella")),
            ],
          )
        ],
      ),
    );
  }
}
