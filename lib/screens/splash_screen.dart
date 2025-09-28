import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'home_screen.dart'; // importa la tua home
import '../utils/app_colors.dart'; // se usi una palette di colori

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _rotation;
  late Animation<double> _scale;
  late Animation<double> _fadeText;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );

    _rotation = Tween<double>(begin: -0.2, end: 0.2)
        .chain(CurveTween(curve: Curves.easeInOut))
        .animate(_controller);

    _scale = Tween<double>(begin: 0.7, end: 1.2)
        .chain(CurveTween(curve: Curves.easeOutBack))
        .animate(_controller);

    _fadeText = Tween<double>(begin: 0, end: 1)
        .chain(CurveTween(curve: Curves.easeIn))
        .animate(CurvedAnimation(
          parent: _controller,
          curve: const Interval(0.5, 1),
        ));

    _controller.forward();

    Future.delayed(const Duration(seconds: 3), () {
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          transitionDuration: const Duration(milliseconds: 700),
          pageBuilder: (_, __, ___) => const HomeScreen(),
          transitionsBuilder: (_, anim, __, child) {
            return FadeTransition(
              opacity: anim,
              child: child,
            );
          },
        ),
      );
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgColor, // colore sfondo personalizzato
      body: Center(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Transform(
                  alignment: Alignment.center,
                  transform: Matrix4.identity()
                    ..rotateY(_rotation.value)
                    ..scale(_scale.value),
                  child: Image.asset(
                    'assets/splash.png', // il logo che mi hai inviato
                    width: 140,
                    height: 140,
                  ),
                ),
                const SizedBox(height: 25),
                Opacity(
                  opacity: _fadeText.value,
                  child: const Text(
                    "Color Slash",
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
