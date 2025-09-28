import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:colorslash/screens/splash_screen.dart';
import 'package:colorslash/services/auth_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
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
        title: 'ColorSlash',
        theme: ThemeData(
          brightness: Brightness.dark,
          primarySwatch: Colors.deepPurple,
          scaffoldBackgroundColor: Colors.black,
          appBarTheme: const AppBarTheme(
            backgroundColor: Colors.deepPurple,
            foregroundColor: Colors.white,
            centerTitle: true,
          ),
          textTheme: const TextTheme(
            bodyText1: TextStyle(color: Colors.white70),
            bodyText2: TextStyle(color: Colors.white70),
          ),
        ),
        home: const SplashScreen(),
      ),
    );
  }
}
