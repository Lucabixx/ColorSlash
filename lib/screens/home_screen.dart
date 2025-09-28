import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:colorslash/services/auth_service.dart';
import 'package:colorslash/services/note_service.dart';
import 'package:colorslash/screens/note_editor_screen.dart';
import 'package:colorslash/screens/note_list_screen.dart';
import 'package:colorslash/models/note.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _searchQuery = '';
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthService>(context);
    final noteService = Provider.of<NoteService>(context);

    final allItems = noteService.items;
    final filteredItems = _searchQuery.isEmpty
        ? allItems
        : allItems
            .where((item) =>
                item.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                item.content
                    .toLowerCase()
                    .contains(_searchQuery.toLowerCase()))
            .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text("ColorSlash"),
        backgroundColor: Colors.deepPurple,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await auth.signOut();
            },
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'sync',
                child: Text("Sincronizza"),
              ),
              const PopupMenuItem(
                value: 'about',
                child: Text("Informazioni"),
              ),
            ],
            onSelected: (value) {
              if (value == 'sync') {
                noteService.syncNotes();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text("Sincronizzazione completata")),
                );
              } else if (value == 'about') {
                showAboutDialog(
                  context: context,
                  applicationName: 'ColorSlash',
                  applicationVersion: '1.0.0',
                  children: [
                    const Text(
                        "App per gestire note e liste colorate, con sincronizzazione e ricerca."),
                  ],
                );
              }
            },
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Cerca nelle note e liste...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(30)),
              ),
              onChanged: (value) {
                setState(() => _searchQuery = value);
              },
            ),
          ),
        ),
      ),
      body: _selectedIndex == 0
          ? NoteListScreen(
              items: filteredItems,
              onTap: (note) => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => NoteEditorScreen(existingNote: note),
                ),
              ),
            )
          : const Center(child: Text("Le mie liste")),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.deepPurple,
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const NoteEditorScreen(),
            ),
          );
        },
        child: const Icon(Icons.add, color: Colors.white),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.deepPurple,
        onTap: (index) {
          setState(() => _selectedIndex = index);
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.note),
            label: "Note",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.checklist),
            label: "Liste",
          ),
        ],
      ),
    );
  }
}
