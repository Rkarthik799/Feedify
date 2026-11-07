import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';

import '../models/post.dart';
import '../providers/post_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/feed_identity.dart';
import '../widgets/media_preview_tile.dart';

class CreatePostScreen extends StatefulWidget {
  const CreatePostScreen({super.key});

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  static const _hashtags = [
    '#flutter',
    '#coding',
    '#weekend',
    '#buildinpublic',
    '#mobiledev',
  ];
  static const _mentions = ['@alex', '@sam', '@devteam', '@fluttercommunity'];
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: context.read<PostProvider>().draftText,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PostProvider>();
    return PopScope(
      canPop: !provider.hasUnsavedChanges && !provider.isSubmitting,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop || provider.isSubmitting) return;
        final discard = await _showDiscardDialog();
        if (!context.mounted || !discard) return;
        provider.resetDraft();
        if (context.mounted) Navigator.pop(context);
      },
      child: Scaffold(
        appBar: AppBar(
          toolbarHeight: 72,
          title: const Text(
            'Create a post',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
          ),
          shape: const Border(bottom: BorderSide(color: AppColors.border)),
        ),
        body: SafeArea(
          top: false,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final wide = constraints.maxWidth >= 900;
              final editor = _buildEditor(provider);
              final settings = _buildSettings(provider);
              return Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1080),
                  child: SingleChildScrollView(
                    padding: EdgeInsets.all(
                      constraints.maxWidth < 600 ? 16 : 28,
                    ),
                    child: AbsorbPointer(
                      absorbing: provider.isSubmitting,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Something worth sharing.',
                            style: Theme.of(context).textTheme.headlineMedium,
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'A thought, a moment, a new perspective. Make it yours.',
                            style: TextStyle(color: AppColors.muted),
                          ),
                          const SizedBox(height: 24),
                          if (wide)
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(flex: 2, child: editor),
                                const SizedBox(width: 24),
                                Expanded(child: settings),
                              ],
                            )
                          else ...[
                            editor,
                            const SizedBox(height: 20),
                            settings,
                          ],
                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        bottomNavigationBar: SafeArea(
          top: false,
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: AppColors.border)),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Center(
              heightFactor: 1,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1024),
                child: Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Saved on this device',
                        style: TextStyle(color: AppColors.muted, fontSize: 12),
                      ),
                    ),
                    const SizedBox(width: 12),
                    FilledButton.icon(
                      onPressed: provider.canPost && !provider.isSubmitting
                          ? _submitPost
                          : null,
                      icon: provider.isSubmitting
                          ? const SizedBox.square(
                              dimension: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.arrow_upward_rounded, size: 18),
                      label: Text(
                        provider.isSubmitting
                            ? 'Publishing...'
                            : 'Publish post',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEditor(PostProvider provider) => Card(
    child: Padding(
      padding: const EdgeInsets.all(20),
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
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    Text(
                      'Sharing with ${provider.draftVisibility.label.toLowerCase()}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _controller,
            minLines: 6,
            maxLines: null,
            enabled: !provider.isSubmitting,
            textCapitalization: TextCapitalization.sentences,
            style: const TextStyle(fontSize: 17, height: 1.7),
            onChanged: provider.updateDraftText,
            decoration: const InputDecoration(
              hintText: "What's on your mind?",
              labelText: 'Post content',
              alignLabelWithHint: true,
            ),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              '${provider.draftText.length} characters',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
          const Divider(height: 32),
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 12,
            runSpacing: 8,
            children: [
              Text(
                'Photos & videos',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              TextButton.icon(
                onPressed: _pickMedia,
                icon: const Icon(Icons.add_photo_alternate_outlined, size: 20),
                label: const Text('Add media'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (provider.draftMedia.isEmpty)
            InkWell(
              onTap: _pickMedia,
              borderRadius: BorderRadius.circular(14),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 28,
                ),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  children: [
                    const Icon(
                      Icons.photo_library_outlined,
                      size: 30,
                      color: AppColors.primary,
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Bring your post to life',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Choose photos or videos from your gallery',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            )
          else
            LayoutBuilder(
              builder: (context, constraints) => GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: provider.draftMedia.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: constraints.maxWidth < 420 ? 2 : 3,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                ),
                itemBuilder: (_, index) => MediaPreviewTile(
                  media: provider.draftMedia[index],
                  onRemove: () => provider.removeDraftMediaAt(index),
                ),
              ),
            ),
          if (provider.isSubmitting && provider.draftMedia.isNotEmpty) ...[
            const SizedBox(height: 16),
            LinearProgressIndicator(
              value: provider.uploadProgress,
              borderRadius: BorderRadius.circular(8),
            ),
            const SizedBox(height: 8),
            Text(
              'Preparing media ${provider.uploadedCount}/${provider.draftMedia.length}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ],
      ),
    ),
  );

  Widget _buildSettings(PostProvider provider) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      _section(
        'Who can see this?',
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Choose an audience for this post.',
              style: TextStyle(color: AppColors.muted, fontSize: 13),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<PostVisibility>(
              initialValue: provider.draftVisibility,
              isExpanded: true,
              decoration: const InputDecoration(labelText: 'Audience'),
              items: [
                for (final visibility in PostVisibility.values)
                  DropdownMenuItem(
                    value: visibility,
                    child: Row(
                      children: [
                        Icon(visibility.icon, size: 18, color: AppColors.muted),
                        const SizedBox(width: 10),
                        Text(visibility.label),
                      ],
                    ),
                  ),
              ],
              onChanged: (value) {
                if (value != null) provider.setDraftVisibility(value);
              },
            ),
          ],
        ),
      ),
      const SizedBox(height: 20),
      _section(
        'Make it discoverable',
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Add a topic to your story.',
              style: TextStyle(color: AppColors.muted, fontSize: 13),
            ),
            const SizedBox(height: 12),
            _suggestions(_hashtags),
            const Divider(height: 32),
            Text(
              'Bring someone in',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 6),
            const Text(
              'Mention someone in your post.',
              style: TextStyle(color: AppColors.muted, fontSize: 13),
            ),
            const SizedBox(height: 12),
            _suggestions(_mentions),
          ],
        ),
      ),
    ],
  );

  Widget _section(String title, Widget child) => Card(
    child: Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          child,
        ],
      ),
    ),
  );

  Widget _suggestions(List<String> suggestions) => Wrap(
    spacing: 6,
    runSpacing: 8,
    children: [
      for (final suggestion in suggestions)
        ActionChip(
          label: Text(
            suggestion,
            style: const TextStyle(fontSize: 12, color: AppColors.primary),
          ),
          onPressed: () {
            final selection = _controller.selection;
            final text = _controller.text;
            final start = selection.isValid ? selection.start : text.length;
            final end = selection.isValid ? selection.end : text.length;
            final prefix = start > 0 && !RegExp(r'\s').hasMatch(text[start - 1])
                ? ' '
                : '';
            final insertion = '$prefix$suggestion ';
            final updated = text.replaceRange(start, end, insertion);
            _controller.value = TextEditingValue(
              text: updated,
              selection: TextSelection.collapsed(
                offset: start + insertion.length,
              ),
            );
            context.read<PostProvider>().updateDraftText(updated);
          },
        ),
    ],
  );

  Future<void> _submitPost() async {
    try {
      final success = await context.read<PostProvider>().submitPost();
      if (!mounted || !success) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Your post is ready. Thanks for sharing!'),
        ),
      );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Could not save your post. Your draft is still here. Please try again.',
            ),
          ),
        );
      }
    }
  }

  Future<void> _pickMedia() async {
    try {
      final status = await context.read<PostProvider>().pickDraftMedia();
      if (!mounted) return;
      switch (status) {
        case MediaPickStatus.success:
        case MediaPickStatus.cancelled:
          return;
        case MediaPickStatus.permissionDenied:
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Allow gallery access to choose photos and videos.',
              ),
            ),
          );
        case MediaPickStatus.permissionPermanentlyDenied:
          final openSettings = await showDialog<bool>(
            context: context,
            builder: (dialogContext) => AlertDialog(
              title: const Text('Allow gallery access'),
              content: const Text(
                'Open app settings to allow access to your photos and videos.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext, false),
                  child: const Text('Not now'),
                ),
                FilledButton(
                  onPressed: () => Navigator.pop(dialogContext, true),
                  child: const Text('Open settings'),
                ),
              ],
            ),
          );
          if (openSettings == true) await openAppSettings();
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not open the gallery. Please try again.'),
          ),
        );
      }
    }
  }

  Future<bool> _showDiscardDialog() async {
    return await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: const Text('Discard this post?'),
            content: const Text('Your draft has unsaved changes.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text('Keep editing'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                child: const Text('Discard'),
              ),
            ],
          ),
        ) ??
        false;
  }
}
