// lib/pages/about_page.dart
import 'package:flutter/material.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Informazioni")),
      body: Padding(
        padding: const EdgeInsets.all(18.0),
        child: Column(
          children: const [
            Text("ColorSlash", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            SizedBox(height: 12),
            Text("Progettato da Luca Bixx", style: TextStyle(fontSize: 16)),
            SizedBox(height: 12),
            Text("Versione 1.0 - Note multimediali con sincronizzazione automatica su Firebase"),
          ],
        ),
      ),
    );
  }
}