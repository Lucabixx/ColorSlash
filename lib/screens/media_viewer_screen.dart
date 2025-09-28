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
  img.Image? _originalImage;
  Uint8List? _filteredBytes;

  String _filter = "none";
  String _viewMode = "filtered";
  bool _showSparkle = false;

  // Slider personalizzati
  double _brightness = 0.0;
  double _contrast = 1.0;
  double _saturation = 1.0;
  double _temperature = 0.0;

  bool _showAdjustPanel = false;

  @override
  void initState() {
    super.initState();
    _loadImage();
  }

  Future<void> _loadImage() async {
    final file = File(widget.media['path']);
    final bytes = await file.readAsBytes();
    setState(() {
      _originalImage = img.decodeImage(bytes);
      _filteredBytes = bytes;
    });
  }

  Future<void> _applyFilter(String filter) async {
    if (_originalImage == null) return;

    setState(() {
      _filter = filter;
      _showSparkle = true;
    });

    await Future.delayed(const Duration(milliseconds: 150));
    setState(() => _showSparkle = false);

    final edited = img.Image.from(_originalImage!);

    switch (filter) {
      case "grayscale":
        img.grayscale(edited);
        break;
      case "sepia":
        img.sepia(edited);
        break;
      case "invert":
        img.invert(edited);
        break;
      case "vivid":
        img.adjustColor(edited, saturation: 1.5, brightness: 0.1);
        break;
      case "cool":
        img.adjustColor(edited, blue: 30);
        break;
      case "warm":
        img.adjustColor(edited, red: 30);
        break;
      default:
        break;
    }

    // Applica regolazioni personalizzate
    img.adjustColor(
      edited,
      brightness: _brightness,
      contrast: _contrast,
      saturation: _saturation,
      red: _temperature > 0 ? (_temperature * 100).toInt() : 0,
      blue: _temperature < 0 ? (-_temperature * 100).toInt() : 0,
    );

    final newBytes = Uint8List.fromList(img.encodeJpg(edited));
    setState(() => _filteredBytes = newBytes);
  }

  Future<void> _saveImage() async {
    if (_filteredBytes == null) return;

    final choice = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.cardBackground,
        title: const Text("Salvare modifiche?", style: TextStyle(color: Colors.white)),
        content: const Text(
          "Vuoi salvare la nota con il filtro applicato o creare una copia nella galleria?",
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, "note"),
            child: const Text("Sovrascrivi Nota"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, "copy"),
            child: const Text("Copia nella Galleria"),
          ),
        ],
      ),
    );

    if (choice == null) return;

    final dir = await getTemporaryDirectory();
    final path = "${dir.path}/filtered_${DateTime.now().millisecondsSinceEpoch}.jpg";
    final file = File(path);
    await file.writeAsBytes(_filteredBytes!);

    if (choice == "copy") {
      await GallerySaver.saveImage(path);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Immagine salvata nella galleria!")),
      );
    } else {
      Navigator.pop(context, file.path);
    }
  }

  void _toggleViewMode() {
    setState(() {
      if (_viewMode == "filtered") {
        _viewMode = "original";
      } else if (_viewMode == "original") {
        _viewMode = "compare";
      } else {
        _viewMode = "filtered";
      }
    });
  }

  void _toggleAdjustPanel() {
    setState(() => _showAdjustPanel = !_showAdjustPanel);
  }

  @override
  Widget build(BuildContext context) {
    if (_originalImage == null || _filteredBytes == null) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: AppColors.primaryDark,
        title: const Text("Visualizza Immagine"),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveImage,
          ),
          IconButton(
            icon: Icon(
              _viewMode == "filtered"
                  ? Icons.auto_awesome
                  : _viewMode == "original"
                      ? Icons.image
                      : Icons.compare,
            ),
            tooltip: "Cambia vista",
            onPressed: _toggleViewMode,
          ),
        ],
      ),
      body: Stack(
        alignment: Alignment.center,
        children: [
          Center(child: _buildImageView()),
          if (_showSparkle)
            const Positioned(
              top: 100,
              child: Icon(Icons.auto_awesome, size: 80, color: Colors.white70),
            ),
        ],
      ),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildFilterBar(),
          if (_showAdjustPanel) _buildAdjustmentPanel(),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _toggleAdjustPanel,
        backgroundColor: AppColors.primaryLight,
        child: Icon(_showAdjustPanel ? Icons.tune : Icons.tune_outlined),
      ),
    );
  }

  Widget _buildImageView() {
    if (_viewMode == "original") {
      return Image.file(File(widget.media['path']), fit: BoxFit.contain);
    } else if (_viewMode == "filtered") {
      return Image.memory(_filteredBytes!, fit: BoxFit.contain);
    } else {
      return Stack(
        children: [
          Image.memory(_filteredBytes!, fit: BoxFit.contain),
          Opacity(
            opacity: 0.5,
            child: Image.file(File(widget.media['path']), fit: BoxFit.contain),
          ),
        ],
      );
    }
  }

  Widget _buildFilterBar() {
    final filters = {
      "none": "Nessuno",
      "grayscale": "Grigio",
      "sepia": "Seppia",
      "invert": "Inverti",
      "vivid": "Vivido",
      "cool": "Freddo",
      "warm": "Caldo",
    };

    return Container(
      color: AppColors.cardBackground,
      padding: const EdgeInsets.symmetric(vertical: 8),
      height: 100,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: filters.entries.map((entry) {
          final isActive = entry.key == _filter;
          return GestureDetector(
            onTap: () => _applyFilter(entry.key),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.symmetric(horizontal: 10),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isActive ? AppColors.primaryLight : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Icon(Icons.auto_awesome,
                      color: isActive ? Colors.white : Colors.white54),
                  const SizedBox(height: 6),
                  Text(entry.value,
                      style: TextStyle(
                          color: isActive ? Colors.white : Colors.white70,
                          fontSize: 12)),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildAdjustmentPanel() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: AppColors.cardBackground,
      child: Column(
        children: [
          _buildSlider("Luminosità", _brightness, -0.5, 0.5, (v) {
            setState(() => _brightness = v);
            _applyFilter(_filter);
          }),
          _buildSlider("Contrasto", _contrast, 0.5, 2.0, (v) {
            setState(() => _contrast = v);
            _applyFilter(_filter);
          }),
          _buildSlider("Saturazione", _saturation, 0.0, 2.0, (v) {
            setState(() => _saturation = v);
            _applyFilter(_filter);
          }),
          _buildSlider("Temperatura", _temperature, -1.0, 1.0, (v) {
            setState(() => _temperature = v);
            _applyFilter(_filter);
          }),
        ],
      ),
    );
  }

  Widget _buildSlider(
      String label, double value, double min, double max, Function(double) onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
        Slider(
          value: value,
          min: min,
          max: max,
          divisions: 20,
          label: value.toStringAsFixed(2),
          onChanged: (v) => onChanged(v),
          activeColor: AppColors.primaryLight,
          thumbColor: AppColors.primary,
        ),
      ],
    );
  }
}
