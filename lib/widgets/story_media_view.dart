import 'dart:io';

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../models/post.dart';

class StoryMediaView extends StatefulWidget {
  const StoryMediaView({super.key, required this.media});

  final PostMedia media;

  @override
  State<StoryMediaView> createState() => _StoryMediaViewState();
}

class _StoryMediaViewState extends State<StoryMediaView>
    with WidgetsBindingObserver {
  VideoPlayerController? _video;
  Future<void>? _ready;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    if (widget.media.type == PostMediaType.video) {
      final VideoPlayerController controller = VideoPlayerController.file(
        File(widget.media.path),
      );
      _video = controller;
      _ready = _initializeVideo(controller);
    }
  }

  Future<void> _initializeVideo(VideoPlayerController controller) async {
    await controller.initialize();
    if (!mounted) {
      return;
    }
    await controller.setLooping(true);
    if (mounted) {
      await controller.play();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) {
      _video?.pause();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _video?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final VideoPlayerController? controller = _video;
    if (controller == null) {
      return Image.file(
        File(widget.media.path),
        fit: BoxFit.contain,
        errorBuilder: (_, _, _) => const _UnavailableMedia(),
      );
    }
    return FutureBuilder<void>(
      future: _ready,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const _UnavailableMedia();
        }
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        return ValueListenableBuilder<VideoPlayerValue>(
          valueListenable: controller,
          builder: (context, value, child) => Stack(
            alignment: Alignment.center,
            children: <Widget>[
              Center(
                child: AspectRatio(
                  aspectRatio: value.aspectRatio,
                  child: VideoPlayer(controller),
                ),
              ),
              Align(
                alignment: Alignment.bottomCenter,
                child: IconButton.filled(
                  tooltip: value.isPlaying ? 'Pause video' : 'Play video',
                  onPressed: () =>
                      value.isPlaying ? controller.pause() : controller.play(),
                  icon: Icon(value.isPlaying ? Icons.pause : Icons.play_arrow),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _UnavailableMedia extends StatelessWidget {
  const _UnavailableMedia();

  @override
  Widget build(BuildContext context) => const Center(
    child: Text('Media unavailable', style: TextStyle(color: Colors.white)),
  );
}
