import 'dart:async';
import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../models/post.dart';
import '../models/story.dart';

class StoryProvider extends ChangeNotifier with WidgetsBindingObserver {
  StoryProvider({
    DateTime Function()? now,
    Future<Directory> Function()? mediaDirectory,
  }) : _now = now ?? DateTime.now,
       _mediaDirectory = mediaDirectory ?? _defaultMediaDirectory {
    WidgetsBinding.instance.addObserver(this);
  }

  static const String storageKey = 'local_user_stories';
  final DateTime Function() _now;
  final Future<Directory> Function() _mediaDirectory;
  List<Story> _stories = <Story>[];
  Future<void> _pending = Future<void>.value();
  Timer? _expiryTimer;
  bool _disposed = false;
  bool _isLoading = true;
  String? _error;

  List<Story> get stories => List<Story>.unmodifiable(
    _stories.where((story) => !story.isExpired(_now())),
  );
  bool get isLoading => _isLoading;
  String? get error => _error;

  static Future<Directory> _defaultMediaDirectory() async {
    final Directory support = await getApplicationSupportDirectory();
    return Directory('${support.path}${Platform.pathSeparator}stories');
  }

  // Serialize changes so expiry and uploads cannot overwrite each other's data.
  Future<T> _enqueue<T>(Future<T> Function() action) {
    final Future<T> result = _pending.then((_) => action());
    _pending = result.then<void>((_) {}, onError: (Object _, StackTrace _) {});
    return result;
  }

  Future<void> initialize() => _enqueue(() async {
    _isLoading = true;
    _error = null;
    _notify();
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final List<Story> restored = <Story>[];
      for (final String value
          in prefs.getStringList(storageKey) ?? <String>[]) {
        try {
          final Story story = Story.fromJson(value);
          if (!story.isExpired(_now())) {
            restored.add(story);
          }
        } on FormatException {
          // One damaged record must not prevent loading the other stories.
          continue;
        } on TypeError {
          continue;
        }
      }
      restored.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      _stories = restored;
      await _persist();
      await _cleanUnusedMedia();
    } catch (_) {
      _error = 'Could not load stories. Pull down to try again.';
    } finally {
      _isLoading = false;
      _scheduleExpiry();
      _notify();
    }
  });

  Future<void> addStory({required PostMedia media, String caption = ''}) =>
      _enqueue(() async {
        final Directory directory = await _mediaDirectory();
        await directory.create(recursive: true);
        final String id = const Uuid().v4();
        final String extension =
            RegExp(r'\.[a-zA-Z0-9]{1,8}$').firstMatch(media.path)?.group(0) ??
            (media.type == PostMediaType.video ? '.mp4' : '.jpg');
        final File copy = await File(
          media.path,
        ).copy('${directory.path}${Platform.pathSeparator}$id$extension');
        final Story story = Story(
          id: id,
          media: PostMedia(path: copy.path, type: media.type),
          createdAt: _now().toUtc(),
          caption: caption.trim(),
        );
        _stories.insert(0, story);
        try {
          await _persist();
        } catch (_) {
          _stories.removeWhere((item) => item.id == id);
          await copy.delete();
          rethrow;
        }
        _error = null;
        _scheduleExpiry();
        _notify();
      });

  Future<void> removeExpiredStories() => _enqueue(() async {
    _stories.removeWhere((story) => story.isExpired(_now()));
    _scheduleExpiry();
    _notify();
    try {
      await _persist();
      await _cleanUnusedMedia();
      _error = null;
    } catch (_) {
      _error = 'Could not clean up expired stories. Pull down to try again.';
    }
    _notify();
  });

  Future<void> _persist() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final bool saved = await prefs.setStringList(
      storageKey,
      _stories
          .where((story) => !story.isExpired(_now()))
          .map((story) => story.toJson())
          .toList(),
    );
    if (!saved) {
      throw StateError('Could not save stories');
    }
  }

  Future<void> _cleanUnusedMedia() async {
    final Directory directory = await _mediaDirectory();
    if (!await directory.exists()) {
      return;
    }
    final Set<String> activePaths = _stories.map((s) => s.media.path).toSet();
    // Only delete our copies; never delete media from the user's gallery.
    await for (final FileSystemEntity entry in directory.list()) {
      if (entry is File && !activePaths.contains(entry.path)) {
        try {
          await entry.delete();
        } on FileSystemException {
          // A playing video can be locked. Retry cleanup on the next refresh.
        }
      }
    }
  }

  void _scheduleExpiry() {
    _expiryTimer?.cancel();
    if (_disposed || _stories.isEmpty) {
      return;
    }
    final DateTime nextExpiry = _stories
        .map((s) => s.expiresAt)
        .reduce((a, b) => a.isBefore(b) ? a : b);
    final Duration remaining = nextExpiry.difference(_now());
    _expiryTimer = Timer(
      remaining.isNegative ? Duration.zero : remaining,
      () => unawaited(removeExpiredStories()),
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(removeExpiredStories());
    }
  }

  void _notify() {
    if (!_disposed) {
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _expiryTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
}
