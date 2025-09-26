// lib/pages/drawing_page.dart
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';

class DrawingPage extends StatefulWidget {
  const DrawingPage({super.key});
  @override State<DrawingPage> createState() => _DrawingPageState();
}

class _DrawingPageState extends State<DrawingPage> {
  final List<Offset> points = [];
  Color selectedColor = Colors.black;
  double strokeWidth = 4.0;

  Future<Uint8List> _exportImage() async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final paint = Paint()..color = selectedColor..strokeWidth = strokeWidth..strokeCap = StrokeCap.round;
    final bg = Paint()..color = Colors.white;
    const w = 1024, h = 1024;
    canvas.drawRect(Rect.fromLTWH(0,0,w.toDouble(),h.toDouble()), bg);
    for (int i = 0; i < points.length - 1; i++) {
      if (points[i] != Offset.zero && points[i+1] != Offset.zero) {
        canvas.drawLine(points[i], points[i+1], paint);
      }
    }
    final pic = recorder.endRecording();
    final img = await pic.toImage(w, h);
    final bd = await img.toByteData(format: ui.ImageByteFormat.png);
    return bd!.buffer.asUint8List();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Disegna"), actions: [IconButton(icon: const Icon(Icons.check), onPressed: () async { final b = await _exportImage(); Navigator.pop(context, b); })]),
      body: GestureDetector(
        onPanUpdate: (d) => setState(() => points.add(d.localPosition)),
        onPanEnd: (_) => points.add(Offset.zero),
        child: CustomPaint(painter: _Painter(points, selectedColor, strokeWidth), child: Container()),
      ),
      bottomNavigationBar: BottomAppBar(
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
          IconButton(icon: const Icon(Icons.color_lens), onPressed: () => setState(() => selectedColor = Colors.black)),
          IconButton(icon: const Icon(Icons.color_lens_outlined), onPressed: () => setState(() => selectedColor = Colors.blue)),
          IconButton(icon: const Icon(Icons.brush), onPressed: () => setState(() => strokeWidth = strokeWidth==4.0?8.0:4.0)),
          IconButton(icon: const Icon(Icons.clear), onPressed: () => setState(() => points.clear())),
        ]),
      ),
    );
  }
}

class _Painter extends CustomPainter {
  final List<Offset> points; final Color color; final double stroke;
  _Painter(this.points,this.color,this.stroke);
  @override void paint(Canvas canvas, Size size) {
    final p = Paint()..color = color..strokeWidth=stroke..strokeCap=StrokeCap.round;
    for (int i=0;i<points.length-1;i++) {
      if (points[i]!=Offset.zero && points[i+1]!=Offset.zero) canvas.drawLine(points[i], points[i+1], p);
    }
  }
  @override bool shouldRepaint(covariant _Painter old) => true;
}