import 'package:flutter/material.dart';
import 'note_editor_screen.dart';
import 'info_screen.dart';
import '../services/auth_service.dart';
import 'package:provider/provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool? rememberChoice;
  String? preferredType; // "note" o "lista"

  void _openNoteOrList() async {
    if (rememberChoice == true && preferredType != null) {
      _openEditor(preferredType!);
      return;
    }

    showDialog(
      context: context,
      builder: (ctx) {
        String? choice;
        bool remember = false;
        return AlertDialog(
          title: const Text("Cosa vuoi creare?"),
          content: StatefulBuilder(
            builder: (context, setState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  RadioListTile<String>(
                    title: const Text("Nota"),
                    value: "note",
                    groupValue: choice,
                    onChanged: (v) => setState(() => choice = v),
                  ),
                  RadioListTile<String>(
                    title: const Text("Lista"),
                    value: "list",
                    groupValue: choice,
                    onChanged: (v) => setState(() => choice = v),
                  ),
                  Row(
                    children: [
                      Checkbox(
                        value: remember,
                        onChanged: (v) => setState(() => remember = v ?? false),
                      ),
                      const Text("Ricorda la mia scelta"),
                    ],
                  ),
                ],
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () {
                if (choice != null) {
                  setState(() {
                    preferredType = choice;
                    rememberChoice = remember;
                  });
                  Navigator.pop(ctx);
                  _openEditor(choice!);
                }
              },
              child: const Text("Conferma"),
            )
          ],
        );
      },
    );
  }

  void _openEditor(String type) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => NoteEditorScreen(type: type),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthService>();

    return Scaffold(
      appBar: AppBar(
        title: const Text("ColorSlash"),
        actions: [
          IconButton(
            icon: const Icon(Icons.cloud_sync),
            onPressed: () async {
              await auth.syncWithCloud(context);
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
                  style: TextStyle(fontSize: 18, color: Colors.white),
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.info_outline),
              title: const Text("Info sull'app"),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const InfoScreen()),
                );
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
      body: const Center(
        child: Text(
          "Benvenuto su ColorSlash!\nPremi + per iniziare.",
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 18),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _openNoteOrList,
        backgroundColor: Colors.blueAccent,
        child: const Icon(Icons.add, size: 36),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }
}
