import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'package:gallery_saver/gallery_saver.dart';
import 'package:colorslash/utils/app_colors.dart';

class MediaViewerScreen extends StatefulWidget {
  final Map<String, dynamic> media;
  const MediaViewerScreen({super.key, required this.media});

  @override
  State<MediaViewerScreen> createState() => _MediaViewerScreenState();
}

class _MediaViewerScreenState extends State<MediaViewerScreen> {
  Uint8List? _originalImage;
  Uint8List? _filteredBytes;
  bool _loading = true;

  String _filter = "original";
  String _viewMode = "compare"; // "original", "filtered", "compare"

  @override
  void initState() {
    super.initState();
    _loadImage();
  }

  Future<void> _loadImage() async {
    final file = File(widget.media['path']);
    final bytes = await file.readAsBytes();
    setState(() {
      _originalImage = bytes;
      _filteredBytes = bytes;
      _loading = false;
    });
  }

  Future<void> _applyFilter(String type) async {
    if (_originalImage == null) return;
    setState(() => _loading = true);

    final image = img.decodeImage(_originalImage!)!;
    img.Image filtered;

    switch (type) {
      case "grayscale":
        filtered = img.grayscale(image);
        break;
      case "sepia":
        filtered = img.sepia(image);
        break;
      case "invert":
        filtered = img.invert(image);
        break;
      case "contrast":
        filtered = img.adjustColor(image, contrast: 1.5);
        break;
      case "bright":
        filtered = img.adjustColor(image, brightness: 0.2);
        break;
      default:
        filtered = image;
    }

    setState(() {
      _filteredBytes = Uint8List.fromList(img.encodeJpg(filtered));
      _filter = type;
      _loading = false;
    });
  }

  Future<void> _saveEditedImage() async {
    final dir = await getTemporaryDirectory();
    final path = "${dir.path}/edited_${DateTime.now().millisecondsSinceEpoch}.jpg";
    final file = await File(path).writeAsBytes(_filteredBytes!);

    // Dialog: salva in nota o galleria
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Salva immagine"),
        content: const Text(
          "Vuoi salvare questa immagine nella nota o esportarla nella galleria del dispositivo?",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Annulla"),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pop(context, {'type': 'image', 'path': file.path});
            },
            child: const Text("Nella Nota"),
          ),
          ElevatedButton(
            onPressed: () async {
              await GallerySaver.saveImage(file.path);
              if (mounted) {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Immagine salvata in galleria")),
                );
              }
            },
            child: const Text("In Galleria"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text("Visualizza immagine"),
        backgroundColor: AppColors.primary,
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _filteredBytes != null ? _saveEditedImage : null,
          ),
          IconButton(
            icon: Icon(
              _viewMode == "compare"
                  ? Icons.compare
                  : _viewMode == "original"
                      ? Icons.visibility_off
                      : Icons.visibility,
            ),
            tooltip: "Cambia vista",
            onPressed: () {
              setState(() {
                if (_viewMode == "original") {
                  _viewMode = "filtered";
                } else if (_viewMode == "filtered") {
                  _viewMode = "compare";
                } else {
                  _viewMode = "original";
                }
              });
            },
          ),
        ],
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primaryLight),
            )
          : Padding(
              padding: const EdgeInsets.all(8),
              child: _buildImageView(),
            ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          border: const Border(
            top: BorderSide(color: Colors.white12, width: 1),
          ),
        ),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _filterButton("original", "Originale"),
              _filterButton("grayscale", "B/N"),
              _filterButton("sepia", "Sepia"),
              _filterButton("invert", "Inverti"),
              _filterButton("contrast", "Contrasto"),
              _filterButton("bright", "Luce+"),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImageView() {
    if (_originalImage == null || _filteredBytes == null) {
      return const Center(child: Text("Errore nel caricamento immagine"));
    }

    if (_viewMode == "original") {
      return InteractiveViewer(child: Image.file(File(widget.media['path'])));
    } else if (_viewMode == "filtered") {
      return InteractiveViewer(child: Image.memory(_filteredBytes!));
    }

    // Modalità confronto
    return LayoutBuilder(
      builder: (context, constraints) {
        double sliderPos = constraints.maxWidth / 2;
        return StatefulBuilder(
          builder: (context, setInnerState) {
            return GestureDetector(
              onPanUpdate: (details) {
                setInnerState(() {
                  sliderPos = (sliderPos + details.delta.dx)
                      .clamp(0, constraints.maxWidth);
                });
              },
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Positioned.fill(
                    child: Image.memory(_filteredBytes!, fit: BoxFit.contain),
                  ),
                  Positioned.fill(
                    child: ClipRect(
                      clipper: _ImageClipper(sliderPos),
                      child: Image.file(
                        File(widget.media['path']),
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                  Positioned(
                    left: sliderPos - 1,
                    top: 0,
                    bottom: 0,
                    child: Container(
                      width: 3,
                      color: AppColors.primaryLight.withOpacity(0.8),
                    ),
                  ),
                  Positioned(
                    left: sliderPos - 16,
                    top: constraints.maxHeight / 2 - 16,
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.primary,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primaryLight.withOpacity(0.8),
                            blurRadius: 10,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: const Icon(Icons.drag_indicator,
                          size: 24, color: Colors.white),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _filterButton(String type, String label) {
    final selected = _filter == type;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: ElevatedButton(
        onPressed: () => _applyFilter(type),
        style: ElevatedButton.styleFrom(
          backgroundColor:
              selected ? AppColors.primaryLight : AppColors.cardBackground,
          foregroundColor: Colors.white,
        ),
        child: Text(label),
      ),
    );
  }
}

/// Clipper per mostrare metà immagine originale
class _ImageClipper extends CustomClipper<Rect> {
  final double width;
  _ImageClipper(this.width);

  @override
  Rect getClip(Size size) => Rect.fromLTWH(0, 0, width, size.height);

  @override
  bool shouldReclip(covariant _ImageClipper oldClipper) =>
      oldClipper.width != width;
}
