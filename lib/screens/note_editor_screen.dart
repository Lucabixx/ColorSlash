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
      _attachments[i]['uploadProgress'] = -1.0; // errore
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
