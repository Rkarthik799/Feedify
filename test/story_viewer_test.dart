import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:social_media/models/post.dart';
import 'package:social_media/models/story.dart';
import 'package:social_media/providers/story_provider.dart';
import 'package:social_media/screens/story_viewer_screen.dart';
import 'package:social_media/widgets/story_media_view.dart';
import 'package:social_media/widgets/story_tray.dart';

void main() {
  testWidgets('an open viewer removes expired media and caption', (
    tester,
  ) async {
    DateTime now = DateTime.utc(2026, 11, 7);
    final Story story = Story(
      id: 'viewed-story',
      media: const PostMedia(
        path: 'missing-test-image.jpg',
        type: PostMediaType.image,
      ),
      createdAt: now,
      caption: 'A temporary moment',
    );
    SharedPreferences.setMockInitialValues(<String, Object>{
      StoryProvider.storageKey: <String>[story.toJson()],
    });
    final Directory directory =
        await tester.runAsync(
              () => Directory.systemTemp.createTemp('feedify_viewer_test_'),
            )
            as Directory;
    final StoryProvider provider = StoryProvider(
      now: () => now,
      mediaDirectory: () async => directory,
    );
    try {
      await tester.runAsync(provider.initialize);
      await tester.pumpWidget(
        ChangeNotifierProvider<StoryProvider>.value(
          value: provider,
          child: MaterialApp(home: StoryViewerScreen(storyId: story.id)),
        ),
      );
      expect(find.byType(StoryMediaView), findsOneWidget);
      expect(find.text(story.caption), findsOneWidget);

      now = now.add(const Duration(hours: 24));
      await tester.runAsync(provider.removeExpiredStories);
      await tester.pump();

      expect(find.text('This story has expired.'), findsOneWidget);
      expect(find.text(story.caption), findsNothing);
      expect(find.byType(StoryMediaView), findsNothing);
    } finally {
      await tester.pumpWidget(const SizedBox.shrink());
      provider.dispose();
      await tester.runAsync(() => directory.delete());
    }
  });

  testWidgets('the story tray opens the story composer', (tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final Directory directory =
        await tester.runAsync(
              () => Directory.systemTemp.createTemp('feedify_composer_test_'),
            )
            as Directory;
    final StoryProvider provider = StoryProvider(
      mediaDirectory: () async => directory,
    );
    try {
      await tester.runAsync(provider.initialize);
      await tester.pumpWidget(
        ChangeNotifierProvider<StoryProvider>.value(
          value: provider,
          child: const MaterialApp(home: Scaffold(body: StoryTray())),
        ),
      );
      await tester.tap(find.text('Add story'));
      await tester.pumpAndSettle();

      expect(find.text('Choose photo or video'), findsOneWidget);
      expect(
        find.text('Your story disappears after 24 hours.'),
        findsOneWidget,
      );
      final TextButton share = tester.widget<TextButton>(
        find.widgetWithText(TextButton, 'Share'),
      );
      expect(share.onPressed, isNull);
    } finally {
      await tester.pumpWidget(const SizedBox.shrink());
      provider.dispose();
      await tester.runAsync(() => directory.delete());
    }
  });
}
