import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'login_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late AnimationController _rotationController;

  @override
  void initState() {
    super.initState();

    _controller =
        AnimationController(vsync: this, duration: const Duration(seconds: 2))
          ..forward();

    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    )..repeat();

    Timer(const Duration(seconds: 5), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _rotationController.dispose();
    super.dispose();
  }

  Widget _floatingIcon(IconData icon, Color color, double dx, double dy) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (_, __) {
        final double t = Curves.easeOutBack.transform(_controller.value);
        return Transform.translate(
          offset: Offset(dx * (1 - t), dy * (1 - t)),
          child: Opacity(opacity: t, child: Icon(icon, color: color, size: 38)),
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
              Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.black, Colors.blueGrey],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
              Transform(
                alignment: Alignment.center,
                transform: Matrix4.identity()
                  ..rotateY(2 * pi * _rotationController.value),
                child: Image.asset(
                  'assets/icon.png',
                  width: 150,
                  height: 150,
                ),
              ),
              _floatingIcon(Icons.mic, Colors.redAccent, -90, -110),
              _floatingIcon(Icons.edit, Colors.orangeAccent, 100, -100),
              _floatingIcon(Icons.camera_alt, Colors.cyanAccent, -120, 100),
              _floatingIcon(Icons.videocam, Colors.greenAccent, 100, 120),
              const Positioned(
                bottom: 60,
                child: Text(
                  "ColorSlash - Versione di Test BETA1",
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white70,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
