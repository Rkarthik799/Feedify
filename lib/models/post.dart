import 'dart:convert';

enum PostVisibility { public, friends, onlyMe }

enum PostMediaType { image, video }

enum PostMediaSource { file, asset }

class PostMedia {
  const PostMedia({
    required this.path,
    required this.type,
    this.source = PostMediaSource.file,
  });

  final String path;
  final PostMediaType type;
  final PostMediaSource source;

  Map<String, dynamic> toMap() {
    return {'path': path, 'type': type.name, 'source': source.name};
  }

  factory PostMedia.fromMap(Map<String, dynamic> map) {
    final String path = map['path'] as String;
    final String? rawSource = map['source'] as String?;
    return PostMedia(
      path: path,
      type: PostMediaType.values.firstWhere(
        (value) => value.name == map['type'],
        orElse: () => PostMediaType.image,
      ),
      source: rawSource == null
          ? (path.startsWith('assets/')
                ? PostMediaSource.asset
                : PostMediaSource.file)
          : PostMediaSource.values.firstWhere(
              (value) => value.name == rawSource,
              orElse: () => PostMediaSource.file,
            ),
    );
  }
}

class Post {
  const Post({
    required this.id,
    required this.content,
    required this.media,
    required this.visibility,
    required this.createdAt,
    required this.hashtags,
    required this.mentions,
    this.isLiked = false,
    this.commentCount = 0,
  });

  final String id;
  final String content;
  final List<PostMedia> media;
  final PostVisibility visibility;
  final DateTime createdAt;
  final List<String> hashtags;
  final List<String> mentions;
  final bool isLiked;
  final int commentCount;

  bool get hasContent => content.trim().isNotEmpty || media.isNotEmpty;

  Post copyWith({
    String? id,
    String? content,
    List<PostMedia>? media,
    PostVisibility? visibility,
    DateTime? createdAt,
    List<String>? hashtags,
    List<String>? mentions,
    bool? isLiked,
    int? commentCount,
  }) {
    return Post(
      id: id ?? this.id,
      content: content ?? this.content,
      media: media ?? this.media,
      visibility: visibility ?? this.visibility,
      createdAt: createdAt ?? this.createdAt,
      hashtags: hashtags ?? this.hashtags,
      mentions: mentions ?? this.mentions,
      isLiked: isLiked ?? this.isLiked,
      commentCount: commentCount ?? this.commentCount,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'content': content,
      'media': media.map((item) => item.toMap()).toList(),
      'visibility': visibility.name,
      'createdAt': createdAt.toIso8601String(),
      'hashtags': hashtags,
      'mentions': mentions,
      'isLiked': isLiked,
      'commentCount': commentCount,
    };
  }

  factory Post.fromMap(Map<String, dynamic> map) {
    return Post(
      id: map['id'] as String,
      content: map['content'] as String,
      media: (map['media'] as List<dynamic>)
          .map((item) => PostMedia.fromMap(item as Map<String, dynamic>))
          .toList(),
      visibility: PostVisibility.values.firstWhere(
        (value) => value.name == map['visibility'],
        orElse: () => PostVisibility.public,
      ),
      createdAt: DateTime.parse(map['createdAt'] as String),
      hashtags: List<String>.from(map['hashtags'] as List<dynamic>),
      mentions: List<String>.from(map['mentions'] as List<dynamic>),
      isLiked: map['isLiked'] as bool? ?? false,
      commentCount: map['commentCount'] as int? ?? 0,
    );
  }

  String toJson() => jsonEncode(toMap());

  factory Post.fromJson(String source) =>
      Post.fromMap(jsonDecode(source) as Map<String, dynamic>);
}
