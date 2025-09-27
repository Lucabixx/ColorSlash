import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

class CloudService {
  final _firestore = FirebaseFirestore.instance;
  final _storage = FirebaseStorage.instance;

  Future<void> uploadAllNotes() async {
    // TODO: Implementa upload automatico note
    // Puoi leggere i file locali da LocalStorage e salvarli qui
  }

  Future<void> uploadMedia(String path, String noteId) async {
    final fileRef = _storage.ref().child('media/$noteId/${DateTime.now()}');
    await fileRef.putFile(Uri.parse(path).toFilePath() as dynamic);
  }
}
