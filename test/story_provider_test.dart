import 'dart:async';
import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:social_media/models/post.dart';
import 'package:social_media/models/story.dart';
import 'package:social_media/providers/story_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory sandbox;
  late Directory mediaDirectory;
  late File source;
  late DateTime now;
  late StoryProvider provider;

  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    sandbox = await Directory.systemTemp.createTemp('feedify_story_test_');
    mediaDirectory = Directory(
      '${sandbox.path}${Platform.pathSeparator}stories',
    );
    source = await File(
      '${sandbox.path}${Platform.pathSeparator}gallery.jpg',
    ).writeAsString('test media');
    now = DateTime.utc(2026, 11, 7, 12);
    provider = StoryProvider(
      now: () => now,
      mediaDirectory: () async => mediaDirectory,
    );
  });

  tearDown(() async {
    provider.dispose();
    if (await mediaDirectory.exists()) {
      await for (final FileSystemEntity entry in mediaDirectory.list()) {
        await entry.delete();
      }
      await mediaDirectory.delete();
    }
    await source.delete();
    await sandbox.delete();
  });

  Future<void> addStory({String caption = ''}) => provider.addStory(
    media: PostMedia(path: source.path, type: PostMediaType.image),
    caption: caption,
  );

  test('story expires at exactly 24 hours', () {
    final Story story = Story(
      id: 'boundary',
      media: PostMedia(path: source.path, type: PostMediaType.image),
      createdAt: now,
    );
    expect(
      story.isExpired(now.add(const Duration(hours: 23, minutes: 59))),
      isFalse,
    );
    expect(story.isExpired(now.add(const Duration(hours: 24))), isTrue);
  });

  test('copies media and restores stories from shared preferences', () async {
    await provider.initialize();
    await addStory(caption: ' A moment ');
    final Story saved = provider.stories.single;
    expect(saved.caption, 'A moment');
    expect(saved.media.path, isNot(source.path));
    expect(await File(saved.media.path).readAsString(), 'test media');

    final StoryProvider restored = StoryProvider(
      now: () => now,
      mediaDirectory: () async => mediaDirectory,
    );
    try {
      await restored.initialize();
      expect(restored.stories.single.id, saved.id);
      expect(restored.stories.single.createdAt, now);
      expect(restored.stories.single.media.path, saved.media.path);
    } finally {
      restored.dispose();
    }
  });

  test(
    'startup removes expired records and copies but keeps gallery files',
    () async {
      await provider.initialize();
      await addStory();
      final String expiredPath = provider.stories.single.media.path;
      now = now.add(const Duration(hours: 24));

      await provider.initialize();

      expect(provider.stories, isEmpty);
      expect(await File(expiredPath).exists(), isFalse);
      expect(await source.exists(), isTrue);
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      expect(prefs.getStringList(StoryProvider.storageKey), isEmpty);
    },
  );

  test('pruning preserves newer stories and their media', () async {
    await provider.initialize();
    await addStory(caption: 'older');
    final String expiredPath = provider.stories.single.media.path;
    now = now.add(const Duration(hours: 23));
    await addStory(caption: 'newer');
    final String activePath = provider.stories.first.media.path;
    now = now.add(const Duration(hours: 1));

    await provider.removeExpiredStories();

    expect(provider.stories.single.caption, 'newer');
    expect(await File(expiredPath).exists(), isFalse);
    expect(await File(activePath).exists(), isTrue);
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    expect(prefs.getStringList(StoryProvider.storageKey), hasLength(1));
  });

  test('damaged records do not prevent loading valid stories', () async {
    await provider.initialize();
    await addStory();
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(StoryProvider.storageKey, <String>[
      'not json',
      '{"id": 42}',
      ...prefs.getStringList(StoryProvider.storageKey)!,
    ]);

    await provider.initialize();

    expect(provider.stories, hasLength(1));
    expect(provider.error, isNull);
    expect(prefs.getStringList(StoryProvider.storageKey), hasLength(1));
  });

  test('resume cleans expired stories after time in background', () async {
    await provider.initialize();
    await addStory();
    now = now.add(const Duration(days: 2));
    final Completer<void> cleaned = Completer<void>();
    provider.addListener(() {
      if (!cleaned.isCompleted && provider.stories.isEmpty) {
        cleaned.complete();
      }
    });

    provider.didChangeAppLifecycleState(AppLifecycleState.resumed);
    await cleaned.future.timeout(const Duration(seconds: 5));
    // Queue a cleanup to wait for the complete lifecycle operation, including I/O.
    await provider.removeExpiredStories();

    final SharedPreferences prefs = await SharedPreferences.getInstance();
    expect(prefs.getStringList(StoryProvider.storageKey), isEmpty);
    expect(await source.exists(), isTrue);
  });

  test('concurrent uploads and cleanup do not lose stories', () async {
    await provider.initialize();
    await Future.wait<void>(<Future<void>>[
      addStory(caption: 'first'),
      provider.removeExpiredStories(),
      addStory(caption: 'second'),
    ]);

    final SharedPreferences prefs = await SharedPreferences.getInstance();
    expect(prefs.getStringList(StoryProvider.storageKey), hasLength(2));
    expect(provider.stories.map((story) => story.caption), <String>[
      'second',
      'first',
    ]);
    for (final Story story in provider.stories) {
      expect(await File(story.media.path).exists(), isTrue);
    }
  });

  test('timer removes stories without a refresh', () async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final Story expiring = Story(
      id: 'about-to-expire',
      media: PostMedia(path: source.path, type: PostMediaType.image),
      createdAt: DateTime.now()
          .subtract(Story.lifetime)
          .add(const Duration(seconds: 1)),
    );
    await prefs.setStringList(StoryProvider.storageKey, <String>[
      expiring.toJson(),
    ]);
    final StoryProvider timedProvider = StoryProvider(
      mediaDirectory: () async => mediaDirectory,
    );
    try {
      await timedProvider.initialize();
      expect(timedProvider.stories, hasLength(1));
      final Completer<void> expired = Completer<void>();
      timedProvider.addListener(() {
        if (!expired.isCompleted && timedProvider.stories.isEmpty) {
          expired.complete();
        }
      });
      await expired.future.timeout(const Duration(seconds: 5));
      // Wait for the timer's queued persistence and file cleanup to finish.
      await timedProvider.removeExpiredStories();
      expect(prefs.getStringList(StoryProvider.storageKey), isEmpty);
    } finally {
      timedProvider.dispose();
    }
  });
}
