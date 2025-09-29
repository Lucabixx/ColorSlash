import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../utils/app_colors.dart';
import '../services/auth_service.dart';
import '../services/note_service.dart';
import '../models/note_model.dart';
import 'note_editor_screen.dart';
import 'media_gallery_screen.dart';
import 'login_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String search = "";
  String filterType = "tutti";

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthService>(context);
    final noteService = Provider.of<NoteService>(context);
    final notes = noteService.notes.where((n) {
      final q = search.toLowerCase();
      final matchesSearch = n.title.toLowerCase().contains(q) || n.content.toLowerCase().contains(q);
      final matchesType = filterType == "tutti" || n.type == filterType;
      return matchesSearch && matchesType;
    }).toList();

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.settings),
        onPressed: (){ Navigator.of(context).pushNamed('/settings'); },
      ),
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text("ColorSlash"),
        backgroundColor: AppColors.primaryDark,
        actions: [
          IconButton(icon: const Icon(Icons.photo_library_outlined), tooltip: "Galleria Media", onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MediaGalleryScreen()))),
          PopupMenuButton<String>(icon: const Icon(Icons.filter_alt_outlined), onSelected: (v) => setState(() => filterType = v), itemBuilder: (_) => const [
            PopupMenuItem(value: "tutti", child: Text("Tutti")),
            PopupMenuItem(value: "note", child: Text("Solo Note")),
            PopupMenuItem(value: "list", child: Text("Solo Liste")),
          ]),
          IconButton(icon: const Icon(Icons.sync), tooltip: "Sincronizza con Cloud", onPressed: () async {
            final noteService = Provider.of<NoteService>(context, listen: false);
            try {
              await noteService.syncWithCloud(auth);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Sincronizzazione completata")));
            } catch (e) {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Errore sync: $e")));
            }
          }),
          IconButton(icon: const Icon(Icons.logout), tooltip: "Esci", onPressed: () async {
            await auth.signOut();
            if (!mounted) return;
            Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const LoginScreen()), (_) => false);
          }),
        ],
      ),

      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              onChanged: (v) => setState(() => search = v),
              decoration: InputDecoration(prefixIcon: const Icon(Icons.search), hintText: "Cerca note o liste...", filled: true, fillColor: AppColors.surface, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)),
            ),
          ),

          Expanded(
            child: notes.isEmpty
                ? const Center(child: Text("Nessuna nota trovata", style: TextStyle(color: Colors.white70)))
                : ListView.builder(
                    padding: const EdgeInsets.all(10),
                    itemCount: notes.length,
                    itemBuilder: (context, i) {
                      final note = notes[i];
                      final color = Color(int.tryParse(note.colorHex.replaceFirst('#', '0x')) ?? 0xFF1E1E1E);
                      return Card(
                        color: color.withOpacity(0.25),
                        margin: const EdgeInsets.symmetric(vertical: 6),
                        child: ListTile(
                          title: Text(note.title.isNotEmpty ? note.title : "(senza titolo)", style: const TextStyle(color: Colors.white, fontSize: 18)),
                          subtitle: Text(note.content.isEmpty ? "Nessun contenuto" : note.content.split('\n').take(2).join('\n'), maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white70)),
                          onTap: () => _openEditor(note),
                          onLongPress: () => _showPreview(note),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),

      floatingActionButton: Container(
        decoration: BoxDecoration(shape: BoxShape.circle, boxShadow: [
          BoxShadow(color: AppColors.primaryLight.withOpacity(0.8), blurRadius: 20, spreadRadius: 4),
          BoxShadow(color: AppColors.primaryDark.withOpacity(0.6), blurRadius: 40, spreadRadius: 10),
        ]),
        child: FloatingActionButton(
          backgroundColor: AppColors.primary,
          onPressed: () => _createNewNote(),
          child: const Icon(Icons.add, size: 30),
        ),
      ),
    );
  }

  Future<void> _createNewNote() async {
    final noteService = Provider.of<NoteService>(context, listen: false);
    final newNote = noteService.createEmptyNote();
    await Navigator.push(context, MaterialPageRoute(builder: (_) => NoteEditorScreen(existingNote: newNote, type: newNote.type)));
    // reload local notes from service
    await noteService.loadLocalNotes();
  }

  Future<void> _openEditor(NoteModel note) async {
    final noteService = Provider.of<NoteService>(context, listen: false);
    await Navigator.push(context, MaterialPageRoute(builder: (_) => NoteEditorScreen(existingNote: note, type: note.type)));
    await noteService.loadLocalNotes();
  }

  void _showPreview(NoteModel note) {
    showModalBottomSheet(
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      context: context,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(note.title, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          Text(note.content.isEmpty ? "Nessun contenuto" : note.content.split('\n').take(6).join('\n'), style: const TextStyle(color: Colors.white70)),
          const SizedBox(height: 16),
          if (note.attachments.isNotEmpty)
            SizedBox(height: 100, child: ListView(scrollDirection: Axis.horizontal, children: note.attachments.where((a) => a.type == 'image').map((a) => Padding(padding: const EdgeInsets.only(right: 10), child: ClipRRect(borderRadius: BorderRadius.circular(12), child: a.url.startsWith('http') ? Image.network(a.url, width: 100, height: 100, fit: BoxFit.cover) : Image.file(File(a.url), width: 100, height: 100, fit: BoxFit.cover)))) .toList())),
          const SizedBox(height: 16),
          Align(alignment: Alignment.center, child: ElevatedButton.icon(icon: const Icon(Icons.open_in_new), label: const Text("Apri nota completa"), onPressed: () {
            Navigator.pop(ctx);
            _openEditor(note);
          })),
        ]),
      ),
    );
  }
}
