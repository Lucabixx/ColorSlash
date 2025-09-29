// lib/widgets/sketch_pad.dart
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

/// Widget semplice per disegno a mano libera.
/// Restituisce i bytes PNG tramite la callback `onSave`.
class SketchPad extends StatefulWidget {
  final Future<void> Function(Uint8List) onSave;
  final Color backgroundColor;
  final Color penColor;
  final double penWidth;

  const SketchPad({
    Key? key,
    required this.onSave,
    this.backgroundColor = Colors.white,
    this.penColor = Colors.black,
    this.penWidth = 4.0,
  }) : super(key: key);

  @override
  State<SketchPad> createState() => _SketchPadState();
}

class _SketchPadState extends State<SketchPad> {
  final GlobalKey _repaintKey = GlobalKey();
  final List<List<Offset>> _strokes = [];
  List<Offset> _current = [];
  Color _penColor = Colors.black;
  double _penWidth = 4.0;

  @override
  void initState() {
    super.initState();
    _penColor = widget.penColor;
    _penWidth = widget.penWidth;
  }

  void _startStroke(Offset p) {
    _current = [p];
    setState(() {});
  }

  void _appendStroke(Offset p) {
    _current.add(p);
    setState(() {});
  }

  void _endStroke() {
    if (_current.isNotEmpty) {
      _strokes.add(List.from(_current));
      _current.clear();
      setState(() {});
    }
  }

  void _undo() {
    if (_strokes.isNotEmpty) {
      _strokes.removeLast();
      setState(() {});
    }
  }

  void _clear() {
    _strokes.clear();
    _current.clear();
    setState(() {});
  }

  Future<void> _savePng() async {
    try {
      final boundary = _repaintKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      final devicePixelRatio = MediaQuery.of(context).devicePixelRatio;
      final ui.Image img = await boundary.toImage(pixelRatio: devicePixelRatio);
      final ByteData? byteData = await img.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return;
      final bytes = byteData.buffer.asUint8List();

      // Callback al chiamante
      await widget.onSave(bytes);
      if (context.mounted) Navigator.of(context).pop();
    } catch (e) {
      debugPrint('SketchPad save error: $e');
      // opzionale: mostrare SnackBar
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Errore salvataggio disegno: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black54,
      appBar: AppBar(
        title: const Text('Disegna (Sketch)'),
        actions: [
          IconButton(onPressed: _undo, icon: const Icon(Icons.undo)),
          IconButton(onPressed: _clear, icon: const Icon(Icons.clear)),
          IconButton(onPressed: _savePng, icon: const Icon(Icons.save)),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // area di disegno
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: RepaintBoundary(
                  key: _repaintKey,
                  child: Container(
                    decoration: BoxDecoration(
                      color: widget.backgroundColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: GestureDetector(
                      onPanStart: (details) {
                        final renderBox = context.findRenderObject() as RenderBox;
                        _startStroke(renderBox.globalToLocal(details.globalPosition));
                      },
                      onPanUpdate: (details) {
                        final renderBox = context.findRenderObject() as RenderBox;
                        _appendStroke(renderBox.globalToLocal(details.globalPosition));
                      },
                      onPanEnd: (_) => _endStroke(),
                      child: CustomPaint(
                        painter: _SketchPainter(strokes: _strokes, current: _current, color: _penColor, strokeWidth: _penWidth),
                        child: Container(),
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // toolbar colori / spessore
            Container(
              color: Colors.black87,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  const Text('Colore:', style: TextStyle(color: Colors.white)),
                  const SizedBox(width: 8),
                  ...[
                    Colors.black,
                    Colors.white,
                    Colors.red,
                    Colors.green,
                    Colors.blue,
                    Colors.orange,
                    Colors.purple,
                  ].map((c) => GestureDetector(
                        onTap: () => setState(() => _penColor = c),
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 6),
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: c,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white24, width: _penColor == c ? 2 : 1),
                          ),
                        ),
                      )),
                  const SizedBox(width: 12),
                  const Text('Spessore:', style: TextStyle(color: Colors.white)),
                  Expanded(
                    child: Slider(
                      value: _penWidth,
                      min: 1,
                      max: 20,
                      divisions: 19,
                      onChanged: (v) => setState(() => _penWidth = v),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SketchPainter extends CustomPainter {
  final List<List<Offset>> strokes;
  final List<Offset> current;
  final Color color;
  final double strokeWidth;

  _SketchPainter({
    required this.strokes,
    required this.current,
    required this.color,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    for (final stroke in strokes) {
      _drawStroke(canvas, stroke, paint);
    }
    _drawStroke(canvas, current, paint);
  }

  void _drawStroke(Canvas canvas, List<Offset> points, Paint paint) {
    if (points.isEmpty) return;
    for (int i = 0; i < points.length - 1; i++) {
      if (points[i] != null && points[i + 1] != null) {
        canvas.drawLine(points[i], points[i + 1], paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _SketchPainter old) {
    return old.strokes != strokes || old.current != current || old.color != color || old.strokeWidth != strokeWidth;
  }
}
