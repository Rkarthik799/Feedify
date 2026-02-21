import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../models/post.dart';

enum MediaPickStatus {
  success,
  cancelled,
  permissionDenied,
  permissionPermanentlyDenied,
}

class PostProvider extends ChangeNotifier {
  static const String _storageKey = 'local_user_posts';
  static const String _legacyStorageKey = 'local_posts';

  final ImagePicker _picker = ImagePicker();
  final Uuid _uuid = const Uuid();

  late final List<Post> _staticPosts = _buildStaticPosts();
  List<Post> _userPosts = <Post>[];
  final List<PostMedia> _draftMedia = <PostMedia>[];
  String _draftText = '';
  PostVisibility _draftVisibility = PostVisibility.public;
  bool _isLoading = false;
  bool _isSubmitting = false;
  double _uploadProgress = 0;
  int _uploadedCount = 0;

  List<Post> get posts {
    final List<Post> merged = <Post>[..._userPosts, ..._staticPosts];
    merged.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return List<Post>.unmodifiable(merged);
  }

  List<PostMedia> get draftMedia => List<PostMedia>.unmodifiable(_draftMedia);
  String get draftText => _draftText;
  PostVisibility get draftVisibility => _draftVisibility;
  bool get isLoading => _isLoading;
  bool get isSubmitting => _isSubmitting;
  double get uploadProgress => _uploadProgress;
  int get uploadedCount => _uploadedCount;
  bool get canPost => _draftText.trim().isNotEmpty || _draftMedia.isNotEmpty;
  bool get hasUnsavedChanges =>
      canPost || _draftVisibility != PostVisibility.public;

  Future<void> initialize() async {
    if (_isLoading) {
      return;
    }

    _isLoading = true;
    notifyListeners();

    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final List<String> serializedPosts =
        prefs.getStringList(_storageKey) ?? <String>[];
    bool didSanitize = false;

    if (serializedPosts.isNotEmpty) {
      _userPosts = serializedPosts
          .map(Post.fromJson)
          .where(_isUserGeneratedPost)
          .toList();
      didSanitize = _userPosts.length != serializedPosts.length;
    } else {
      final List<String> legacyPosts =
          prefs.getStringList(_legacyStorageKey) ?? <String>[];
      if (legacyPosts.isNotEmpty) {
        _userPosts = legacyPosts
            .map(Post.fromJson)
            .where(_isUserGeneratedPost)
            .toList();
        didSanitize = true;
      }
    }
    if (didSanitize) {
      await _persistPosts();
    }

    _isLoading = false;
    notifyListeners();
  }

  void updateDraftText(String value) {
    _draftText = value;
    notifyListeners();
  }

  void setDraftVisibility(PostVisibility value) {
    _draftVisibility = value;
    notifyListeners();
  }

  Future<MediaPickStatus> pickDraftMedia() async {
    final MediaPickStatus permissionStatus = await _ensureMediaPermission();
    if (permissionStatus != MediaPickStatus.success) {
      return permissionStatus;
    }

    final List<XFile> picked = await _picker.pickMultipleMedia(
      imageQuality: 85,
      requestFullMetadata: false,
    );

    if (picked.isEmpty) {
      return MediaPickStatus.cancelled;
    }

    for (final XFile file in picked) {
      final String mime = file.mimeType ?? '';
      final bool isVideo =
          mime.startsWith('video/') ||
          _hasVideoExtension(file.path.toLowerCase());

      _draftMedia.add(
        PostMedia(
          path: file.path,
          type: isVideo ? PostMediaType.video : PostMediaType.image,
        ),
      );
    }

    notifyListeners();
    return MediaPickStatus.success;
  }

  void removeDraftMediaAt(int index) {
    if (index < 0 || index >= _draftMedia.length) {
      return;
    }

    _draftMedia.removeAt(index);
    notifyListeners();
  }

