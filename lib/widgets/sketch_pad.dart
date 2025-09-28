import 'dart:ui' as ui;
import 'dart:typed_data';
import 'package:flutter/material.dart';

class SketchPad extends StatefulWidget {
  final Function(Uint8List) onSave;

  const SketchPad({super.key, required this.onSave});

  @override
  State<SketchPad> createState() => _SketchPadState();
}

class _SketchPadState extends State<SketchPad> {
  List<Offset?> _points = [];
  Color _selectedColor = Colors.black;
  double _strokeWidth = 4.0;

  GlobalKey canvasKey = GlobalKey();

  void _clear() {
    setState(() => _points.clear());
  }

  Future<void> _save() async {
    final boundary = canvasKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
    final image = await boundary.toImage(pixelRatio: 3.0);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    final pngBytes = byteData!.buffer.asUint8List();
    widget.onSave(pngBytes);
    if (context.mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Disegna"),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: _clear,
          ),
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: _save,
          ),
        ],
      ),
      bottomNavigationBar: Container(
        color: Colors.grey[200],
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildColorButton(Colors.black),
            _buildColorButton(Colors.red),
            _buildColorButton(Colors.blue),
            _buildColorButton(Colors.green),
            _buildColorButton(Colors.orange),
            _buildColorButton(Colors.purple),
            Slider(
              value: _strokeWidth,
              min: 2,
              max: 10,
              onChanged: (v) => setState(() => _strokeWidth = v),
            ),
          ],
        ),
      ),
      body: RepaintBoundary(
        key: canvasKey,
        child: GestureDetector(
          onPanStart: (details) {
            setState(() {
              _points.add(details.localPosition);
            });
          },
          onPanUpdate: (details) {
            setState(() {
              _points.add(details.localPosition);
            });
          },
          onPanEnd: (details) {
            _points.add(null);
          },
          child: CustomPaint(
            painter: _SketchPainter(_points, _selectedColor, _strokeWidth),
            size: Size.infinite,
          ),
        ),
      ),
    );
  }

  Widget _buildColorButton(Color color) {
    return GestureDetector(
      onTap: () => setState(() => _selectedColor = color),
      child: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(
            color: _selectedColor == color ? Colors.grey.shade800 : Colors.white,
            width: 2,
          ),
        ),
      ),
    );
  }
}

class _SketchPainter extends CustomPainter {
  final List<Offset?> points;
  final Color color;
  final double strokeWidth;

  _SketchPainter(this.points, this.color, this.strokeWidth);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeCap = StrokeCap.round
      ..strokeWidth = strokeWidth;

    for (int i = 0; i < points.length - 1; i++) {
      if (points[i] != null && points[i + 1] != null) {
        canvas.drawLine(points[i]!, points[i + 1]!, paint);
      }
    }
  }

  @override
  bool shouldRepaint(_SketchPainter oldDelegate) => true;
}
