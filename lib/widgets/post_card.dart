import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/post.dart';
import '../providers/post_provider.dart';
import 'media_preview_tile.dart';

class PostCard extends StatelessWidget {
  const PostCard({super.key, required this.post, this.index = 0});

  final Post post;
  final int index;

  @override
  Widget build(BuildContext context) {
    final PostProvider provider = context.read<PostProvider>();
    final double screenWidth = MediaQuery.sizeOf(context).width;
    final int mediaColumns = _mediaColumnCount(screenWidth);

    return TweenAnimationBuilder<double>(
      key: ValueKey<String>('post-${post.id}'),
      duration: Duration(milliseconds: 260 + (index * 45).clamp(0, 360)),
      tween: Tween<double>(begin: 0, end: 1),
      curve: Curves.easeOutCubic,
      builder: (BuildContext context, double value, Widget? child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 16 * (1 - value)),
            child: child,
          ),
        );
      },
      child: Card(
        elevation: 0,
        margin: EdgeInsets.symmetric(
          horizontal: (screenWidth * 0.035).clamp(8, 16),
          vertical: 8,
        ),
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(color: Colors.grey.shade200),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Container(
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: <Color>[Color(0xFFFF7A18), Color(0xFFFF3D81)],
                      ),
                    ),
                    padding: const EdgeInsets.all(2),
                    child: const CircleAvatar(
                      radius: 18,
                      backgroundColor: Colors.white,
                      child: Icon(Icons.person),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        const Text(
                          'You',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                        Text(
                          _formatPostTime(post.createdAt),
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _VisibilityBadge(visibility: post.visibility),
                ],
              ),
              if (post.content.isNotEmpty) ...<Widget>[
                const SizedBox(height: 12),
                Text(
                  post.content,
                  style: const TextStyle(fontSize: 15, height: 1.4),
                ),
              ],
              if (post.media.isNotEmpty) ...<Widget>[
                const SizedBox(height: 12),
                GridView.builder(
                  physics: const NeverScrollableScrollPhysics(),
                  shrinkWrap: true,
                  itemCount: post.media.length,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: mediaColumns,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                  ),
                  itemBuilder: (_, int mediaIndex) {
                    return MediaPreviewTile(media: post.media[mediaIndex]);
                  },
                ),
              ],
              const SizedBox(height: 8),
              Divider(color: Colors.grey.shade200, height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: <Widget>[
                  _ActionPill(
                    label: post.isLiked ? 'Liked' : 'Like',
                    icon: post.isLiked ? Icons.favorite : Icons.favorite_border,
                    iconColor: post.isLiked ? Colors.red : Colors.grey.shade700,
                    onTap: () => provider.toggleLike(post.id),
                  ),
                  _ActionPill(
                    label: 'Comment (${post.commentCount})',
                    icon: Icons.mode_comment_outlined,
                    iconColor: Colors.grey.shade700,
                    onTap: () => provider.addComment(post.id),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatPostTime(DateTime dateTime) {
    final Duration diff = DateTime.now().difference(dateTime);

    if (diff.inSeconds < 10) {
      return 'Just now';
    }
    if (diff.inMinutes < 1) {
      return '${diff.inSeconds}s ago';
    }
    if (diff.inHours < 1) {
      return '${diff.inMinutes}m ago';
    }
    if (diff.inDays < 1) {
      return '${diff.inHours}h ago';
    }

    return DateFormat('MMM d, h:mm a').format(dateTime);
  }

  int _mediaColumnCount(double width) {
    if (width < 360) {
      return 2;
    }
    if (width < 700) {
      return 3;
    }
    return 4;
  }
}

class _ActionPill extends StatelessWidget {
  const _ActionPill({
    required this.label,
    required this.icon,
    required this.iconColor,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final Color iconColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFE1EDFF),
      borderRadius: BorderRadius.circular(26),
      child: InkWell(
        borderRadius: BorderRadius.circular(26),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(icon, size: 18, color: iconColor),
              const SizedBox(width: 6),
              Text(label),
            ],
          ),
        ),
      ),
    );
  }
}

class _VisibilityBadge extends StatelessWidget {
  const _VisibilityBadge({required this.visibility});

  final PostVisibility visibility;

  @override
  Widget build(BuildContext context) {
    IconData icon;
    String text;
    Color bg;

    switch (visibility) {
      case PostVisibility.public:
        icon = Icons.public;
        text = 'Public';
        bg = const Color(0xFFD9FFF1);
      case PostVisibility.friends:
        icon = Icons.group;
        text = 'Friends';
        bg = const Color(0xFFDCE7FF);
      case PostVisibility.onlyMe:
        icon = Icons.lock;
        text = 'Only Me';
        bg = const Color(0xFFFFE7D6);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 14),
          const SizedBox(width: 4),
          Text(
            text,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
