
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'theme_manager.dart';
import 'home_screen.dart';
import 'settings_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  runApp(ThemeManager(prefs: prefs, child: MyApp()));
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final themeManager = ThemeManager.of(context);
    return AnimatedBuilder(
      animation: themeManager,
      builder: (context, _) {
        return MaterialApp(
          title: 'ColorSlash',
          theme: themeManager.lightTheme,
          darkTheme: themeManager.darkTheme,
          themeMode: themeManager.currentThemeMode,
          home: HomeScreen(),
          routes: {
            '/settings': (_) => SettingsPage(),
          },
        );
      },
    );
  }
}