  Future<bool> submitPost() async {
    if (!canPost || _isSubmitting) {
      return false;
    }

    _isSubmitting = true;
    _uploadProgress = _draftMedia.isEmpty ? 1 : 0;
    _uploadedCount = 0;
    notifyListeners();

    if (_draftMedia.isNotEmpty) {
      await _simulateUpload();
    }

    final String trimmedText = _draftText.trim();
    final List<String> hashtags = _extractTokens(trimmedText, '#');
    final List<String> mentions = _extractTokens(trimmedText, '@');

    final Post post = Post(
      id: _uuid.v4(),
      content: trimmedText,
      media: List<PostMedia>.from(_draftMedia),
      visibility: _draftVisibility,
      createdAt: DateTime.now(),
      hashtags: hashtags,
      mentions: mentions,
    );

    _userPosts.insert(0, post);
    await _persistPosts();
    resetDraft();

    _isSubmitting = false;
    _uploadProgress = 0;
    _uploadedCount = 0;
    notifyListeners();
    return true;
  }

  void resetDraft() {
    _draftText = '';
    _draftMedia.clear();
    _draftVisibility = PostVisibility.public;
    notifyListeners();
  }

  Future<void> _simulateUpload() async {
    final int total = _draftMedia.length;
    for (int index = 0; index < total; index++) {
      final int delayMs = 260 + math.Random().nextInt(320);
      await Future<void>.delayed(Duration(milliseconds: delayMs));
      _uploadedCount = index + 1;
      _uploadProgress = _uploadedCount / total;
      notifyListeners();
    }
  }

  Future<void> toggleLike(String postId) async {
    bool updatedUserPost = false;
    final int userIndex = _userPosts.indexWhere((item) => item.id == postId);
    if (userIndex != -1) {
      final Post current = _userPosts[userIndex];
      _userPosts[userIndex] = current.copyWith(isLiked: !current.isLiked);
      updatedUserPost = true;
    } else {
      final int staticIndex = _staticPosts.indexWhere(
        (item) => item.id == postId,
      );
      if (staticIndex == -1) {
        return;
      }
      final Post current = _staticPosts[staticIndex];
      _staticPosts[staticIndex] = current.copyWith(isLiked: !current.isLiked);
    }
    notifyListeners();
    if (updatedUserPost) {
      await _persistPosts();
    }
  }

  Future<void> addComment(String postId) async {
    bool updatedUserPost = false;
    final int userIndex = _userPosts.indexWhere((item) => item.id == postId);
    if (userIndex != -1) {
      final Post current = _userPosts[userIndex];
      _userPosts[userIndex] = current.copyWith(
        commentCount: current.commentCount + 1,
      );
      updatedUserPost = true;
    } else {
      final int staticIndex = _staticPosts.indexWhere(
        (item) => item.id == postId,
      );
      if (staticIndex == -1) {
        return;
      }
      final Post current = _staticPosts[staticIndex];
      _staticPosts[staticIndex] = current.copyWith(
        commentCount: current.commentCount + 1,
      );
    }
    notifyListeners();
    if (updatedUserPost) {
      await _persistPosts();
    }
  }

