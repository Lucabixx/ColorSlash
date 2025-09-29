// lib/models/note_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class Attachment {
  final String type; // 'image', 'video', 'audio', 'sketch', ecc.
  final String url;  // percorso locale o URL remoto

  Attachment({required this.type, required this.url});

  Map<String, dynamic> toJson() => {
        'type': type,
        'url': url,
      };

  factory Attachment.fromJson(Map<String, dynamic> json) {
    return Attachment(
      type: (json['type'] ?? '') as String,
      url: (json['url'] ?? '') as String,
    );
  }
}

class NoteModel {
  String id;
  String type; // 'note' o 'list'
  String title;
  String content;
  String colorHex; // es: "#FF2979FF" (AARRGGBB)
  DateTime updatedAt;
  List<Attachment> attachments;

  NoteModel({
    required this.id,
    required this.type,
    required this.title,
    required this.content,
    required this.colorHex,
    required this.updatedAt,
    required this.attachments,
  });

  // -------------------------
  // Serializzazione
  // -------------------------
  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type,
        'title': title,
        'content': content,
        'colorHex': colorHex,
        'updatedAt': updatedAt.toUtc().toIso8601String(),
        'attachments': attachments.map((a) => a.toJson()).toList(),
      };

  // -------------------------
  // From JSON locale
  // -------------------------
  factory NoteModel.fromJson(Map<String, dynamic> json) {
    final rawAttachments = json['attachments'] as List<dynamic>? ?? [];

    return NoteModel(
      id: json['id'] as String? ??
          DateTime.now().millisecondsSinceEpoch.toString(),
      type: json['type'] as String? ?? 'note',
      title: json['title'] as String? ?? '',
      content: json['content'] as String? ?? '',
      colorHex: json['colorHex'] as String? ?? '#FF1E1E1E',
      updatedAt: _parseDate(json['updatedAt']),
      attachments: rawAttachments.map((e) {
        if (e is Attachment) return e;
        if (e is Map<String, dynamic>) return Attachment.fromJson(e);
        return Attachment.fromJson(Map<String, dynamic>.from(e as Map));
      }).toList(),
    );
  }

  // -------------------------
  // From Firestore document
  // -------------------------
  factory NoteModel.fromDoc(DocumentSnapshot doc) {
    final data = doc.data();
    if (data == null) {
      // Documento vuoto → nota placeholder
      return NoteModel(
        id: doc.id,
        type: 'note',
        title: '',
        content: '',
        colorHex: '#FF1E1E1E',
        updatedAt: DateTime.now(),
        attachments: [],
      );
    }

    final map = Map<String, dynamic>.from(data as Map);
    map['id'] ??= doc.id;
    return NoteModel.fromJson(map);
  }

  // -------------------------
  // Helper: parsing flessibile di updatedAt
  // -------------------------
  static DateTime _parseDate(dynamic value) {
    try {
      if (value == null) return DateTime.now();
      if (value is Timestamp) return value.toDate();
      if (value is DateTime) return value;
      if (value is String && value.isNotEmpty) {
        return DateTime.tryParse(value) ?? DateTime.now();
      }
    } catch (_) {}
    return DateTime.now();
  }
}
