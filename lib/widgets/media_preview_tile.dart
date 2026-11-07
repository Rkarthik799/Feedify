import 'dart:io';

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../models/post.dart';

class MediaPreviewTile extends StatelessWidget {
  const MediaPreviewTile({
    super.key,
    required this.media,
    this.onRemove,
    this.aspectRatio = 1,
  });

  final PostMedia media;
  final VoidCallback? onRemove;
  final double aspectRatio;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: <Widget>[
        ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: Container(
            color: Colors.grey.shade200,
            child: AspectRatio(
              aspectRatio: aspectRatio,
              child: media.type == PostMediaType.image
                  ? _ImagePreview(media: media)
                  : _VideoPreview(media: media),
            ),
          ),
        ),
        if (onRemove != null)
          Positioned(
            right: 6,
            top: 6,
            child: IconButton.filled(
              tooltip: 'Remove attachment',
              onPressed: onRemove,
              style: IconButton.styleFrom(
                backgroundColor: Colors.black.withValues(alpha: 0.6),
                foregroundColor: Colors.white,
              ),
              icon: const Icon(Icons.close, size: 18),
            ),
          ),
      ],
    );
  }
}

class _ImagePreview extends StatelessWidget {
  const _ImagePreview({required this.media});

  final PostMedia media;

  @override
  Widget build(BuildContext context) {
    if (_isAssetPath(media)) {
      return Image.asset(
        media.path,
        fit: BoxFit.cover,
        cacheWidth: 1080,
        filterQuality: FilterQuality.low,
        errorBuilder:
            (BuildContext context, Object error, StackTrace? stackTrace) =>
                const _FallbackTile(
                  icon: Icons.broken_image_outlined,
                  label: 'Image unavailable',
                ),
      );
    }

    return Image.file(
      File(media.path),
      fit: BoxFit.cover,
      cacheWidth: 1080,
      filterQuality: FilterQuality.low,
      errorBuilder:
          (BuildContext context, Object error, StackTrace? stackTrace) =>
              const _FallbackTile(
                icon: Icons.broken_image_outlined,
                label: 'Image unavailable',
              ),
    );
  }
}

class _VideoPreview extends StatefulWidget {
  const _VideoPreview({required this.media});

  final PostMedia media;

  @override
  State<_VideoPreview> createState() => _VideoPreviewState();
}

class _VideoPreviewState extends State<_VideoPreview> {
  VideoPlayerController? _controller;
  Future<void>? _initializeFuture;

  @override
  void initState() {
    super.initState();
    final VideoPlayerController controller = _isAssetPath(widget.media)
        ? VideoPlayerController.asset(widget.media.path)
        : VideoPlayerController.file(File(widget.media.path));
    _controller = controller;
    _initializeFuture = controller.initialize().then((_) {
      controller
        ..setLooping(true)
        ..setVolume(0)
        ..play();
    });
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final VideoPlayerController? controller = _controller;
    if (controller == null) {
      return const _FallbackTile(
        icon: Icons.broken_image_outlined,
        label: 'Video unavailable',
      );
    }

    return FutureBuilder<void>(
      future: _initializeFuture,
      builder: (BuildContext context, AsyncSnapshot<void> snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator(strokeWidth: 2));
        }
        if (snapshot.hasError) {
          return const _FallbackTile(
            icon: Icons.broken_image_outlined,
            label: 'Video unavailable',
          );
        }

        return Stack(
          fit: StackFit.expand,
          children: <Widget>[
            FittedBox(
              fit: BoxFit.cover,
              child: SizedBox(
                width: controller.value.size.width,
                height: controller.value.size.height,
                child: VideoPlayer(controller),
              ),
            ),
            const Align(
              alignment: Alignment.bottomRight,
              child: Padding(
                padding: EdgeInsets.all(6),
                child: Icon(
                  Icons.videocam_rounded,
                  color: Colors.white,
                  size: 18,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

bool _isAssetPath(PostMedia media) {
  return media.source == PostMediaSource.asset ||
      media.path.startsWith('assets/');
}

class _FallbackTile extends StatelessWidget {
  const _FallbackTile({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Colors.grey.shade300,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(icon, size: 30, color: Colors.grey.shade800),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
