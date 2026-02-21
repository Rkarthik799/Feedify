import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';

import '../models/post.dart';
import '../providers/post_provider.dart';
import '../widgets/media_preview_tile.dart';

class CreatePostScreen extends StatefulWidget {
  const CreatePostScreen({super.key});

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  static const List<String> _hashtags = <String>[
    '#flutter',
    '#coding',
    '#weekend',
    '#buildinpublic',
    '#mobiledev',
  ];

  static const List<String> _mentions = <String>[
    '@alex',
    '@sam',
    '@devteam',
    '@fluttercommunity',
  ];

  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    final PostProvider provider = context.read<PostProvider>();
    _controller = TextEditingController(text: provider.draftText);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.sizeOf(context).width;
    final double horizontalPadding = (screenWidth * 0.04).clamp(12, 20);
    final int mediaColumns = _mediaColumnCount(screenWidth);

    return Consumer<PostProvider>(
      builder: (BuildContext context, PostProvider provider, Widget? child) {
        return PopScope(
          canPop: !provider.hasUnsavedChanges,
          onPopInvokedWithResult: (bool didPop, Object? _) async {
            if (didPop || !provider.hasUnsavedChanges) {
              return;
            }

            final bool shouldDiscard = await _showDiscardDialog(context);
            if (!context.mounted || !shouldDiscard) {
              return;
            }

            provider.resetDraft();
            Navigator.of(context).pop();
          },
          child: Scaffold(
            extendBodyBehindAppBar: true,
            appBar: AppBar(
              title: const Text('Create Post'),
              flexibleSpace: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: <Color>[Color(0xFF00C2FF), Color(0xFF6A11CB)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              ),
              actions: <Widget>[
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFFFF6B00),
                      foregroundColor: Colors.white,
                    ),
                    onPressed: provider.canPost && !provider.isSubmitting
                        ? () => _submitPost(context)
                        : null,
                    child: provider.isSubmitting
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Post'),
                  ),
                ),
              ],
            ),
            body: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: <Color>[Color(0xFFF3F6FF), Color(0xFFEAF1FF)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: SafeArea(
                child: SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(
                    horizontalPadding,
                    12,
                    horizontalPadding,
                    24,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      _AnimatedEntry(
                        delayMs: 0,
                        child: _SectionCard(
                          title: 'Compose',
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Container(
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: LinearGradient(
                                    colors: <Color>[
                                      Color(0xFFFF7A18),
                                      Color(0xFFFF3D81),
                                    ],
                                  ),
                                ),
                                padding: const EdgeInsets.all(2),
                                child: const CircleAvatar(
                                  radius: 24,
                                  backgroundColor: Colors.white,
                                  child: Icon(Icons.person),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: TextField(
                                  controller: _controller,
                                  maxLines: null,
                                  minLines: 4,
                                  onChanged: provider.updateDraftText,
                                  decoration: InputDecoration(
                                    hintText: "What's on your mind?",
                                    filled: true,
                                    fillColor: Colors.grey.shade100,
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(14),
                                      borderSide: BorderSide.none,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Align(
                        alignment: Alignment.centerRight,
                        child: Text(
                          '${provider.draftText.length} chars',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      if (provider.isSubmitting &&
                          provider.draftMedia.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 10),
                          child: _UploadProgressCard(
                            uploadedCount: provider.uploadedCount,
                            totalCount: provider.draftMedia.length,
                            progress: provider.uploadProgress,
                          ),
                        ),
                      const SizedBox(height: 14),
                      _AnimatedEntry(
                        delayMs: 70,
                        child: _SectionCard(
                          title: 'Visibility',
                          child: DropdownButton<PostVisibility>(
                            value: provider.draftVisibility,
                            isExpanded: true,
                            underline: const SizedBox.shrink(),
                            items: const <DropdownMenuItem<PostVisibility>>[
                              DropdownMenuItem(
                                value: PostVisibility.public,
                                child: Text('Public'),
                              ),
                              DropdownMenuItem(
                                value: PostVisibility.friends,
                                child: Text('Friends'),
                              ),
                              DropdownMenuItem(
                                value: PostVisibility.onlyMe,
                                child: Text('Only Me'),
                              ),
                            ],
                            onChanged: (PostVisibility? value) {
                              if (value != null) {
                                provider.setDraftVisibility(value);
                              }
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      _AnimatedEntry(
                        delayMs: 140,
                        child: _SectionCard(
                          title: 'Add Media',
                          action: TextButton.icon(
                            onPressed: () => _onPickMedia(context),
                            icon: const Icon(Icons.photo_library_outlined),
                            label: const Text('Gallery'),
                          ),
                          child: AnimatedOpacity(
                            duration: const Duration(milliseconds: 280),
                            opacity: provider.draftMedia.isEmpty ? 0.35 : 1,
                            child: provider.draftMedia.isEmpty
                                ? Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(14),
                                      border: Border.all(
                                        color: Colors.grey.shade300,
                                      ),
                                    ),
                                    child: Text(
                                      'No media selected. Add image/video from gallery.',
                                      style: TextStyle(
                                        color: Colors.grey.shade700,
                                      ),
                                    ),
                                  )
                                : GridView.builder(
                                    shrinkWrap: true,
                                    physics:
                                        const NeverScrollableScrollPhysics(),
                                    itemCount: provider.draftMedia.length,
                                    gridDelegate:
                                        SliverGridDelegateWithFixedCrossAxisCount(
                                          crossAxisCount: mediaColumns,
                                          mainAxisSpacing: 8,
                                          crossAxisSpacing: 8,
                                        ),
                                    itemBuilder: (_, int index) {
                                      return MediaPreviewTile(
                                        media: provider.draftMedia[index],
                                        onRemove: () =>
                                            provider.removeDraftMediaAt(index),
                                      );
                                    },
                                  ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      _AnimatedEntry(
                        delayMs: 210,
                        child: _SectionCard(
                          title: 'Hashtag Suggestions',
                          child: _SuggestionWrap(
                            suggestions: _hashtags,
                            onSelected: (String value) =>
                                _insertSuggestion(provider, value),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      _AnimatedEntry(
                        delayMs: 280,
                        child: _SectionCard(
                          title: 'Mention Suggestions',
                          child: _SuggestionWrap(
                            suggestions: _mentions,
                            onSelected: (String value) =>
                                _insertSuggestion(provider, value),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
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

  void _insertSuggestion(PostProvider provider, String suggestion) {
    final String text = _controller.text.trimRight();
    final String appended = text.isEmpty ? suggestion : '$text $suggestion';
    _controller
      ..text = appended
      ..selection = TextSelection.fromPosition(
        TextPosition(offset: appended.length),
      );
    provider.updateDraftText(appended);
  }

  Future<void> _submitPost(BuildContext context) async {
    final PostProvider provider = context.read<PostProvider>();
    final bool success = await provider.submitPost();

    if (!context.mounted || !success) {
      return;
    }

    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
      return;
    }

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Posted locally.')));
  }

  Future<void> _onPickMedia(BuildContext context) async {
    final PostProvider provider = context.read<PostProvider>();
    final MediaPickStatus status = await provider.pickDraftMedia();
    if (!context.mounted) {
      return;
    }

    switch (status) {
      case MediaPickStatus.success:
      case MediaPickStatus.cancelled:
        return;
      case MediaPickStatus.permissionDenied:
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please allow gallery permissions to select media.'),
          ),
        );
      case MediaPickStatus.permissionPermanentlyDenied:
        final bool openSettings = await _showPermissionDialog(context);
        if (openSettings) {
          await openAppSettings();
        }
    }
  }

  Future<bool> _showDiscardDialog(BuildContext context) async {
    final bool? decision = await showDialog<bool>(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: const Text('Discard this post?'),
          content: const Text('You have unsaved changes in this draft.'),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Keep Editing'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Discard'),
            ),
          ],
        );
      },
    );

    return decision ?? false;
  }

  Future<bool> _showPermissionDialog(BuildContext context) async {
    final bool? decision = await showDialog<bool>(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: const Text('Permission required'),
          content: const Text(
            'Gallery access is permanently denied. Open app settings to allow photos and videos.',
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Not now'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Open settings'),
            ),
          ],
        );
      },
    );
    return decision ?? false;
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.child, this.action});

  final String title;
  final Widget child;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFC7D7FF)),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Color(0x1A3B2A9F),
            blurRadius: 16,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                ),
                if (action case final Widget actionWidget) actionWidget,
              ],
            ),
            const SizedBox(height: 10),
            child,
          ],
        ),
      ),
    );
  }
}

