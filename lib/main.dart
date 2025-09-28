import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'services/auth_service.dart';
import 'screens/splash_screen.dart';
import 'utils/theme.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // ✅ Inizializza Firebase solo se disponibile
    await Firebase.initializeApp();
  } catch (e) {
    debugPrint("⚠️ Firebase non inizializzato: $e");
  }

  runApp(const ColorSlashApp());
}

/// ✅ Chiave globale per usare SnackBar e Navigator ovunque
class GlobalContext {
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
  static BuildContext get context => navigatorKey.currentContext!;
}

class ColorSlashApp extends StatelessWidget {
  const ColorSlashApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthService()),
      ],
      child: MaterialApp(
        title: "ColorSlash",
        navigatorKey: GlobalContext.navigatorKey,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme, // 🌙 Tema personalizzato
        home: const SplashScreen(), // Mostra splash all'avvio
      ),
    );
  }
}

/// 🔹 Splash screen con animazione iniziale
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
    _controller.forward();

    Future.delayed(const Duration(seconds: 3), _navigateNext);
  }

  void _navigateNext() {
    final auth = Provider.of<AuthService>(context, listen: false);
    final user = auth.currentUser;

    // 🔹 Se non loggato, permette uso locale o login
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => user == null ? const LoginOrLocal() : const HomeScreen()),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: FadeTransition(
          opacity: _animation,
          child: ScaleTransition(
            scale: _animation,
            child: Image.asset(
              'assets/splash.png',
              width: 160,
              height: 160,
            ),
          ),
        ),
      ),
    );
  }
}

/// 🔹 Schermata che permette di scegliere tra uso locale o login
class LoginOrLocal extends StatelessWidget {
  const LoginOrLocal({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.color_lens, size: 80, color: Colors.purpleAccent),
              const SizedBox(height: 20),
              const Text(
                "Benvenuto su ColorSlash!",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 30),
              ElevatedButton.icon(
                icon: const Icon(Icons.offline_bolt),
                label: const Text("Usa senza registrazione"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purpleAccent,
                  minimumSize: const Size(double.infinity, 50),
                ),
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => const HomeScreen()),
                  );
                },
              ),
              const SizedBox(height: 15),
              OutlinedButton.icon(
                icon: const Icon(Icons.login),
                label: const Text("Accedi o Registrati"),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                  side: const BorderSide(color: Colors.purpleAccent),
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
