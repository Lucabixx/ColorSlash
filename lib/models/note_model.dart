import 'package:cloud_firestore/cloud_firestore.dart';

class Attachment {
  final String type;
  final String url;

  Attachment({required this.type, required this.url});

  Map<String, dynamic> toJson() => {'type': type, 'url': url};

  factory Attachment.fromJson(Map<String, dynamic> json) => Attachment(
        type: json['type'] as String,
        url: json['url'] as String,
      );
}

class NoteModel {
  String id;
  String title;
  String content;
  String colorHex;
  DateTime updatedAt;
  List<Attachment> attachments;

  NoteModel({
    required this.id,
    required this.title,
    required this.content,
    required this.colorHex,
    required this.updatedAt,
    required this.attachments,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'content': content,
        'colorHex': colorHex,
        'updatedAt': updatedAt.toUtc().toIso8601String(),
        'attachments': attachments.map((a) => a.toJson()).toList(),
      };

  factory NoteModel.fromJson(Map<String, dynamic> json) => NoteModel(
        id: json['id'] as String,
        title: json['title'] as String? ?? '',
        content: json['content'] as String? ?? '',
        colorHex: json['colorHex'] as String? ?? '#FFFFFFFF',
        updatedAt: DateTime.parse(json['updatedAt'] as String),
        attachments: (json['attachments'] as List<dynamic>? ?? [])
            .map((e) => Attachment.fromJson(e as Map<String, dynamic>))
            .toList(),
      );

  factory NoteModel.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return NoteModel.fromJson(data);
  }
}