class _SuggestionWrap extends StatelessWidget {
  const _SuggestionWrap({required this.suggestions, required this.onSelected});

  final List<String> suggestions;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: suggestions.map((String item) {
        return TweenAnimationBuilder<double>(
          duration: const Duration(milliseconds: 260),
          tween: Tween<double>(begin: 0.92, end: 1),
          builder: (BuildContext context, double value, Widget? child) {
            return Transform.scale(scale: value, child: child);
          },
          child: ActionChip(
            label: Text(item),
            backgroundColor: const Color(0xFFE1EDFF),
            side: const BorderSide(color: Color(0xFFAEC7FF)),
            onPressed: () => onSelected(item),
          ),
        );
      }).toList(),
    );
  }
}

class _UploadProgressCard extends StatelessWidget {
  const _UploadProgressCard({
    required this.uploadedCount,
    required this.totalCount,
    required this.progress,
  });

  final int uploadedCount;
  final int totalCount;
  final double progress;

  @override
  Widget build(BuildContext context) {
    final int safeUploaded = uploadedCount.clamp(0, totalCount);
    final int percent = (progress * 100).clamp(0, 100).round();
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: <Color>[Color(0xFFFF7A18), Color(0xFFFF3D81)],
        ),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                const Icon(Icons.cloud_upload_rounded, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Uploading media... $safeUploaded/$totalCount',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Text(
                  '$percent%',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: progress.clamp(0, 1),
                minHeight: 8,
                backgroundColor: const Color(0x66FFFFFF),
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AnimatedEntry extends StatelessWidget {
  const _AnimatedEntry({required this.delayMs, required this.child});

  final int delayMs;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 420 + delayMs),
      tween: Tween<double>(begin: 0, end: 1),
      curve: Curves.easeOutCubic,
      builder: (BuildContext context, double value, Widget? child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 12 * (1 - value)),
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}
