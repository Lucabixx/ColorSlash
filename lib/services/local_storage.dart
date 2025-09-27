import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class LocalStorage {
  Future<void> saveNote(String id, Map<String, dynamic> data) async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setString(id, jsonEncode(data));
  }

  Future<Map<String, dynamic>?> getNote(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString(id);
    if (json == null) return null;
    return jsonDecode(json);
  }

  Future<void> deleteNote(String id) async {
    final prefs = await SharedPreferences.getInstance();
    prefs.remove(id);
  }
}
