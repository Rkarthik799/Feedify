import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/post.dart';
import '../models/story.dart';
import '../providers/story_provider.dart';
import '../screens/create_story_screen.dart';
import '../screens/story_viewer_screen.dart';

class StoryTray extends StatelessWidget {
  const StoryTray({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<StoryProvider>(
      builder: (context, provider, child) {
        final List<Story> stories = provider.stories;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: Text(
                'Stories',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
            if (provider.error != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(provider.error!),
              ),
            SizedBox(
              height: 112,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                itemCount: stories.length + 1,
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return _StoryButton(
                      label: 'Add story',
                      onTap: provider.isLoading
                          ? null
                          : () {
                              Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                  builder: (_) => const CreateStoryScreen(),
                                ),
                              );
                            },
                      child: provider.isLoading
                          ? const CircularProgressIndicator(strokeWidth: 2)
                          : const Icon(Icons.add, size: 30),
                    );
                  }
                  final Story story = stories[index - 1];
                  return _StoryButton(
                    label: 'Your story',
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => StoryViewerScreen(storyId: story.id),
                      ),
                    ),
                    child: story.media.type == PostMediaType.video
                        ? const Icon(Icons.play_circle_outline, size: 32)
                        : Image.file(
                            File(story.media.path),
                            width: 64,
                            height: 64,
                            fit: BoxFit.cover,
                            cacheWidth: 160,
                            errorBuilder: (_, _, _) =>
                                const Icon(Icons.broken_image_outlined),
                          ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

class _StoryButton extends StatelessWidget {
  const _StoryButton({required this.label, required this.child, this.onTap});

  final String label;
  final Widget child;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 88,
    child: InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: Column(
          children: <Widget>[
            Container(
              width: 70,
              height: 70,
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFF6A11CB), width: 2),
              ),
              child: ClipOval(child: Center(child: child)),
            ),
            const SizedBox(height: 5),
            Text(label, maxLines: 1, style: const TextStyle(fontSize: 12)),
          ],
        ),
      ),
    ),
  );
}
