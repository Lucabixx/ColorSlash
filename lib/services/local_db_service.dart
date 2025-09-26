import 'dart:async';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/note_model.dart';
import 'dart:convert';

class LocalDbService {
  static Database? _db;

  Future<Database> get db async {
    if (_db != null) return _db!;
    _db = await initDb();
    return _db!;
  }

  Future<Database> initDb() async {
    final databasesPath = await getDatabasesPath();
    final path = join(databasesPath, 'colorslash.db');
    return await openDatabase(path, version: 1, onCreate: (db, v) async {
      await db.execute('CREATE TABLE notes(id TEXT PRIMARY KEY, title TEXT, content TEXT, color TEXT, updatedAt TEXT, attachments TEXT)');
    });
  }

  Future<void> upsertNote(NoteModel note) async {
    final dbClient = await db;
    await dbClient.insert('notes', {
      'id': note.id,
      'title': note.title,
      'content': note.content,
      'color': note.colorHex,
      'updatedAt': note.updatedAt.toUtc().toIso8601String(),
      'attachments': json.encode(note.attachments.map((a) => a.toJson()).toList()),
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<NoteModel>> getAllNotes() async {
    final dbClient = await db;
    final res = await dbClient.query('notes', orderBy: 'updatedAt DESC');
    return res.map((row) {
      final attachments = (json.decode(row['attachments'] as String) as List<dynamic>).map((e) => Attachment.fromJson(e as Map<String, dynamic>)).toList();
      return NoteModel(
        id: row['id'] as String,
        title: row['title'] as String,
        content: row['content'] as String,
        colorHex: row['color'] as String,
        updatedAt: DateTime.parse(row['updatedAt'] as String),
        attachments: attachments,
      );
    }).toList();
  }

  Future<void> deleteNote(String id) async {
    final dbClient = await db;
    await dbClient.delete('notes', where: 'id = ?', whereArgs: [id]);
  }
}
