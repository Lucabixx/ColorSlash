// lib/services/cloud_service.dart
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

class CloudService {
  static final _firestore = FirebaseFirestore.instance;
  static final _storage = FirebaseStorage.instance;

  /// Upload file with progress & retry
  static Future<String> uploadMedia(
    File file,
    String noteId, {
    void Function(double progress)? onProgress,
  }) async {
    final fileName = file.path.split('/').last;
    final ref = _storage.ref().child('notes/$noteId/$fileName');

    int attempt = 0;
    while (true) {
      try {
        final uploadTask = ref.putFile(file);
        uploadTask.snapshotEvents.listen((event) {
          final p = event.bytesTransferred / event.totalBytes;
          if (onProgress != null) onProgress(p);
        });

        final snapshot = await uploadTask;
        final url = await snapshot.ref.getDownloadURL();
        return url;
      } catch (e) {
        attempt++;
        if (attempt >= 3) rethrow;
        await Future.delayed(Duration(seconds: attempt * 2));
      }
    }
  }

  static Future<void> backupNote(Map<String, dynamic> note) async {
    final id = note['id'] ?? DateTime.now().millisecondsSinceEpoch.toString();
    await _firestore.collection('notes').doc(id).set(note);
  }
}
