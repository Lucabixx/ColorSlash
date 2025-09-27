import 'package:flutter/material.dart';

class InfoScreen extends StatelessWidget {
  const InfoScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Informazioni")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: const [
            Text(
              "ColorSlash - Versione di Test BETA1",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.blueAccent),
            ),
            SizedBox(height: 12),
            Text("Versione 0.1"),
            SizedBox(height: 12),
            Text(
              "ColorSlash è un'app per note multimediali (testo, immagini, audio, video e schizzi). "
              "Le note vengono salvate automaticamente in locale e (se sei loggato) sincronizzate su cloud.",
            ),
            SizedBox(height: 18),
            Text("Progettato da Luca Bixx"),
            SizedBox(height: 40),
            Center(child: Text("© 2025 Luca Bixx")),
          ],
        ),
      ),
    );
  }
}
