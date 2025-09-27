// lib/services/cloud_service.dart
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

class CloudService {
  static final _firestore = FirebaseFirestore.instance;
  static final _storage = FirebaseStorage.instance;

  /// Upload with progress callback and retry
  static Future<String> uploadMediaWithProgress(
    File file,
    String noteId, {
    void Function(double progress)? onProgress,
  }) async {
    final fileName = file.path.split('/').last;
    final ref = _storage.ref().child('notes/$noteId/$fileName');

    int attempts = 0;
    while (true) {
      try {
        final uploadTask = ref.putFile(file);
        uploadTask.snapshotEvents.listen((snapshot) {
          final total = snapshot.totalBytes;
          final transferred = snapshot.bytesTransferred;
          if (total > 0 && onProgress != null) onProgress(transferred / total);
        });

        final snapshot = await uploadTask;
        final url = await snapshot.ref.getDownloadURL();
        return url;
      } catch (e) {
        attempts++;
        if (attempts >= 3) rethrow;
        await Future.delayed(Duration(seconds: attempts * 2));
      }
    }
  }

  static Future<void> backupNote(Map<String, dynamic> note) async {
    final id = note['id'] ?? DateTime.now().millisecondsSinceEpoch.toString();
    await _firestore.collection('notes').doc(id).set(note);
  }

  static Future<void> uploadAllNotes(List<Map<String, dynamic>> notes) async {
    for (var n in notes) {
      final id = n['id'] ?? DateTime.now().millisecondsSinceEpoch.toString();
      await _firestore.collection('notes').doc(id).set(n);
    }
  }
}
