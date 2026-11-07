import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/story.dart';
import '../providers/story_provider.dart';
import '../widgets/story_media_view.dart';

class StoryViewerScreen extends StatelessWidget {
  const StoryViewerScreen({super.key, required this.storyId});

  final String storyId;

  @override
  Widget build(BuildContext context) {
    return Consumer<StoryProvider>(
      builder: (context, provider, child) {
        final Story? story = provider.stories
            .where((item) => item.id == storyId)
            .firstOrNull;
        return Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.black,
            foregroundColor: Colors.white,
            title: const Text('Your story'),
          ),
          body: SafeArea(
            child: story == null
                ? const Center(
                    child: Text(
                      'This story has expired.',
                      style: TextStyle(color: Colors.white),
                    ),
                  )
                : Column(
                    children: <Widget>[
                      Expanded(
                        child: StoryMediaView(
                          key: ValueKey<String>(story.id),
                          media: story.media,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: <Widget>[
                            if (story.caption.isNotEmpty) ...<Widget>[
                              Text(
                                story.caption,
                                style: const TextStyle(color: Colors.white),
                              ),
                              const SizedBox(height: 8),
                            ],
                            Text(
                              'Expires ${DateFormat('MMM d, h:mm a').format(story.expiresAt.toLocal())}',
                              style: const TextStyle(color: Colors.white70),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
          ),
        );
      },
    );
  }
}
