import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/note_service.dart';
import '../utils/app_colors.dart';
import 'home_screen.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  final emailCtrl = TextEditingController();
  final passCtrl = TextEditingController();
  bool _loading = false;

  late AnimationController _controller;
  late Animation<double> _glowAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat(reverse: true);
    _glowAnim = Tween<double>(begin: 0.9, end: 1.06).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    emailCtrl.dispose();
    passCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleGoogleSignIn(AuthService auth, NoteService noteService) async {
    setState(() => _loading = true);
    final user = await auth.signInWithGoogle();
    setState(() => _loading = false);

    if (user != null) {
      // if NoteService exists, try to sync
      try {
        await noteService.syncWithCloud(auth);
      } catch (_) {}
      if (mounted) {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const HomeScreen()));
      }
    } else {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Accesso con Google non riuscito")));
    }
  }

  Future<void> _handleEmailSignIn(AuthService auth, NoteService noteService) async {
    final email = emailCtrl.text.trim();
    final pass = passCtrl.text.trim();
    if (email.isEmpty || pass.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Inserisci email e password")));
      return;
    }

    setState(() => _loading = true);
    final user = await auth.signInWithEmail(email, pass);
    setState(() => _loading = false);

    if (user != null) {
      try {
        await noteService.syncWithCloud(auth);
      } catch (_) {}
      if (mounted) Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const HomeScreen()));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Accesso non riuscito (controlla credenziali o verifica email)")));
    }
  }

  Future<void> _handleAnonymous(AuthService auth, NoteService noteService) async {
    setState(() => _loading = true);
    final user = await auth.signInAnonymously();
    setState(() => _loading = false);
    if (user != null) {
      // local-only: just open Home (notes are local in NoteService)
      await noteService.loadLocalNotes();
      if (mounted) Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const HomeScreen()));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Impossibile avviare la sessione offline")));
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthService>(context);
    final noteService = Provider.of<NoteService>(context, listen: false);

    return Scaffold(
      body: AnimatedContainer(
        duration: const Duration(milliseconds: 500),
        decoration: const BoxDecoration(
          gradient: LinearGradient(colors: [Color(0xFF001F3F), Color(0xFF004080), Color(0xFF0074D9)], begin: Alignment.topLeft, end: Alignment.bottomRight),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(gradient: AppColors.metallicGradient, borderRadius: BorderRadius.circular(20), boxShadow: AppColors.metallicShadow),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                ScaleTransition(scale: _glowAnim, child: ShaderMask(shaderCallback: (bounds) => AppColors.metallicGradient.createShader(bounds), blendMode: BlendMode.srcIn, child: const Text("ColorSlash", style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold)))),
                const SizedBox(height: 18),

                // email
                TextField(controller: emailCtrl, keyboardType: TextInputType.emailAddress, style: const TextStyle(color: Colors.white), decoration: InputDecoration(hintText: "Email", hintStyle: const TextStyle(color: Colors.white70), filled: true, fillColor: AppColors.surface, border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none))),
                const SizedBox(height: 12),

                // password
                TextField(controller: passCtrl, obscureText: true, style: const TextStyle(color: Colors.white), decoration: InputDecoration(hintText: "Password", hintStyle: const TextStyle(color: Colors.white70), filled: true, fillColor: AppColors.surface, border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none))),
                const SizedBox(height: 16),

                ElevatedButton(
                  onPressed: _loading ? null : () => _handleEmailSignIn(auth, noteService),
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, minimumSize: const Size.fromHeight(48)),
                  child: _loading ? const CircularProgressIndicator(color: Colors.white) : const Text("Accedi"),
                ),
                const SizedBox(height: 10),

                OutlinedButton.icon(
                  onPressed: _loading ? null : () => _handleGoogleSignIn(auth, noteService),
                  icon: const Icon(Icons.account_circle),
                  label: const Text("Accedi con Google"),
                  style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
                ),
                const SizedBox(height: 10),

                ElevatedButton.icon(
                  onPressed: _loading ? null : () => _handleAnonymous(auth, noteService),
                  icon: const Icon(Icons.offline_bolt),
                  label: const Text("Usa senza registrazione (offline)"),
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryLight, minimumSize: const Size.fromHeight(48)),
                ),

                const SizedBox(height: 12),
                TextButton(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RegisterScreen())), child: const Text("Non hai un account? Registrati", style: TextStyle(color: Colors.white70))),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}
