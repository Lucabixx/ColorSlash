import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';

import 'services/auth_service.dart';
import 'screens/splash_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp();
  } catch (e) {
    debugPrint("Errore durante l'inizializzazione Firebase: $e");
    // possiamo procedere comunque (ma molte funzionalità Firebase non saranno disponibili)
  }

  runApp(const ColorSlashApp());
}

class ColorSlashApp extends StatelessWidget {
  const ColorSlashApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<AuthService>(
      create: (_) => AuthService(),
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'ColorSlash - Versione di Test BETA1',
        theme: ThemeData.dark().copyWith(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.blueAccent),
          scaffoldBackgroundColor: Colors.black,
          appBarTheme: const AppBarTheme(backgroundColor: Colors.blueAccent, foregroundColor: Colors.white),
          floatingActionButtonTheme: const FloatingActionButtonThemeData(backgroundColor: Colors.blueAccent),
        ),
        home: const SplashScreen(),
      ),
    );
  }
}
