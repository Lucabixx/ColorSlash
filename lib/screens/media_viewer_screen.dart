import 'dart:io';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:video_player/video_player.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:colorslash/utils/app_colors.dart';

class MediaViewerScreen extends StatefulWidget {
  final List<Map<String, dynamic>> mediaList;
  final int initialIndex;

  const MediaViewerScreen({
    super.key,
    required this.mediaList,
    required this.initialIndex,
  });

  @override
  State<MediaViewerScreen> createState() => _MediaViewerScreenState();
}

class _MediaViewerScreenState extends State<MediaViewerScreen> {
  late PageController _pageController;
  late int _currentIndex;
  VideoPlayerController? _videoController;
  FlutterSoundPlayer? _audioPlayer;
  bool _isAudioPlaying = false;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: _currentIndex);
    _setupMedia();
  }

  Future<void> _setupMedia() async {
    _disposeControllers();

    final current = widget.mediaList[_currentIndex];
    if (current['type'] == 'video') {
      _videoController = VideoPlayerController.file(File(current['path']))
        ..initialize().then((_) {
          setState(() {});
          _videoController?.play();
        });
    } else if (current['type'] == 'audio') {
      _audioPlayer = FlutterSoundPlayer();
      await _audioPlayer!.openPlayer();
      await _audioPlayer!.startPlayer(fromURI: current['path']);
      setState(() => _isAudioPlaying = true);
    }
  }

  void _disposeControllers() {
    _videoController?.pause();
    _videoController?.dispose();
    _videoController = null;

    if (_audioPlayer != null) {
      _audioPlayer!.stopPlayer();
      _audioPlayer!.closePlayer();
      _audioPlayer = null;
    }
  }

  @override
  void dispose() {
    _disposeControllers();
    _pageController.dispose();
    super.dispose();
  }

  void _onPageChanged(int index) async {
    setState(() => _currentIndex = index);
    await _setupMedia();
  }

  Future<void> _deleteCurrent() async {
    final current = widget.mediaList[_currentIndex];
    final file = File(current['path']);
    if (await file.exists()) {
      await file.delete();
    }
    setState(() {
      widget.mediaList.removeAt(_currentIndex);
      if (_currentIndex >= widget.mediaList.length && _currentIndex > 0) {
        _currentIndex--;
      }
    });

    if (widget.mediaList.isEmpty && context.mounted) {
      Navigator.pop(context);
    } else {
      await _setupMedia();
    }
  }

  Future<void> _shareCurrent() async {
    final current = widget.mediaList[_currentIndex];
    final file = File(current['path']);
    if (await file.exists()) {
      await Share.shareXFiles([XFile(file.path)], text: 'Guarda questo file da ColorSlash!');
    }
  }

  @override
  Widget build(BuildContext context) {
    final current = widget.mediaList[_currentIndex];

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // 🔹 Swipe per cambiare media
          PageView.builder(
            controller: _pageController,
            onPageChanged: _onPageChanged,
            itemCount: widget.mediaList.length,
            itemBuilder: (context, index) {
              final item = widget.mediaList[index];
              switch (item['type']) {
                case 'image':
                  return Center(
                    child: InteractiveViewer(
                      child: Hero(
                        tag: item['path'],
                        child: Image.file(File(item['path'])),
                      ),
                    ),
                  );

                case 'video':
                  if (_videoController == null || !_videoController!.value.isInitialized) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  return Stack(
                    alignment: Alignment.center,
                    children: [
                      Center(
                        child: AspectRatio(
                          aspectRatio: _videoController!.value.aspectRatio,
                          child: VideoPlayer(_videoController!),
                        ),
                      ),
                      Positioned(
                        bottom: 60,
                        left: 0,
                        right: 0,
                        child: Column(
                          children: [
                            VideoProgressIndicator(
                              _videoController!,
                              allowScrubbing: true,
                              colors: VideoProgressColors(
                                playedColor: AppColors.primaryLight,
                                bufferedColor: Colors.white30,
                                backgroundColor: Colors.white10,
                              ),
                            ),
                            const SizedBox(height: 10),
                            IconButton(
                              iconSize: 60,
                              color: AppColors.primaryLight,
                              icon: Icon(
                                _videoController!.value.isPlaying
                                    ? Icons.pause_circle
                                    : Icons.play_circle,
                              ),
                              onPressed: () {
                                setState(() {
                                  if (_videoController!.value.isPlaying) {
                                    _videoController!.pause();
                                  } else {
                                    _videoController!.play();
                                  }
                                });
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  );

                case 'audio':
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.audiotrack,
                            size: 80, color: AppColors.primaryLight),
                        const SizedBox(height: 20),
                        Text(
                          _isAudioPlaying ? "In riproduzione..." : "Audio fermo",
                          style: const TextStyle(color: Colors.white70),
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                          ),
                          onPressed: () async {
                            if (_isAudioPlaying) {
                              await _audioPlayer?.pausePlayer();
                            } else {
                              await _audioPlayer?.resumePlayer();
                            }
                            setState(() => _isAudioPlaying = !_isAudioPlaying);
                          },
                          icon: Icon(
                            _isAudioPlaying ? Icons.pause : Icons.play_arrow,
                            color: Colors.white,
                          ),
                          label: Text(
                            _isAudioPlaying ? "Pausa" : "Riprendi",
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  );

                default:
                  return const Center(
                    child: Icon(Icons.error_outline, color: Colors.redAccent),
                  );
              }
            },
          ),

          // 🔹 Chiudi
          Positioned(
            top: 40,
            left: 20,
            child: CircleAvatar(
              backgroundColor: Colors.black54,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ),

          // 🔹 Azioni rapide
          Positioned(
            top: 40,
            right: 20,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildActionButton(Icons.share, _shareCurrent, "Condividi"),
                const SizedBox(width: 10),
                _buildActionButton(Icons.delete, _deleteCurrent, "Elimina"),
              ],
            ),
          ),

          // 🔹 Indicatore posizione
          Positioned(
            bottom: 30,
            left: 0,
            right: 0,
            child: Center(
              child: Text(
                "${_currentIndex + 1} / ${widget.mediaList.length}",
                style: const TextStyle(color: Colors.white70, fontSize: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(IconData icon, VoidCallback onTap, String tooltip) {
    return Tooltip(
      message: tooltip,
      child: CircleAvatar(
        backgroundColor: AppColors.primary.withOpacity(0.3),
        child: IconButton(
          icon: Icon(icon, color: Colors.white),
          onPressed: onTap,
        ),
      ),
    );
  }
}
