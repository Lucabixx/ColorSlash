import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import 'info_screen.dart';
import 'note_editor_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool? rememberChoice;
  String? preferredType;
  bool _isSyncing = false;
  List<Map<String, dynamic>> _notes = [];
  List<Map<String, dynamic>> _filteredNotes = [];
  final TextEditingController _searchController = TextEditingController();
  String _filterType = "all";

  @override
  void initState() {
    super.initState();
    _loadNotes();
    _autoSync();
    _searchController.addListener(_filterNotes);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<File> _getNotesFile() async {
    final dir = await getApplicationDocumentsDirectory();
    return File("${dir.path}/notes.json");
  }

  Future<void> _loadNotes() async {
    try {
      final file = await _getNotesFile();
      if (await file.exists()) {
        final decoded = jsonDecode(await file.readAsString());
        setState(() {
          _notes = List<Map<String, dynamic>>.from(decoded);
          _filterNotes();
        });
      } else {
        setState(() {
          _notes = [];
          _filteredNotes = [];
        });
      }
    } catch (e) {
      debugPrint("Errore caricamento note: $e");
    }
  }

  void _filterNotes() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredNotes = _notes.where((note) {
        final title = (note['title'] ?? '').toLowerCase();
        final content = (note['content'] ?? '').toLowerCase();
        final type = (note['type'] ?? 'note');
        final matchesQuery =
            title.contains(query) || content.contains(query);
        final matchesType = _filterType == "all" || _filterType == type;
        return matchesQuery && matchesType;
      }).toList();
    });
  }

  Future<void> _saveNotes() async {
    final file = await _getNotesFile();
    await file.writeAsString(jsonEncode(_notes));
  }

  Future<void> _autoSync() async {
    final auth = context.read<AuthService>();
    setState(() => _isSyncing = true);
    try {
      await auth.syncWithCloud(context);
      await _loadNotes();
    } catch (e) {
      debugPrint("Errore sync automatica: $e");
    } finally {
      setState(() => _isSyncing = false);
    }
  }

  void _onAddPressed() {
    if (rememberChoice == true && preferredType != null) {
      _openEditor(preferredType!);
      return;
    }

    showDialog(
      context: context,
      builder: (ctx) {
        bool remember = false;
        String sel = "note";
        return AlertDialog(
          title: const Text("Cosa vuoi creare?"),
          content: StatefulBuilder(builder: (c, setState) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                RadioListTile<String>(
                  title: const Text("Nota"),
                  value: "note",
                  groupValue: sel,
                  onChanged: (v) => setState(() => sel = v ?? "note"),
                ),
                RadioListTile<String>(
                  title: const Text("Lista"),
                  value: "list",
                  groupValue: sel,
                  onChanged: (v) => setState(() => sel = v ?? "list"),
                ),
                CheckboxListTile(
                  value: remember,
                  onChanged: (v) => setState(() => remember = v ?? false),
                  title: const Text("Ricorda la mia scelta"),
                ),
              ],
            );
          }),
          actions: [
            TextButton(
              onPressed: () {
                if (remember) {
                  setState(() {
                    rememberChoice = true;
                    preferredType = sel;
                  });
                }
                Navigator.pop(ctx);
                _openEditor(sel);
              },
              child: const Text("OK"),
            )
          ],
        );
      },
    );
  }

  Future<void> _chooseColor(Map<String, dynamic> note) async {
    final color = await showDialog<Color>(
      context: context,
      builder: (ctx) {
        Color selected = Color(note['color'] ?? Colors.white.value);
        return AlertDialog(
          title: const Text("Scegli un colore"),
          content: SingleChildScrollView(
            child: BlockPicker(
              pickerColor: selected,
              onColorChanged: (c) => selected = c,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, selected),
              child: const Text("OK"),
            ),
          ],
        );
      },
    );

    if (color != null) {
      setState(() {
        note['color'] = color.value;
      });
      await _saveNotes();
    }
  }

  void _openEditor(String type) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            NoteEditorScreen(noteId: UniqueKey().toString(), type: type),
      ),
    );
    if (result == true) {
      await _loadNotes();
    }
  }

  Future<void> _deleteNote(String id) async {
    setState(() {
      _notes.removeWhere((n) => n['id'] == id);
      _filteredNotes.removeWhere((n) => n['id'] == id);
    });
    await _saveNotes();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthService>();
    return Scaffold(
      appBar: AppBar(
        title: const Text("ColorSlash - BETA1"),
        actions: [
          if (_isSyncing)
            const Padding(
              padding: EdgeInsets.only(right: 16),
              child: Center(
                child: SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2)),
              ),
            ),
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const InfoScreen()),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.cloud_sync),
            tooltip: "Sincronizza manualmente",
            onPressed: () async {
              setState(() => _isSyncing = true);
              await auth.syncWithCloud(context);
              await _loadNotes();
              setState(() => _isSyncing = false);
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: "Cerca per titolo o contenuto...",
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                DropdownButton<String>(
                  value: _filterType,
                  items: const [
                    DropdownMenuItem(value: "all", child: Text("Tutte")),
                    DropdownMenuItem(value: "note", child: Text("Note")),
                    DropdownMenuItem(value: "list", child: Text("Liste")),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _filterType = value;
                        _filterNotes();
                      });
                    }
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: _filteredNotes.isEmpty
                ? const Center(
                    child: Text(
                      "Nessuna nota trovata.",
                      style: TextStyle(color: Colors.white70),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(8),
                    itemCount: _filteredNotes.length,
                    itemBuilder: (context, index) {
                      final note = _filteredNotes[index];
                      final color = Color(note['color'] ?? Colors.white.value);
                      return Dismissible(
                        key: ValueKey(note['id']),
                        direction: DismissDirection.endToStart,
                        onDismissed: (_) => _deleteNote(note['id']),
                        background: Container(
                          color: Colors.redAccent,
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 20),
                          child: const Icon(Icons.delete, color: Colors.white),
                        ),
                        child: Card(
                          color: color.withOpacity(0.9),
                          child: ListTile(
                            title: Text(note['title'] ?? 'Senza titolo'),
                            subtitle: Text(
                              note['content'] ?? '',
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            onTap: () async {
                              final result = await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => NoteEditorScreen(
                                    noteId: note['id'],
                                    type: note['type'] ?? 'note',
                                  ),
                                ),
                              );
                              if (result == true) await _loadNotes();
                            },
                            trailing: IconButton(
                              icon: const Icon(Icons.color_lens),
                              onPressed: () => _chooseColor(note),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _onAddPressed,
        backgroundColor: Colors.blueAccent,
        child: const Icon(Icons.add, size: 36),
      ),
      floatingActionButtonLocation:
          FloatingActionButtonLocation.centerDocked,
    );
  }
}

// 🔹 Import del selettore colori
class BlockPicker extends StatelessWidget {
  final Color pickerColor;
  final ValueChanged<Color> onColorChanged;
  const BlockPicker(
      {super.key, required this.pickerColor, required this.onColorChanged});

  @override
  Widget build(BuildContext context) {
    final colors = [
      Colors.white,
      Colors.red,
      Colors.green,
      Colors.blue,
      Colors.yellow,
      Colors.purple,
      Colors.orange,
      Colors.cyan,
      Colors.pink,
      Colors.teal,
      Colors.grey,
    ];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: colors.map((color) {
        return GestureDetector(
          onTap: () => onColorChanged(color),
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color,
              border: Border.all(
                color: pickerColor == color ? Colors.black : Colors.grey,
                width: 2,
              ),
              borderRadius: BorderRadius.circular(6),
            ),
          ),
        );
      }).toList(),
    );
  }
}
