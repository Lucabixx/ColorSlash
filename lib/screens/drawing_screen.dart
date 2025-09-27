// lib/screens/drawing_screen.dart
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

/// Simple stroke model: list of points, color and strokeWidth
class _Stroke {
  List<Offset> points;
  Color color;
  double strokeWidth;
  _Stroke({required this.points, required this.color, required this.strokeWidth});
}

/// Painter that draws all strokes
class _SketchPainter extends CustomPainter {
  final List<_Stroke> strokes;
  _SketchPainter(this.strokes);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();

    for (final stroke in strokes) {
      final paint = Paint()
        ..color = stroke.color
        ..strokeCap = StrokeCap.round
        ..isAntiAlias = true
        ..strokeWidth = stroke.strokeWidth;

      for (int i = 0; i < stroke.points.length - 1; i++) {
        if (stroke.points[i] != Offset.zero && stroke.points[i + 1] != Offset.zero) {
          canvas.drawLine(stroke.points[i], stroke.points[i + 1], paint);
        }
      }
      // if single point, draw a dot
      if (stroke.points.length == 1) {
        canvas.drawCircle(stroke.points.first, stroke.strokeWidth / 2, paint);
      }
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _SketchPainter oldDelegate) => true;
}

/// Drawing screen:
/// - returns Uint8List PNG when user taps Save (Navigator.pop(pngBytes))
/// - supports color selection, stroke width, undo, clear
class DrawingScreen extends StatefulWidget {
  const DrawingScreen({super.key});

  @override
  State<DrawingScreen> createState() => _DrawingScreenState();
}

class _DrawingScreenState extends State<DrawingScreen> {
  final List<_Stroke> _strokes = [];
  Color _selectedColor = Colors.black;
  double _strokeWidth = 4.0;
  Size _canvasSize = const Size(1024, 1024);
  bool _isSaving = false;

  // Current stroke being drawn
  void _onPanStart(DragStartDetails details, BuildContext ctx) {
    final RenderBox rb = ctx.findRenderObject() as RenderBox;
    final p = rb.globalToLocal(details.globalPosition);
    setState(() {
      _strokes.add(_Stroke(points: [p], color: _selectedColor, strokeWidth: _strokeWidth));
    });
  }

  void _onPanUpdate(DragUpdateDetails details, BuildContext ctx) {
    final RenderBox rb = ctx.findRenderObject() as RenderBox;
    final p = rb.globalToLocal(details.globalPosition);
    setState(() {
      _strokes.last.points.add(p);
    });
  }

  void _onPanEnd(DragEndDetails details) {
    // finish current stroke
    setState(() {});
  }

  Future<Uint8List?> _exportToPngBytes() async {
    if (_strokes.isEmpty) {
      // return a blank white PNG
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      final paintBg = Paint()..color = Colors.white;
      canvas.drawRect(Rect.fromLTWH(0, 0, _canvasSize.width, _canvasSize.height), paintBg);
      final picture = recorder.endRecording();
      final img = await picture.toImage(_canvasSize.width.toInt(), _canvasSize.height.toInt());
      final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
      return byteData?.buffer.asUint8List();
    }

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    // White background
    final bg = Paint()..color = Colors.white;
    canvas.drawRect(Rect.fromLTWH(0, 0, _canvasSize.width, _canvasSize.height), bg);

    // Scale factor in case widget and target sizes differ:
    // Here we match drawing coordinates to canvas size (both in logical pixels),
    // so we draw strokes with the same coordinates.
    // If you want higher-res export, compute a scale factor.
    for (final stroke in _strokes) {
      final paint = Paint()
        ..color = stroke.color
        ..strokeCap = StrokeCap.round
        ..isAntiAlias = true
        ..strokeWidth = stroke.strokeWidth;
      for (int i = 0; i < stroke.points.length - 1; i++) {
        final a = stroke.points[i];
        final b = stroke.points[i + 1];
        canvas.drawLine(a, b, paint);
      }
      if (stroke.points.length == 1) {
        canvas.drawCircle(stroke.points.first, stroke.strokeWidth / 2, paint);
      }
    }

    final picture = recorder.endRecording();
    // convert to image with integer size
    final img = await picture.toImage(_canvasSize.width.toInt(), _canvasSize.height.toInt());
    final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
    return byteData?.buffer.asUint8List();
  }

