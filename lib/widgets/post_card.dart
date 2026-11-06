import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/post.dart';
import '../providers/post_provider.dart';
import '../theme/app_theme.dart';
import 'comments_sheet.dart';
import 'feed_identity.dart';
import 'media_preview_tile.dart';

class PostCard extends StatelessWidget {
  const PostCard({super.key, required this.post, this.index = 0});

  final Post post;
  final int index;

  @override
  Widget build(BuildContext context) {
    final provider = context.read<PostProvider>();
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const UserAvatar(),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'You',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
                      Text(
                        formatPostTime(post.createdAt),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                Tooltip(
                  message: post.visibility.label,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          post.visibility.icon,
                          size: 14,
                          color: AppColors.muted,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          post.visibility.label,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            if (post.content.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text.rich(
                TextSpan(children: _contentSpans(post.content)),
                style: const TextStyle(fontSize: 15, height: 1.65),
              ),
            ],
            if (post.media.isNotEmpty) ...[
              const SizedBox(height: 16),
              LayoutBuilder(
                builder: (context, constraints) {
                  final columns = post.media.length == 1
                      ? 1
                      : (constraints.maxWidth < 350
                            ? 2
                            : post.media.length.clamp(2, 3));
                  return GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: post.media.length,
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: columns,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                      childAspectRatio: post.media.length == 1 ? 1.3 : 1,
                    ),
                    itemBuilder: (_, index) => MediaPreviewTile(
                      media: post.media[index],
                      aspectRatio: post.media.length == 1 ? 1.3 : 1,
                    ),
                  );
                },
              ),
            ],
            const SizedBox(height: 14),
            Wrap(
              spacing: 12,
              children: [
                Text(
                  post.isLiked ? '1 like' : 'Be the first to like this',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                Text(
                  '${post.commentCount} ${post.commentCount == 1 ? 'comment' : 'comments'}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
            const Divider(height: 24),
            Row(
              children: [
                Expanded(
                  child: TextButton.icon(
                    onPressed: () => provider.toggleLike(post.id),
                    style: TextButton.styleFrom(
                      foregroundColor: post.isLiked
                          ? const Color(0xFFCB4B65)
                          : AppColors.muted,
                      minimumSize: const Size(0, 44),
                    ),
                    icon: Icon(
                      post.isLiked
                          ? Icons.favorite_rounded
                          : Icons.favorite_border_rounded,
                      size: 20,
                    ),
                    label: Text(post.isLiked ? 'Liked' : 'Like'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextButton.icon(
                    onPressed: () => showPostComments(context, post.id),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.muted,
                      minimumSize: const Size(0, 44),
                    ),
                    icon: const Icon(
                      Icons.chat_bubble_outline_rounded,
                      size: 19,
                    ),
                    label: const Text('Comment'),
                  ),
                ),
              ],
            ),
            if (post.comments.isNotEmpty) ...[
              const SizedBox(height: 8),
              InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () => showPostComments(context, post.id),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: '${post.comments.last.author}  ',
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        TextSpan(text: post.comments.last.content),
                      ],
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  List<TextSpan> _contentSpans(String content) {
    final spans = <TextSpan>[];
    final pattern = RegExp(r'[#@][a-zA-Z0-9_]+');
    var end = 0;
    for (final match in pattern.allMatches(content)) {
      if (match.start > end) {
        spans.add(TextSpan(text: content.substring(end, match.start)));
      }
      spans.add(
        TextSpan(
          text: match.group(0),
          style: const TextStyle(
            color: AppColors.primary,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
      end = match.end;
    }
    if (end < content.length) spans.add(TextSpan(text: content.substring(end)));
    return spans;
  }
}
