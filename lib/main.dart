import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';

import 'services/auth_service.dart';
import 'services/note_service.dart';
import 'screens/splash_screen.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'utils/theme.dart';
import 'utils/app_colors.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp();
  } catch (e) {
    debugPrint("⚠️ Firebase non inizializzato: $e");
  }

  runApp(const ColorSlashApp());
}

/// ✅ Chiave globale per SnackBar e Navigator
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
        ChangeNotifierProvider(create: (_) => NoteService()..loadNotes()), // 🔹 Carica note al boot
      ],
      child: MaterialApp(
        title: "ColorSlash",
        navigatorKey: GlobalContext.navigatorKey,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        home: const SplashScreen(),
      ),
    );
  }
}

/// 🔹 Splash screen con effetto orbitante e logo animato
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
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat(reverse: true);

    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);

    Future.delayed(const Duration(seconds: 4), _navigateNext);
  }

  void _navigateNext() {
    final auth = Provider.of<AuthService>(context, listen: false);
    final user = auth.currentUser;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => user == null ? const LoginOrLocal() : const HomeScreen(),
      ),
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
      body: Stack(
        alignment: Alignment.center,
        children: [
          // 🌌 Effetto bagliore orbitante
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return Container(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    colors: [
                      AppColors.primaryLight.withOpacity(0.1 + _controller.value * 0.3),
                      Colors.black,
                    ],
                    radius: 1.2,
                  ),
                ),
              );
            },
          ),

          // ✨ Logo animato
          FadeTransition(
            opacity: _animation,
            child: ScaleTransition(
              scale: _animation,
              child: Hero(
                tag: 'splashLogo',
                child: Image.asset(
                  'assets/splash.png',
                  width: 180,
                  height: 180,
                ),
              ),
            ),
          ),
        ],
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
              const Icon(Icons.color_lens, size: 80, color: AppColors.primaryLight),
              const SizedBox(height: 20),
              const Text(
                "Benvenuto su ColorSlash!",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 30),

              // 🌀 Uso offline
              ElevatedButton.icon(
                icon: const Icon(Icons.offline_bolt),
                label: const Text("Usa senza registrazione"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryLight,
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

              // 🔐 Login Firebase
              OutlinedButton.icon(
                icon: const Icon(Icons.login),
                label: const Text("Accedi o Registrati"),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                  side: const BorderSide(color: AppColors.primaryLight),
                  foregroundColor: AppColors.textPrimary,
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
