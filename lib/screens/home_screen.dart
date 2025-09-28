import 'package:flutter/material.dart';
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

  @override
  void initState() {
    super.initState();
    _autoSync();
  }

  /// 🔹 Avvia la sincronizzazione automatica all’apertura
  Future<void> _autoSync() async {
    final auth = context.read<AuthService>();

    setState(() => _isSyncing = true);
    try {
      await auth.syncWithCloud(context);
    } catch (e) {
      debugPrint("Errore durante la sincronizzazione automatica: $e");
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

  void _openEditor(String type) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => NoteEditorScreen(noteId: UniqueKey().toString()),
      ),
    );
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
              title: const Text("Sincronizza adesso"),
              onTap: () async {
                setState(() => _isSyncing = true);
                await auth.syncWithCloud(context);
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
      body: Center(
        child: _isSyncing
            ? const CircularProgressIndicator()
            : const Text(
                "Premi + per creare una nota o una lista multimediale",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white70),
              ),
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
