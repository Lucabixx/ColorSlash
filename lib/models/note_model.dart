import 'package:cloud_firestore/cloud_firestore.dart';

class Attachment {
  final String type; // 'image'|'video'|'audio'|'sketch'|...
  final String url; // local path or remote url

  Attachment({required this.type, required this.url});

  Map<String, dynamic> toJson() => {'type': type, 'url': url};

  factory Attachment.fromJson(Map<String, dynamic> json) => Attachment(
        type: (json['type'] ?? '') as String,
        url: (json['url'] ?? '') as String,
      );
}

class NoteModel {
  String id;
  String type; // 'note' or 'list'
  String title;
  String content;
  String colorHex; // e.g. "#FF2979FF" (AARRGGBB)
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

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type,
        'title': title,
        'content': content,
        'colorHex': colorHex,
        'updatedAt': updatedAt.toUtc().toIso8601String(),
        'attachments': attachments.map((a) => a.toJson()).toList(),
      };

  factory NoteModel.fromJson(Map<String, dynamic> json) {
    final attachmentsRaw = json['attachments'] as List<dynamic>? ?? [];
    return NoteModel(
      id: json['id'] as String? ?? DateTime.now().millisecondsSinceEpoch.toString(),
      type: json['type'] as String? ?? 'note',
      title: json['title'] as String? ?? '',
      content: json['content'] as String? ?? '',
      colorHex: json['colorHex'] as String? ?? '#FF1E1E1E',
      updatedAt: DateTime.tryParse(json['updatedAt'] as String? ?? '') ?? DateTime.now(),
      attachments: attachmentsRaw.map((e) {
        if (e is Attachment) return e;
        if (e is Map<String, dynamic>) return Attachment.fromJson(e);
        return Attachment.fromJson(Map<String, dynamic>.from(e as Map));
      }).toList(),
    );
  }

  factory NoteModel.fromDoc(DocumentSnapshot doc) {
    final data = doc.data();
    if (data == null) {
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
    // ensure id exists
    map['id'] = map['id'] ?? doc.id;
    return NoteModel.fromJson(map);
  }
}
