import 'package:flutter/material.dart';
import 'info_screen.dart';
import '../services/auth_service.dart';
import 'package:provider/provider.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();

    return Scaffold(
      appBar: AppBar(
        title: const Text("ColorSlash - BETA1"),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const InfoScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.cloud_sync),
            onPressed: () {
              auth.syncWithCloud(context);
            },
          ),
        ],
      ),
      body: const Center(
        child: Text(
          "Aggiungi una nuova nota o lista con il pulsante +",
          style: TextStyle(color: Colors.white70),
        ),
      ),
      floatingActionButton: FloatingActionButton.large(
        backgroundColor: Colors.blueAccent.shade700,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add, size: 40),
        onPressed: () {
          // TODO: collegare creazione nota/lista
        },
      ),
    );
  }
}
