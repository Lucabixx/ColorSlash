import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/note_service.dart';
import '../utils/app_colors.dart';
import 'home_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});
  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _email = TextEditingController();
  final _pass = TextEditingController();
  bool _loading = false;

  Future<void> _register(BuildContext context) async {
    final auth = Provider.of<AuthService>(context, listen: false);
    final noteService = Provider.of<NoteService>(context, listen: false);

    final email = _email.text.trim();
    final pass = _pass.text.trim();
    if (email.isEmpty || pass.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Inserisci email e password")));
      return;
    }

    setState(() => _loading = true);
    final user = await auth.registerWithEmail(email, pass);
    setState(() => _loading = false);

    if (user != null) {
      // carica locali e prova sync
      await noteService.loadLocalNotes();
      try {
        await noteService.syncWithCloud(auth);
      } catch (_) {}
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Registrazione completata: controlla la mail per la verifica")));
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const HomeScreen()));
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Registrazione non riuscita")));
    }
  }

  @override
  void dispose() {
    _email.dispose();
    _pass.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text("Registrati"), backgroundColor: AppColors.primaryDark),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(gradient: AppColors.lightGradient, borderRadius: BorderRadius.circular(12)),
            child: Column(
              children: [
                TextField(controller: _email, keyboardType: TextInputType.emailAddress, decoration: const InputDecoration(hintText: "Email")),
                const SizedBox(height: 12),
                TextField(controller: _pass, obscureText: true, decoration: const InputDecoration(hintText: "Password (min 6)")),
                const SizedBox(height: 16),
                ElevatedButton(onPressed: _loading ? null : () => _register(context), child: _loading ? const CircularProgressIndicator(color: Colors.white) : const Text("Registrati")),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
