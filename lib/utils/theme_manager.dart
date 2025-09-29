
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AutoThemeMode { system, time, manual }

class ThemeManager extends ChangeNotifier {
  final SharedPreferences prefs;
  ThemeMode _mode = ThemeMode.system;
  AutoThemeMode autoMode = AutoThemeMode.system;
  bool manualDark = false;

  ThemeData get lightTheme => ThemeData.light();
  ThemeData get darkTheme => ThemeData.dark();

  ThemeManager({required this.prefs, required Widget child}) {
    final s = prefs.getString('autoThemeMode') ?? 'system';
    autoMode = AutoThemeMode.values.firstWhere((e) => e.toString().split('.').last==s, orElse: ()=>AutoThemeMode.system);
    manualDark = prefs.getBool('manualDark') ?? false;
    _mode = _calculateMode();
  }

  ThemeMode get currentThemeMode => _mode;

  ThemeMode _calculateMode() {
    if (autoMode==AutoThemeMode.manual) return manualDark?ThemeMode.dark:ThemeMode.light;
    if (autoMode==AutoThemeMode.time) {
      final h = DateTime.now().hour;
      return (h>=19 || h<7) ? ThemeMode.dark : ThemeMode.light;
    }
    return ThemeMode.system;
  }

  void setAutoMode(AutoThemeMode m) {
    autoMode = m;
    prefs.setString('autoThemeMode', m.toString().split('.').last);
    _mode = _calculateMode();
    notifyListeners();
  }

  void setManualDark(bool v) {
    manualDark = v;
    prefs.setBool('manualDark', v);
    if (autoMode==AutoThemeMode.manual) {
      _mode = _calculateMode();
      notifyListeners();
    }
  }

  // Helper to access the manager from widgets
  static ThemeManager of(BuildContext context) {
    return context.findAncestorWidgetOfExactType<_ThemeProvider>()!.manager;
  }
}

class _ThemeProvider extends InheritedWidget {
  final ThemeManager manager;
  const _ThemeProvider({required Widget child, required this.manager}): super(child: child);

  @override
  bool updateShouldNotify(covariant _ThemeProvider oldWidget) => manager!=oldWidget.manager;
}
