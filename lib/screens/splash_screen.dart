import 'dart:async';
import 'package:flutter/material.dart';
import 'login_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _controller =
        AnimationController(vsync: this, duration: const Duration(seconds: 2));
    _scaleAnim =
        CurvedAnimation(parent: _controller, curve: Curves.easeInOutBack);

    _controller.forward();

    Timer(const Duration(seconds: 4), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _floatingIcon(IconData icon, Color color, double dx, double dy) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (_, __) {
        final double t = _controller.value;
        return Transform.translate(
          offset: Offset(dx * (1 - t), dy * (1 - t)),
          child: Opacity(
            opacity: t,
            child: Icon(icon, color: color, size: 36 + 12 * t),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
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
          ScaleTransition(
            scale: _scaleAnim,
            child: Image.asset(
              'assets/icon.png',
              width: 140,
              height: 140,
            ),
          ),
          _floatingIcon(Icons.mic, Colors.redAccent, -80, -120),
          _floatingIcon(Icons.edit, Colors.orangeAccent, 100, -100),
          _floatingIcon(Icons.camera_alt, Colors.lightBlueAccent, -100, 100),
          _floatingIcon(Icons.videocam, Colors.greenAccent, 100, 120),
          const Positioned(
            bottom: 60,
            child: Text(
              "ColorSlash - Versione di Test BETA1",
              style: TextStyle(
                fontSize: 16,
                color: Colors.white70,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
