// lib/services/local_storage.dart
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class LocalStorage {
  /// Save note as JSON string under its id
  static Future<void> saveNote(String id, Map<String, dynamic> data) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(id, jsonEncode(data));
  }

  static Future<Map<String, dynamic>?> getNote(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final s = prefs.getString(id);
    if (s == null) return null;
    return jsonDecode(s) as Map<String, dynamic>;
  }

  static Future<List<Map<String, dynamic>>> getAllNotes() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys().where((k) => !k.startsWith('__')).toList();
    final List<Map<String, dynamic>> res = [];
    for (var k in keys) {
      final s = prefs.getString(k);
      if (s == null) continue;
      try {
        final m = jsonDecode(s) as Map<String, dynamic>;
        res.add(m);
      } catch (_) {}
    }
    return res;
  }

  static Future<void> deleteNote(String id) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(id);
  }
}