  Future<void> _persistPosts() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final List<String> serialized = _userPosts
        .map((item) => item.toJson())
        .toList();
    await prefs.setStringList(_storageKey, serialized);
  }

  List<String> _extractTokens(String text, String prefix) {
    return text
        .split(RegExp(r'\s+'))
        .where((word) => word.startsWith(prefix) && word.length > 1)
        .map((word) => word.replaceAll(RegExp(r'[^a-zA-Z0-9_#@]'), ''))
        .where((word) => word.length > 1)
        .toSet()
        .toList();
  }

  bool _hasVideoExtension(String path) {
    const List<String> videoExtensions = <String>[
      '.mp4',
      '.mov',
      '.m4v',
      '.avi',
      '.mkv',
      '.webm',
      '.3gp',
    ];
    return videoExtensions.any(path.endsWith);
  }

  Future<MediaPickStatus> _ensureMediaPermission() async {
    if (!Platform.isAndroid && !Platform.isIOS) {
      return MediaPickStatus.success;
    }

    final bool hasAccess = await _requestPhotosAndVideosPermission();
    if (hasAccess) {
      return MediaPickStatus.success;
    }

    if (Platform.isAndroid) {
      final PermissionStatus storageStatus = await Permission.storage.request();
      if (storageStatus.isGranted || storageStatus.isLimited) {
        return MediaPickStatus.success;
      }
      if (storageStatus.isPermanentlyDenied) {
        return MediaPickStatus.permissionPermanentlyDenied;
      }
    }

    final PermissionStatus photoStatus = await Permission.photos.status;
    final PermissionStatus videoStatus = await Permission.videos.status;
    if (photoStatus.isPermanentlyDenied || videoStatus.isPermanentlyDenied) {
      return MediaPickStatus.permissionPermanentlyDenied;
    }

    return MediaPickStatus.permissionDenied;
  }

  Future<bool> _requestPhotosAndVideosPermission() async {
    final Map<Permission, PermissionStatus> statuses = await <Permission>[
      Permission.photos,
      Permission.videos,
    ].request();
    final PermissionStatus photoStatus =
        statuses[Permission.photos] ?? PermissionStatus.denied;
    final PermissionStatus videoStatus =
        statuses[Permission.videos] ?? PermissionStatus.denied;

    return photoStatus.isGranted ||
        photoStatus.isLimited ||
        videoStatus.isGranted ||
        videoStatus.isLimited;
  }

  List<Post> _buildStaticPosts() {
    final DateTime now = DateTime.now();
    const List<String> mediaPaths = <String>[
      'assets/images/feed_1.jpg',
      'assets/images/feed_2.jpg',
      'assets/images/feed_3.jpg',
      'assets/images/feed_4.jpg',
      'assets/images/feed_5.jpg',
      'assets/images/feed_6.jpg',
      'assets/images/feed_7.jpg',
      'assets/images/feed_8.jpg',
      'assets/images/feed_9.jpg',
      'assets/images/feed_10.jpg',
      'assets/images/feed_11.jpg',
      'assets/images/feed_12.jpg',
      'assets/images/feed_13.jpg',
      'assets/images/feed_14.mp4',
      'assets/images/feed_15.mp4',
    ];

    const List<String> captions = <String>[
      'Morning run and coffee. #weekend #health',
      'Workspace setup before coding session. @devteam #flutter',
      'Street vibes and quick snapshots. #daily',
      'Building all day, shipping at night. #buildinpublic',
      'Short break, long scroll. #social',
      'Captured this one on the way home. #citylife',
      'New design moodboard update. #ui #mobiledev',
      'Small wins today. #progress',
      'Weekend plans are loading... #weekend',
      'Team sync + ideas dump. @alex @sam #collab',
      'Trying a different angle today. #photography',
      'Focus mode. Notifications off. #deepwork',
      'Throwback frame from last month. #memories',
      'Another upload from the camera roll. #random',
      'Keeping this one simple. #minimal',
      'Threads, posts, and late-night thoughts. #socialmedia',
    ];

    final List<PostVisibility> visibilityCycle = <PostVisibility>[
      PostVisibility.public,
      PostVisibility.friends,
      PostVisibility.onlyMe,
      PostVisibility.public,
    ];

    return List<Post>.generate(captions.length, (int index) {
      final String primaryAsset = mediaPaths[index % mediaPaths.length];
      final List<PostMedia> media = <PostMedia>[_buildAssetMedia(primaryAsset)];

      if (index % 4 == 1) {
        final String secondAsset = mediaPaths[(index + 1) % mediaPaths.length];
        media.add(_buildAssetMedia(secondAsset));
      }

      final String caption = captions[index];
      return Post(
        id: 'static-${index + 1}',
        content: caption,
        media: media,
        visibility: visibilityCycle[index % visibilityCycle.length],
        createdAt: now.subtract(Duration(hours: index * 3 + 1)),
        hashtags: _extractTokens(caption, '#'),
        mentions: _extractTokens(caption, '@'),
      );
    });
  }

  PostMedia _buildAssetMedia(String path) {
    final bool isVideo = _hasVideoExtension(path.toLowerCase());
    return PostMedia(
      path: path,
      type: isVideo ? PostMediaType.video : PostMediaType.image,
      source: PostMediaSource.asset,
    );
  }

  bool _isUserGeneratedPost(Post post) {
    if (post.id.startsWith('static-')) {
      return false;
    }
    if (post.media.isEmpty) {
      return true;
    }
    return post.media.any((media) => !media.path.startsWith('assets/'));
  }
}
