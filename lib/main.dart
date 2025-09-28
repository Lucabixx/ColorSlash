import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';

import 'services/auth_service.dart';
import 'services/note_service.dart';
import 'screens/splash_screen.dart';
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

/// Chiave globale per SnackBar / Navigator
class GlobalContext {
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
  static BuildContext get context => navigatorKey.currentContext!;
}

/// App principale: fornisce i Provider e il LifecycleWatcher
class ColorSlashApp extends StatelessWidget {
  const ColorSlashApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthService()),
        ChangeNotifierProvider(create: (_) => NoteService()..loadLocalNotes()),
      ],
      child: const LifecycleWatcher(
        child: MaterialApp(
          title: "ColorSlash",
          debugShowCheckedModeBanner: false,
          home: SplashScreen(),
          // navigatorKey viene impostato nel widget qui sotto
        ),
      ),
    );
  }
}

/// Widget che espone navigatorKey e gestisce il lifecycle dell'app:
/// - onResume -> prova a sincronizzare se utente loggato
/// - onPause/terminate -> salva/local sync
class LifecycleWatcher extends StatefulWidget {
  final Widget child;
  const LifecycleWatcher({required this.child, super.key});

  @override
  State<LifecycleWatcher> createState() => _LifecycleWatcherState();
}

class _LifecycleWatcherState extends State<LifecycleWatcher> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final noteService = context.read<NoteService?>();
    final auth = context.read<AuthService?>();
    if (noteService == null || auth == null) return;

    if (state == AppLifecycleState.resumed) {
      // app tornata in primo piano -> carica locali e, se loggato, sincronizza
      noteService.loadLocalNotes();
      if (auth.currentUser != null) {
        noteService.syncWithCloud(auth);
      }
    } else if (state == AppLifecycleState.paused || state == AppLifecycleState.detached) {
      // app va in background / termina -> salva locali e (se loggato) push in cloud
      noteService.saveLocalNotes();
      if (auth.currentUser != null) {
        noteService.syncWithCloud(auth);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "ColorSlash",
      navigatorKey: GlobalContext.navigatorKey,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: widget.child,
    );
  }
}
