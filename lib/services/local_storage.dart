// lib/services/local_storage.dart
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class LocalStorage {
  static Future<void> saveNote(String id, Map<String, dynamic> data) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(id, jsonEncode(data));
  }

  static Future<Map<String, dynamic>?> loadNote(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final s = prefs.getString(id);
    if (s == null) return null;
    return jsonDecode(s) as Map<String, dynamic>;
  }

  static Future<List<Map<String, dynamic>>> getAllNotes() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys().where((k) => k != null).toList();
    final res = <Map<String, dynamic>>[];
    for (var k in keys) {
      final s = prefs.getString(k);
      if (s == null) continue;
      try {
        res.add(jsonDecode(s) as Map<String, dynamic>);
      } catch (_) {}
    }
    return res;
  }

  static Future<void> deleteNote(String id) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(id);
  }
}
