import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:provider/provider.dart';

import '../utils/app_colors.dart';
import '../services/auth_service.dart';
import 'home_screen.dart';
import 'login_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _rotation;
  late final Animation<double> _scale;
  late final Animation<double> _fadeText;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 3));
    _rotation = Tween<double>(begin: -0.18, end: 0.18).chain(CurveTween(curve: Curves.easeInOut)).animate(_controller);
    _scale = Tween<double>(begin: 0.76, end: 1.08).chain(CurveTween(curve: Curves.easeOutBack)).animate(_controller);
    _fadeText = CurvedAnimation(parent: _controller, curve: const Interval(0.5, 1.0, curve: Curves.easeIn));

    _controller.repeat(reverse: true);

    Future.delayed(const Duration(seconds: 3), () {
      final auth = Provider.of<AuthService>(context, listen: false);
      final isLogged = auth.currentUser != null;
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          transitionDuration: const Duration(milliseconds: 700),
          pageBuilder: (_, __, ___) => isLogged ? const HomeScreen() : const LoginScreen(),
          transitionsBuilder: (_, anim, __, child) {
            return FadeTransition(opacity: anim, child: child);
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

  Widget _floatingIcon(IconData icon, Color color, double angle, double radius) {
    // un'icona che orbita intorno al logo (per effetto 3D dinamico)
    final dx = math.cos(angle) * radius;
    final dy = math.sin(angle) * radius;
    return Transform.translate(
      offset: Offset(dx, dy),
      child: Icon(icon, color: color.withOpacity(0.95), size: 36),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgColor,
      body: Center(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            final t = _controller.value;
            return Stack(
              alignment: Alignment.center,
              children: [
                // bagliore circolare
                Container(
                  width: 320,
                  height: 320,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        AppColors.primary.withOpacity(0.06 + t * 0.12),
                        Colors.transparent,
                      ],
                      radius: 0.9,
                    ),
                  ),
                ),

                // logo 3D rotante
                Transform(
                  alignment: Alignment.center,
                  transform: Matrix4.identity()
                    ..setEntry(3, 2, 0.001)
                    ..rotateY(_rotation.value),
                  child: Transform.scale(
                    scale: _scale.value,
                    child: Container(
                      width: 160,
                      height: 160,
                      decoration: BoxDecoration(
                        gradient: AppColors.metallicGradient,
                        borderRadius: BorderRadius.circular(28),
                        boxShadow: AppColors.metallicShadow,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(18.0),
                        child: Image.asset('assets/splash.png', fit: BoxFit.contain),
                      ),
                    ),
                  ),
                ),

                // icone che orbitano (microfono, video, foto, pennello)
                Positioned(
                  left: 40,
                  top: 80,
                  child: _floatingIcon(Icons.mic, AppColors.primaryLight, t * math.pi * 2, 0),
                ),
                Positioned(
                  right: 40,
                  top: 80,
                  child: _floatingIcon(Icons.camera_alt, AppColors.accent, -t * math.pi * 2, 0),
                ),

                // testo con fade
                Positioned(
                  bottom: 64,
                  child: Opacity(
                    opacity: _fadeText.value,
                    child: const Text(
                      "ColorSlash",
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 1.4,
                      ),
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
