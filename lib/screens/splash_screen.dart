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

  double progress = 0.0;
  Timer? progressTimer;

  @override
  void initState() {
    super.initState();

    // Animazione ingresso icone
    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..forward();

    // Rotazione logo
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat();

    // Barra di caricamento incrementale
    progressTimer = Timer.periodic(const Duration(milliseconds: 40), (timer) {
      setState(() {
        progress += 0.01;
        if (progress >= 1.0) {
          timer.cancel();
          _goToHome();
        }
      });
    });
  }

  void _goToHome() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const HomeScreen()),
    );
  }

  @override
  void dispose() {
    progressTimer?.cancel();
    _entryController.dispose();
    _rotationController.dispose();
    super.dispose();
  }

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
              // Sfondo
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

              // Icone fluttuanti
              _floatingIcon(Icons.mic, Colors.redAccent, -120, -120, 0.0),
              _floatingIcon(Icons.edit, Colors.orangeAccent, 120, -100, 0.05),
              _floatingIcon(Icons.camera_alt, Colors.cyanAccent, -120, 100, 0.1),
              _floatingIcon(
                  Icons.videocam, Colors.lightGreenAccent, 120, 120, 0.15),

              // Testo e barra in basso
              Positioned(
                bottom: 56,
                child: Column(
                  children: [
                    const Text(
                      'ColorSlash - Versione di Test BETA1',
                      style: TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                    const SizedBox(height: 16),

                    // Barra di progresso animata
                    SizedBox(
                      width: 200,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: LinearProgressIndicator(
                          value: progress,
                          backgroundColor: Colors.white10,
                          color: Colors.blueAccent,
                          minHeight: 6,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "${(progress * 100).toInt()}%",
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
