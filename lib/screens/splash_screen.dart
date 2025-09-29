import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../screens/login_screen.dart';
import '../screens/home_screen.dart';
import '../utils/app_colors.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _rotation;
  late final Animation<double> _scale;
  late final Animation<double> _fade;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 3));
    // rotation from 0 to 2*pi (clockwise)
    _rotation = Tween<double>(begin: 0, end: 2 * 3.14159265).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    _scale = Tween<double>(begin: 0.85, end: 1.05).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );
    _fade = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _controller, curve: const Interval(0.3, 1.0, curve: Curves.easeIn)));

    _controller.repeat();

    // After splash delay, navigate to login or home depending on auth state
    Future.delayed(const Duration(seconds: 3), _navigateNext);
  }

  void _navigateNext() {
    final auth = Provider.of<AuthService>(context, listen: false);
    final user = auth.currentUser;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => user == null ? const LoginScreen() : const HomeScreen()),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final logo = Image.asset('assets/splash.png', width: 160, height: 160);
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Stack(
          alignment: Alignment.center,
          children: [
            // orbit glow background
            Positioned.fill(
              child: AnimatedBuilder(
                animation: _controller,
                builder: (_, __) {
                  return Container(
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        colors: [
                          AppColors.primaryLight.withOpacity(0.06 + 0.2 * (_controller.value)),
                          Colors.transparent,
                        ],
                        radius: 0.9,
                      ),
                    ),
                  );
                },
              ),
            ),

            // rotating central logo (clockwise)
            AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return Transform.rotate(
                  angle: _rotation.value,
                  child: Transform.scale(scale: _scale.value, child: FadeTransition(opacity: _fade, child: logo)),
                );
              },
            ),

            // bottom-left small pen icon
            Positioned(
              left: 18,
              bottom: 24,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: AppColors.surface.withOpacity(0.6), borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.create, color: Colors.white, size: 28),
              ),
            ),

            // bottom-right small note icon
            Positioned(
              right: 18,
              bottom: 24,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: AppColors.surface.withOpacity(0.6), borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.sticky_note_2, color: Colors.white, size: 28),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
