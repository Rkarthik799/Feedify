import 'dart:convert';

import 'post.dart';

class Story {
  const Story({
    required this.id,
    required this.media,
    required this.createdAt,
    this.caption = '',
  });

  static const Duration lifetime = Duration(hours: 24);

  final String id;
  final PostMedia media;
  final DateTime createdAt;
  final String caption;

  DateTime get expiresAt => createdAt.add(lifetime);

  bool isExpired(DateTime now) => !now.isBefore(expiresAt);

  String toJson() => jsonEncode(<String, dynamic>{
    'id': id,
    'media': media.toMap(),
    'createdAt': createdAt.toUtc().toIso8601String(),
    'caption': caption,
  });

  factory Story.fromJson(String source) {
    final Map<String, dynamic> map = jsonDecode(source) as Map<String, dynamic>;
    return Story(
      id: map['id'] as String,
      media: PostMedia.fromMap(map['media'] as Map<String, dynamic>),
      createdAt: DateTime.parse(map['createdAt'] as String).toUtc(),
      caption: map['caption'] as String? ?? '',
    );
  }
}
