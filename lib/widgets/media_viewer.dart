import 'dart:io';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';

class MediaViewer extends StatefulWidget {
  final List<Map<String, dynamic>> media;
  final int initialIndex;

  const MediaViewer({
    super.key,
    required this.media,
    this.initialIndex = 0,
  });

  @override
  State<MediaViewer> createState() => _MediaViewerState();
}

class _MediaViewerState extends State<MediaViewer> {
  late int _currentIndex;
  VideoPlayerController? _videoController;
  final AudioPlayer _audioPlayer = AudioPlayer();

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _initializeMedia();
  }

  void _initializeMedia() {
    final current = widget.media[_currentIndex];
    if (current['type'] == 'video') {
      _videoController = VideoPlayerController.file(File(current['path']))
        ..initialize().then((_) {
          setState(() {});
        });
    }
  }

  @override
  void dispose() {
    _videoController?.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mediaItem = widget.media[_currentIndex];
    final type = mediaItem['type'];

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black87,
        title: Text("Media ${_currentIndex + 1}/${widget.media.length}"),
      ),
      body: Center(
        child: _buildMediaView(type, mediaItem),
      ),
      bottomNavigationBar: _buildControls(),
    );
  }

  Widget _buildMediaView(String type, Map<String, dynamic> mediaItem) {
    switch (type) {
      case 'image':
        return PhotoViewGallery.builder(
          itemCount: widget.media.where((m) => m['type'] == 'image').length,
          builder: (context, index) {
            final imgList = widget.media.where((m) => m['type'] == 'image').toList();
            return PhotoViewGalleryPageOptions(
              imageProvider: FileImage(File(imgList[index]['path'])),
              minScale: PhotoViewComputedScale.contained,
              maxScale: PhotoViewComputedScale.covered * 3,
            );
          },
          pageController: PageController(initialPage: _currentIndex),
          backgroundDecoration: const BoxDecoration(color: Colors.black),
        );

      case 'video':
        if (_videoController == null || !_videoController!.value.isInitialized) {
          return const CircularProgressIndicator(color: Colors.white);
        }
        return AspectRatio(
          aspectRatio: _videoController!.value.aspectRatio,
          child: VideoPlayer(_videoController!),
        );

      case 'audio':
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.audiotrack, color: Colors.white, size: 100),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () async {
                await _audioPlayer.play(DeviceFileSource(mediaItem['path']));
              },
              icon: const Icon(Icons.play_arrow),
              label: const Text("Riproduci audio"),
            ),
            ElevatedButton.icon(
              onPressed: () async {
                await _audioPlayer.stop();
              },
              icon: const Icon(Icons.stop),
              label: const Text("Stop"),
            ),
          ],
        );

      default:
        return const Text("Formato non supportato", style: TextStyle(color: Colors.white));
    }
  }

  Widget _buildControls() {
    return BottomAppBar(
      color: Colors.black87,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: _currentIndex > 0
                ? () {
                    setState(() {
                      _currentIndex--;
                      _initializeMedia();
                    });
                  }
                : null,
          ),
          IconButton(
            icon: const Icon(Icons.arrow_forward, color: Colors.white),
            onPressed: _currentIndex < widget.media.length - 1
                ? () {
                    setState(() {
                      _currentIndex++;
                      _initializeMedia();
                    });
                  }
                : null,
          ),
        ],
      ),
    );
  }
}
