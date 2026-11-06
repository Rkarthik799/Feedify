import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/post_provider.dart';
import '../theme/app_theme.dart';
import 'feed_identity.dart';

Future<void> showPostComments(BuildContext context, String postId) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.white,
    constraints: const BoxConstraints(maxWidth: 640),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    clipBehavior: Clip.antiAlias,
    builder: (context) => LayoutBuilder(
      builder: (context, constraints) {
        final inset = MediaQuery.viewInsetsOf(context).bottom;
        final height = math.max(
          0.0,
          math.min(680.0, constraints.maxHeight - inset),
        );
        final minimumHeight = MediaQuery.textScalerOf(context).scale(360);
        final sheet = CommentsSheet(postId: postId);
        return Padding(
          padding: EdgeInsets.only(bottom: inset),
          child: SizedBox(
            height: height,
            child: height < minimumHeight
                ? SingleChildScrollView(
                    child: SizedBox(height: minimumHeight, child: sheet),
                  )
                : sheet,
          ),
        );
      },
    ),
  );
}

class CommentsSheet extends StatefulWidget {
  const CommentsSheet({super.key, required this.postId});

  final String postId;

  @override
  State<CommentsSheet> createState() => _CommentsSheetState();
}

class _CommentsSheetState extends State<CommentsSheet> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  bool _isSubmitting = false;
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_isSubmitting || _controller.text.trim().isEmpty) return;
    setState(() {
      _isSubmitting = true;
      _error = null;
    });
    try {
      final saved = await context.read<PostProvider>().addComment(
        widget.postId,
        _controller.text,
      );
      if (!mounted) return;
      if (!saved) {
        setState(
          () => _error = 'Could not add your comment. Please try again.',
        );
        return;
      }
      _controller.clear();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOut,
          );
        }
      });
    } catch (_) {
      if (mounted) {
        setState(
          () => _error =
              'Could not save your comment. Your text is still here. Try again.',
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final posts = context.watch<PostProvider>().posts.where(
      (post) => post.id == widget.postId,
    );
    final comments = posts.isEmpty ? null : posts.first.comments;
    return SafeArea(
      top: false,
      child: Column(
        children: [
          const SizedBox(height: 10),
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.border,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 12, 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Comments (${comments?.length ?? 0})',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                IconButton(
                  tooltip: 'Close comments',
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: comments == null || comments.isEmpty
                ? SingleChildScrollView(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      children: [
                        const SizedBox(height: 36),
                        const CircleAvatar(
                          radius: 30,
                          backgroundColor: AppColors.tint,
                          child: Icon(
                            Icons.chat_bubble_outline_rounded,
                            color: AppColors.primary,
                            size: 28,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Start the conversation',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Share a thought or a little encouragement.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: AppColors.muted),
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(20),
                    itemCount: comments.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 20),
                    itemBuilder: (context, index) {
                      final comment = comments[index];
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const UserAvatar(radius: 17),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Wrap(
                                  spacing: 8,
                                  crossAxisAlignment: WrapCrossAlignment.center,
                                  children: [
                                    Text(
                                      comment.author,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    Text(
                                      formatPostTime(comment.createdAt),
                                      style: Theme.of(
                                        context,
                                      ).textTheme.bodySmall,
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                SelectableText(comment.content),
                              ],
                            ),
                          ),
                        ],
                      );
                    },
                  ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      _error!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: TextField(
                        key: const ValueKey('comment-input'),
                        controller: _controller,
                        enabled: !_isSubmitting && comments != null,
                        minLines: 1,
                        maxLines: 3,
                        maxLength: PostProvider.maxCommentLength,
                        textCapitalization: TextCapitalization.sentences,
                        textInputAction: TextInputAction.send,
                        onSubmitted: (_) => _submit(),
                        onChanged: (_) => setState(() => _error = null),
                        decoration: const InputDecoration(
                          hintText: 'Add a thoughtful comment...',
                          labelText: 'Your comment',
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    IconButton.filled(
                      key: const ValueKey('send-comment'),
                      tooltip: 'Post comment',
                      onPressed:
                          _isSubmitting ||
                              _controller.text.trim().isEmpty ||
                              comments == null
                          ? null
                          : _submit,
                      icon: _isSubmitting
                          ? const SizedBox.square(
                              dimension: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.arrow_upward_rounded),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
