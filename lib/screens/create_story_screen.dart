import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../models/post.dart';
import '../providers/story_provider.dart';
import '../widgets/story_media_view.dart';

class CreateStoryScreen extends StatefulWidget {
  const CreateStoryScreen({super.key});

  @override
  State<CreateStoryScreen> createState() => _CreateStoryScreenState();
}

class _CreateStoryScreenState extends State<CreateStoryScreen> {
  final TextEditingController _caption = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  PostMedia? _media;
  bool _isPicking = false;
  bool _isSaving = false;

  Future<void> _pickMedia() async {
    setState(() => _isPicking = true);
    try {
      final XFile? file = await _picker.pickMedia(
        imageQuality: 85,
        requestFullMetadata: false,
      );
      if (!mounted || file == null) {
        return;
      }
      final bool isVideo =
          (file.mimeType ?? '').startsWith('video/') ||
          RegExp(
            r'\.(mp4|mov|m4v|avi|mkv|webm|3gp)$',
            caseSensitive: false,
          ).hasMatch(file.path);
      setState(() {
        _media = PostMedia(
          path: file.path,
          type: isVideo ? PostMediaType.video : PostMediaType.image,
        );
      });
    } on PlatformException catch (error) {
      if (mounted) {
        final bool denied = error.code.contains('access_denied');
        _showError(
          denied
              ? 'Allow photo access in device settings to add a story.'
              : 'Could not open your gallery. Please try again.',
        );
      }
    } catch (_) {
      if (mounted) {
        _showError('Could not select media. Please try again.');
      }
    } finally {
      if (mounted) {
        setState(() => _isPicking = false);
      }
    }
  }

  Future<void> _share() async {
    final PostMedia? media = _media;
    if (media == null || _isSaving) {
      return;
    }
    setState(() => _isSaving = true);
    try {
      await context.read<StoryProvider>().addStory(
        media: media,
        caption: _caption.text,
      );
      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (_) {
      if (mounted) {
        _showError('Could not save your story. Please try again.');
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  void dispose() {
    _caption.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool busy = _isPicking || _isSaving;
    return PopScope(
      canPop: !_isSaving,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Add story'),
          actions: <Widget>[
            TextButton(
              onPressed: _media == null || busy ? null : _share,
              child: _isSaving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Share'),
            ),
          ],
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                const Text('Your story disappears after 24 hours.'),
                const SizedBox(height: 12),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: ColoredBox(
                      color: Colors.black,
                      child: _media == null
                          ? const Center(
                              child: Icon(
                                Icons.add_photo_alternate_outlined,
                                size: 64,
                                color: Colors.white,
                              ),
                            )
                          : StoryMediaView(
                              key: ValueKey<String>(_media!.path),
                              media: _media!,
                            ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: busy ? null : _pickMedia,
                  icon: const Icon(Icons.photo_library_outlined),
                  label: Text(
                    _isPicking
                        ? 'Opening gallery…'
                        : _media == null
                        ? 'Choose photo or video'
                        : 'Change media',
                  ),
                ),
                TextField(
                  controller: _caption,
                  enabled: !_isSaving,
                  maxLength: 200,
                  decoration: const InputDecoration(
                    hintText: 'Add a caption (optional)',
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
