import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'services/auth_service.dart';
import 'services/firebase_service.dart';
import 'screens/splash_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ✅ Inizializzazione Firebase centralizzata
  try {
    await FirebaseService.initializeFirebase(GlobalContext.context);
  } catch (e) {
    debugPrint("Errore durante l'inizializzazione Firebase: $e");
  }

  runApp(const ColorSlashApp());
}

/// ✅ Contesto globale per mostrare SnackBar anche prima dell’avvio completo
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
        navigatorKey: GlobalContext.navigatorKey,
        debugShowCheckedModeBanner: false,
        title: 'ColorSlash - Versione di Test BETA1',
        theme: ThemeData.dark().copyWith(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.blueAccent),
          scaffoldBackgroundColor: Colors.black,
          appBarTheme: const AppBarTheme(
            backgroundColor: Colors.blueAccent,
            foregroundColor: Colors.white,
          ),
          floatingActionButtonTheme: const FloatingActionButtonThemeData(
            backgroundColor: Colors.blueAccent,
          ),
        ),
        home: const SplashScreen(),
      ),
    );
  }
}
