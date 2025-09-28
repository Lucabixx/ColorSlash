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
  String? preferredType; // "note" or "list"
  bool _isSyncing = false;
  List<Map<String, dynamic>> _notes = [];
  List<Map<String, dynamic>> _filteredNotes = [];
  final TextEditingController _searchController = TextEditingController();

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

  /// 🔹 Carica le note locali
  Future<void> _loadNotes() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = File("${dir.path}/notes.json");

      if (await file.exists()) {
        final content = await file.readAsString();
        final decoded = jsonDecode(content);

        setState(() {
          _notes = List<Map<String, dynamic>>.from(decoded);
          _filteredNotes = _notes;
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

  /// 🔹 Filtra note per testo cercato
  void _filterNotes() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredNotes = _notes.where((note) {
        final title = (note['title'] ?? '').toLowerCase();
        final content = (note['content'] ?? '').toLowerCase();
        return title.contains(query) || content.contains(query);
      }).toList();
    });
  }

  /// 🔹 Sincronizzazione automatica
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

  /// 🔹 Creazione nuova nota/lista
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

  void _openEditor(String type) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => NoteEditorScreen(noteId: UniqueKey().toString()),
      ),
    );

    if (result == true) {
      await _loadNotes();
    }
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
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
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

      drawer: Drawer(
        child: ListView(
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(color: Colors.blueAccent),
              child: Center(
                child: Text(
                  "Progettato da Luca Bixx",
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.sync),
              title: const Text("Sincronizza ora"),
              onTap: () async {
                setState(() => _isSyncing = true);
                await auth.syncWithCloud(context);
                await _loadNotes();
                setState(() => _isSyncing = false);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text("Logout"),
              onTap: () async {
                await auth.signOut();
                Navigator.popUntil(context, (route) => route.isFirst);
              },
            ),
          ],
        ),
      ),

      body: _isSyncing
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // 🔍 Campo di ricerca
                Padding(
                  padding: const EdgeInsets.all(8.0),
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

                Expanded(
                  child: _filteredNotes.isEmpty
                      ? const Center(
                          child: Text(
                            "Nessuna nota trovata.\nCrea una nuova nota o modifica la ricerca.",
                            textAlign: TextAlign.center,
                            style:
                                TextStyle(color: Colors.white70, fontSize: 16),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(8),
                          itemCount: _filteredNotes.length,
                          itemBuilder: (context, index) {
                            final note = _filteredNotes[index];
                            return Card(
                              color: Colors.deepPurple.shade100,
                              child: ListTile(
                                title: Text(note['title'] ?? 'Senza titolo'),
                                subtitle: Text(
                                  note['content'] ?? '',
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => NoteEditorScreen(
                                        noteId: note['id'],
                                      ),
                                    ),
                                  ).then((value) async {
                                    if (value == true) await _loadNotes();
                                  });
                                },
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
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }
}