  Future<void> _saveAndReturn() async {
    setState(() => _isSaving = true);
    try {
      final bytes = await _exportToPngBytes();
      if (bytes == null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Nessun disegno da salvare")));
        return;
      }
      // OPTIONAL: save to file in app documents (uncomment if needed)
      // final dir = await getApplicationDocumentsDirectory();
      // final file = File('${dir.path}/drawing_${DateTime.now().millisecondsSinceEpoch}.png');
      // await file.writeAsBytes(bytes);

      Navigator.of(context).pop(bytes); // return Uint8List to caller
    } catch (e) {
      debugPrint("Errore export drawing: $e");
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Errore durante il salvataggio")));
    } finally {
      setState(() => _isSaving = false);
    }
  }

  void _undo() {
    if (_strokes.isNotEmpty) {
      setState(() => _strokes.removeLast());
    }
  }

  void _clear() {
    setState(() => _strokes.clear());
  }

  Widget _buildColorButton(Color c) {
    return GestureDetector(
      onTap: () => setState(() => _selectedColor = c),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 6),
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: c,
          shape: BoxShape.circle,
          border: Border.all(color: _selectedColor == c ? Colors.white : Colors.transparent, width: 2),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // We capture canvas size via LayoutBuilder
    return Scaffold(
      appBar: AppBar(
        title: const Text("Disegna - ColorSlash"),
        actions: [
          IconButton(icon: const Icon(Icons.undo), onPressed: _undo),
          IconButton(icon: const Icon(Icons.delete_forever), onPressed: _clear),
          IconButton(icon: const Icon(Icons.save), onPressed: _saveAndReturn),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: LayoutBuilder(builder: (context, constraints) {
              // set canvas size to match current widget size
              _canvasSize = Size(constraints.maxWidth, constraints.maxHeight);
              return GestureDetector(
                onPanStart: (d) => _onPanStart(d, context),
                onPanUpdate: (d) => _onPanUpdate(d, context),
                onPanEnd: _onPanEnd,
                child: Container(
                  color: Colors.white, // drawing background (visible while drawing)
                  child: CustomPaint(
                    painter: _SketchPainter(_strokes),
                    child: Container(),
                  ),
                ),
              );
            }),
          ),

          // bottom controls: colors and stroke width
          Container(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
            color: Colors.black87,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // color palette
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildColorButton(Colors.black),
                    _buildColorButton(Colors.blueAccent),
                    _buildColorButton(Colors.redAccent),
                    _buildColorButton(Colors.green),
                    _buildColorButton(Colors.orange),
                    _buildColorButton(Colors.purple),
                    _buildColorButton(Colors.brown),
                    _buildColorButton(Colors.white),
                  ],
                ),
                const SizedBox(height: 8),
                // stroke width slider
                Row(
                  children: [
                    const Text("Dimensione", style: TextStyle(color: Colors.white70)),
                    Expanded(
                      child: Slider(
                        min: 1,
                        max: 30,
                        divisions: 29,
                        value: _strokeWidth,
                        label: "${_strokeWidth.toInt()}",
                        onChanged: (v) => setState(() => _strokeWidth = v),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white10,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(_strokeWidth.toInt().toString(), style: const TextStyle(color: Colors.white)),
                    )
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
      // show saving overlay
      floatingActionButton: _isSaving
          ? const FloatingActionButton(onPressed: null, child: CircularProgressIndicator(color: Colors.white))
          : null,
    );
  }
}
