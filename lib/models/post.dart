import 'dart:convert';

enum PostVisibility { public, friends, onlyMe }

enum PostMediaType { image, video }

enum PostMediaSource { file, asset }

class PostComment {
  const PostComment({
    required this.id,
    required this.content,
    required this.createdAt,
    this.author = 'You',
  });

  final String id;
  final String content;
  final DateTime createdAt;
  final String author;

  Map<String, dynamic> toMap() => {
    'id': id,
    'content': content,
    'createdAt': createdAt.toIso8601String(),
    'author': author,
  };

  factory PostComment.fromMap(Map<String, dynamic> map) => PostComment(
    id: map['id'] as String,
    content: map['content'] as String,
    createdAt: DateTime.parse(map['createdAt'] as String),
    author: map['author'] as String? ?? 'You',
  );
}

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
    this.comments = const <PostComment>[],
  });

  final String id;
  final String content;
  final List<PostMedia> media;
  final PostVisibility visibility;
  final DateTime createdAt;
  final List<String> hashtags;
  final List<String> mentions;
  final bool isLiked;
  final List<PostComment> comments;

  int get commentCount => comments.length;

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
    List<PostComment>? comments,
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
      comments: comments ?? this.comments,
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
      'comments': comments.map((comment) => comment.toMap()).toList(),
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
      comments: List<PostComment>.unmodifiable(
        (map['comments'] as List<dynamic>? ?? <dynamic>[]).map(
          (item) => PostComment.fromMap(item as Map<String, dynamic>),
        ),
      ),
    );
  }

  String toJson() => jsonEncode(toMap());

  factory Post.fromJson(String source) =>
      Post.fromMap(jsonDecode(source) as Map<String, dynamic>);
}
