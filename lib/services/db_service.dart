import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DBService {
  DBService._private();
  static final DBService instance = DBService._private();

  Database? _db;

  Future<Database> get db async {
    if (_db != null) return _db!;
    _db = await _initDB();
    return _db!;
  }

  Future<Database> _initDB() async {
    final path = join(await getDatabasesPath(), 'colorslash.db');
    return await openDatabase(path, version: 1, onCreate: (db, v) async {
      await db.execute('''
        CREATE TABLE notes (
          id TEXT PRIMARY KEY,
          title TEXT,
          content TEXT,
          color TEXT,
          lastModified INTEGER
        )
      ''');
    });
  }

  Future<void> upsertNote(Map<String, dynamic> note) async {
    final d = await db;
    await d.insert('notes', note, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Map<String,dynamic>>> getAllNotes() async {
    final d = await db;
    return await d.query('notes', orderBy: 'lastModified DESC');
  }
}
