import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';

import '../services/auth_service.dart';
import 'note_editor_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Map<String, dynamic>> _notes = [];
  List<Map<String, dynamic>> _filteredNotes = [];
  String _searchQuery = '';
  String _sortKey = 'date';
  bool _ascending = false;
  String _filterType = 'all';
  Color? _filterColor;
  bool _syncing = false;

  @override
  void initState() {
    super.initState();
    _loadNotes();
  }

  Future<File> _getNotesFile() async {
    final dir = await getApplicationDocumentsDirectory();
    return File("${dir.path}/notes.json");
  }

  Future<void> _loadNotes() async {
    try {
      final file = await _getNotesFile();
      if (await file.exists()) {
        final data = jsonDecode(await file.readAsString());
        final loaded = List<Map<String, dynamic>>.from(data);
        setState(() {
          _notes = loaded;
          _applyFilters();
        });
      }
    } catch (e) {
      debugPrint("Errore caricamento note: $e");
    }
  }

  Future<void> _saveNotes() async {
    final file = await _getNotesFile();
    await file.writeAsString(jsonEncode(_notes));
  }

  void _applyFilters() {
    List<Map<String, dynamic>> result = List.from(_notes);

    // filtro tipo
    if (_filterType != 'all') {
      result = result.where((n) => n['type'] == _filterType).toList();
    }

    // filtro colore
    if (_filterColor != null) {
      result = result.where((n) => n['color'] == _filterColor!.value).toList();
    }

    // ricerca testo
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      result = result.where((n) {
        final title = (n['title'] ?? '').toString().toLowerCase();
        final content = (n['content'] ?? '').toString().toLowerCase();
        return title.contains(q) || content.contains(q);
      }).toList();
    }

    // ordinamento
    result.sort((a, b) {
      dynamic vA = a[_sortKey];
      dynamic vB = b[_sortKey];
      if (_sortKey == 'date') {
        vA = DateTime.tryParse(vA ?? '') ?? DateTime(0);
        vB = DateTime.tryParse(vB ?? '') ?? DateTime(0);
      }
      final cmp = vA.toString().compareTo(vB.toString());
      return _ascending ? cmp : -cmp;
    });

    setState(() => _filteredNotes = result);
  }

  Future<void> _addOrEditNote([Map<String, dynamic>? existing]) async {
    final id = existing?['id'] ?? DateTime.now().millisecondsSinceEpoch.toString();
    final result = await Navigator.push<bool?>(
      context,
      MaterialPageRoute(
        builder: (_) => NoteEditorScreen(
          noteId: id,
          type: existing?['type'] ?? 'note',
          // existing data non supportato qui (se necessario aggiungere)
        ),
      ),
    );
    if (result == true) {
      await _loadNotes();
    }
  }

  Future<void> _deleteNote(String id) async {
    setState(() => _notes.removeWhere((n) => n['id'] == id));
    await _saveNotes();
    _applyFilters();
  }

  Future<void> _changeColor(Map<String, dynamic> note) async {
    final newColor = await showDialog<Color>(
      context: context,
      builder: (ctx) {
        Color selected = Color(note['color'] ?? Colors.white.value);
        return AlertDialog(
          title: const Text('Cambia colore'),
          content: Wrap(
            spacing: 8,
            children: [
              for (final c in [Colors.white, Colors.red, Colors.green, Colors.blue, Colors.yellow, Colors.purple])
                GestureDetector(
                  onTap: () => selected = c,
                  child: Container(
                    width: 30,
                    height: 30,
                    margin: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: c,
                      shape: BoxShape.circle,
                      border: Border.all(color: selected == c ? Colors.black : Colors.grey),
                    ),
                  ),
                ),
            ],
          ),
          actions: [TextButton(onPressed: () => Navigator.pop(ctx, selected), child: const Text('OK'))],
        );
      },
    );

    if (newColor != null) {
      note['color'] = newColor.value;
      await _saveNotes();
      _applyFilters();
    }
  }

  Future<void> _syncWithCloud() async {
    final auth = Provider.of<AuthService>(context, listen: false);
    try {
      setState(() => _syncing = true);
      await auth.syncWithCloud(context);
      await _loadNotes();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Sincronizzazione completata ✅')));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Errore sincronizzazione: $e')));
      }
    } finally {
      setState(() => _syncing = false);
    }
  }

  void _resetFilters() {
    setState(() {
      _filterType = 'all';
      _filterColor = null;
      _searchQuery = '';
      _sortKey = 'date';
      _ascending = false;
    });
    _applyFilters();
  }

  Widget _highlightText(String text, String query) {
    if (query.isEmpty) return Text(text, style: const TextStyle(color: Colors.white));
    final lowerText = text.toLowerCase();
    final lowerQuery = query.toLowerCase();
    final List<InlineSpan> spans = [];
    int start = 0;
    while (true) {
      final index = lowerText.indexOf(lowerQuery, start);
      if (index == -1) {
        spans.add(TextSpan(text: text.substring(start)));
        break;
      }
      if (index > start) spans.add(TextSpan(text: text.substring(start, index)));
      spans.add(TextSpan(
        text: text.substring(index, index + query.length),
        style: const TextStyle(backgroundColor: Colors.yellow, fontWeight: FontWeight.bold),
      ));
      start = index + query.length;
    }
    return RichText(text: TextSpan(style: const TextStyle(color: Colors.white), children: spans));
  }

  @override
  Widget build(BuildContext context) {
    final noteCount = _filteredNotes.where((n) => n['type'] == 'note').length;
    final listCount = _filteredNotes.where((n) => n['type'] == 'list').length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('ColorSlash - BETA1'),
        actions: [
          if (_syncing)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 12),
              child: Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))),
            ),
          IconButton(icon: const Icon(Icons.cloud_sync), onPressed: _syncing ? null : _syncWithCloud),
          IconButton(icon: const Icon(Icons.filter_alt_off), onPressed: _resetFilters),
          PopupMenuButton<String>(
            onSelected: (val) {
              if (val == 'note' || val == 'list' || val == 'all') {
                _filterType = val;
              } else if (val == 'asc' || val == 'desc') {
                _ascending = val == 'asc';
              } else {
                _sortKey = val;
              }
              _applyFilters();
            },
            itemBuilder: (context) => const [
              PopupMenuItem(value: 'note', child: Text('Solo Note')),
              PopupMenuItem(value: 'list', child: Text('Solo Liste')),
              PopupMenuItem(value: 'all', child: Text('Tutti')),
              PopupMenuDivider(),
              PopupMenuItem(value: 'title', child: Text('Ordina per Titolo')),
              PopupMenuItem(value: 'date', child: Text('Ordina per Data')),
              PopupMenuItem(value: 'color', child: Text('Ordina per Colore')),
              PopupMenuDivider(),
              PopupMenuItem(value: 'asc', child: Text('Crescente')),
              PopupMenuItem(value: 'desc', child: Text('Decrescente')),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText: 'Cerca...'),
              onChanged: (v) {
                _searchQuery = v;
                _applyFilters();
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: Row(
              children: [
                Text('Note: $noteCount', style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(width: 16),
                Text('Liste: $listCount', style: const TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          Expanded(
            child: _filteredNotes.isEmpty
                ? const Center(child: Text('Nessuna nota trovata'))
                : ListView.builder(
                    itemCount: _filteredNotes.length,
                    itemBuilder: (context, i) {
                      final n = _filteredNotes[i];
                      final color = Color(n['color'] ?? Colors.white.value);
                      final title = n['title'] ?? '';
                      final content = n['content'] ?? '';
                      return Dismissible(
                        key: Key(n['id']),
                        direction: DismissDirection.endToStart,
                        onDismissed: (_) => _deleteNote(n['id']),
                        background: Container(
                          color: Colors.red,
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 20),
                          child: const Icon(Icons.delete, color: Colors.white),
                        ),
                        child: ListTile(
                          onTap: () => _addOrEditNote(n),
                          onLongPress: () => _changeColor(n),
                          leading: Container(width: 12, height: 12, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
                          title: _highlightText(title, _searchQuery),
                          subtitle: _highlightText(content, _searchQuery),
                          trailing: Icon(n['type'] == 'note' ? Icons.sticky_note_2 : Icons.list_alt, color: Colors.white70),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: PopupMenuButton<String>(
        icon: const Icon(Icons.add),
        onSelected: (v) => _addOrEditNote({'type': v}),
        itemBuilder: (_) => const [
          PopupMenuItem(value: 'note', child: Text('Nuova Nota')),
          PopupMenuItem(value: 'list', child: Text('Nuova Lista')),
        ],
      ),
    );
  }
}
