import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:colorslash/screens/home_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _entryController;
  late final AnimationController _rotationController;

  @override
  void initState() {
    super.initState();

    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..forward();

    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat();

    // Naviga alla HomeScreen dopo 4 secondi
    Timer(const Duration(seconds: 4), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    });
  }

  @override
  void dispose() {
    _entryController.dispose();
    _rotationController.dispose();
    super.dispose();
  }

  /// Icone fluttuanti animate
  Widget _floatingIcon(
      IconData icon, Color color, double dx, double dy, double delay) {
    return AnimatedBuilder(
      animation: _entryController,
      builder: (_, __) {
        final t = Curves.easeOutBack
            .transform((_entryController.value + delay).clamp(0.0, 1.0));
        return Transform.translate(
          offset: Offset(dx * (1 - t), dy * (1 - t)),
          child: Opacity(opacity: t, child: Icon(icon, color: color, size: 44)),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedBuilder(
        animation: _rotationController,
        builder: (context, child) {
          return Stack(
            alignment: Alignment.center,
            children: [
              // Sfondo gradiente
              Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF020617), Color(0xFF061826)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),

              // Logo rotante 3D
              Transform(
                alignment: Alignment.center,
                transform: Matrix4.identity()
                  ..setEntry(3, 2, 0.001)
                  ..rotateY(2 * pi * _rotationController.value),
                child: Image.asset(
                  'assets/icon.png',
                  width: 160,
                  height: 160,
                ),
              ),

              // Icone fluttuanti intorno al logo
              _floatingIcon(Icons.mic, Colors.redAccent, -120, -120, 0.0),
              _floatingIcon(Icons.edit, Colors.orangeAccent, 120, -100, 0.05),
              _floatingIcon(Icons.camera_alt, Colors.cyanAccent, -120, 100, 0.1),
              _floatingIcon(
                  Icons.videocam, Colors.lightGreenAccent, 120, 120, 0.15),

              // Testo in basso
              const Positioned(
                bottom: 56,
                child: Text(
                  'ColorSlash - Versione di Test BETA1',
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
