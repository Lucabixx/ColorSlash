import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import 'home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  bool isLoading = false;
  bool isRegisterMode = false;
  String? errorMessage;

  Future<void> _submit(BuildContext context) async {
    final auth = context.read<AuthService>();
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      if (isRegisterMode) {
        await auth.signUpWithEmail(
          emailController.text.trim(),
          passwordController.text.trim(),
        );
      } else {
        await auth.signInWithEmail(
          emailController.text.trim(),
          passwordController.text.trim(),
        );
      }

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
      }
    } catch (e) {
      setState(() => errorMessage = e.toString());
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _loginWithGoogle(BuildContext context) async {
    final auth = context.read<AuthService>();
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      await auth.signInWithGoogle();
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
      }
    } catch (e) {
      setState(() => errorMessage = e.toString());
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final titleText = isRegisterMode ? "Crea un Account" : "Accedi";
    final buttonText = isRegisterMode ? "Registrati" : "Accedi";

    return Scaffold(
      backgroundColor: const Color(0xFF0A0E21),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo
              Image.asset(
                'assets/icon.png',
                width: 120,
                height: 120,
              ),
              const SizedBox(height: 20),

              const Text(
                "ColorSlash",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 30),

              Text(
                titleText,
                style: const TextStyle(color: Colors.white70, fontSize: 18),
              ),
              const SizedBox(height: 20),

              // Email
              TextField(
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  filled: true,
                  fillColor: Color(0xFF1D1E33),
                  hintText: "Email",
                  hintStyle: TextStyle(color: Colors.white60),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(10)),
                  ),
                ),
                style: const TextStyle(color: Colors.white),
              ),
              const SizedBox(height: 16),

              // Password
              TextField(
                controller: passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  filled: true,
                  fillColor: Color(0xFF1D1E33),
                  hintText: "Password",
                  hintStyle: TextStyle(color: Colors.white60),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(10)),
                  ),
                ),
                style: const TextStyle(color: Colors.white),
              ),
              const SizedBox(height: 20),

              if (errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Text(
                    errorMessage!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.redAccent),
                  ),
                ),

              // Pulsante Accedi / Registrati
              ElevatedButton(
                onPressed: isLoading ? null : () => _submit(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: isLoading
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(color: Colors.white),
                      )
                    : Text(buttonText),
              ),
              const SizedBox(height: 12),

              // Login con Google
              OutlinedButton.icon(
                onPressed: isLoading ? null : () => _loginWithGoogle(context),
                icon: Image.asset('assets/google_icon.png', width: 22),
                label: const Text(
                  "Accedi con Google",
                  style: TextStyle(color: Colors.white),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.white24),
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 20),

              // Toggle modalità
              TextButton(
                onPressed: () {
                  setState(() {
                    isRegisterMode = !isRegisterMode;
                    errorMessage = null;
                  });
                },
                child: Text(
                  isRegisterMode
                      ? "Hai già un account? Accedi"
                      : "Non hai un account? Registrati",
                  style: const TextStyle(color: Colors.white70),
                ),
              ),

              const SizedBox(height: 20),
              const Text(
                "Versione di Test BETA1",
                style: TextStyle(color: Colors.white54, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
