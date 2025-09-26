import 'package:flutter_sound/flutter_sound.dart';
import 'package:path_provider/path_provider.dart';

class AudioService {
  final FlutterSoundRecorder _recorder = FlutterSoundRecorder();
  bool _inited = false;

  Future<void> init() async {
    if (!_inited) {
      await _recorder.openRecorder();
      _inited = true;
    }
  }

  Future<String?> startRecording(String fileName) async {
    await init();
    final dir = await getApplicationDocumentsDirectory();
    final path = '${dir.path}/$fileName.aac';
    await _recorder.startRecorder(toFile: path, codec: Codec.aacADTS);
    return path;
  }

  Future<String?> stopRecording() async {
    if (!_inited) return null;
    final path = await _recorder.stopRecorder();
    return path;
  }

  void dispose() {
    if (_inited) _recorder.closeRecorder();
  }
}
