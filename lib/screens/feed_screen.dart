import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/post.dart';
import '../providers/post_provider.dart';
<<<<<<< HEAD
import '../providers/story_provider.dart';
=======
import '../theme/app_theme.dart';
import '../widgets/feed_identity.dart';
>>>>>>> feature/ui-change
import '../widgets/post_card.dart';
import '../widgets/story_tray.dart';
import 'create_post_screen.dart';

enum _FeedFilter { all, yours, liked }

class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key});

<<<<<<< HEAD
  Future<void> _reload(BuildContext context) async {
    await Future.wait<void>(<Future<void>>[
      context.read<PostProvider>().initialize(),
      context.read<StoryProvider>().initialize(),
    ]);
=======
  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();
  _FeedFilter _filter = _FeedFilter.all;
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _createPost() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => const CreatePostScreen()));
  }

  void _selectFilter(_FeedFilter filter) {
    setState(() => _filter = filter);
    if (_scrollController.hasClients) _scrollController.jumpTo(0);
  }

  void _searchTag(String tag) {
    _searchController.text = tag;
    setState(() {
      _query = tag;
      _filter = _FeedFilter.all;
    });
    if (_scrollController.hasClients) _scrollController.jumpTo(0);
>>>>>>> feature/ui-change
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PostProvider>();
    final allPosts = provider.posts;
    final posts = allPosts.where((post) {
      final matchesFilter = switch (_filter) {
        _FeedFilter.all => true,
        _FeedFilter.yours => !post.id.startsWith('static-'),
        _FeedFilter.liked => post.isLiked,
      };
      return matchesFilter &&
          post.content.toLowerCase().contains(_query.trim().toLowerCase());
    }).toList();
    final width = MediaQuery.sizeOf(context).width;
    final showSidebar = width >= 980;
    final showDiscover = width >= 1280;

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 76,
        titleSpacing: width < 600 ? 16 : 28,
        shape: const Border(bottom: BorderSide(color: AppColors.border)),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.dynamic_feed_rounded,
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(width: 10),
            const Flexible(
              child: Text(
                'feedify',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 25,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -1,
                ),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh feed',
            onPressed: provider.isLoading ? null : provider.initialize,
            icon: const Icon(Icons.refresh_rounded, color: AppColors.muted),
          ),
          const SizedBox(width: 6),
          if (width >= 520)
            FilledButton.icon(
              onPressed: _createPost,
              icon: const Icon(Icons.add_rounded, size: 20),
              label: const Text('New post'),
            )
          else
            IconButton.filled(
              tooltip: 'New post',
              onPressed: _createPost,
              icon: const Icon(Icons.add_rounded),
            ),
<<<<<<< HEAD
            child: RefreshIndicator(
              onRefresh: () => _reload(context),
              child: ListView.builder(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.only(top: 8, bottom: 92 + bottomInset),
                itemCount: provider.isLoading || provider.posts.isEmpty
                    ? 2
                    : provider.posts.length + 1,
                itemBuilder: (_, int index) {
                  if (index == 0) {
                    return const StoryTray();
                  }
                  if (provider.isLoading) {
                    return const Padding(
                      padding: EdgeInsets.all(32),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }
                  if (provider.posts.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.all(24),
                      child: Text(
                        'No posts yet. Create your first local post.',
                        textAlign: TextAlign.center,
                      ),
                    );
                  }
                  return PostCard(
                    post: provider.posts[index - 1],
                    index: index - 1,
                  );
                },
=======
          SizedBox(width: width < 600 ? 16 : 28),
        ],
      ),
      body: SafeArea(
        top: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1360),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: width < 600 ? 16 : 28),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (showSidebar) ...[
                    SizedBox(
                      width: 216,
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(vertical: 28),
                        child: _buildSidebar(provider),
                      ),
                    ),
                    const SizedBox(width: 28),
                  ],
                  Expanded(
                    child: Align(
                      alignment: Alignment.topCenter,
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 720),
                        child: RefreshIndicator(
                          onRefresh: provider.initialize,
                          child: CustomScrollView(
                            controller: _scrollController,
                            physics: const AlwaysScrollableScrollPhysics(),
                            slivers: [
                              SliverToBoxAdapter(
                                child: _buildFeedHeader(context, showSidebar),
                              ),
                              if (provider.loadError != null)
                                SliverToBoxAdapter(
                                  child: Padding(
                                    padding: const EdgeInsets.only(bottom: 16),
                                    child: Card(
                                      child: Padding(
                                        padding: const EdgeInsets.all(16),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(provider.loadError!),
                                            TextButton(
                                              onPressed: provider.initialize,
                                              child: const Text('Try again'),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              SliverToBoxAdapter(child: _buildComposer()),
                              SliverToBoxAdapter(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 18,
                                  ),
                                  child: Row(
                                    children: [
                                      const Expanded(child: Divider()),
                                      const SizedBox(width: 12),
                                      Text(
                                        _query.isNotEmpty
                                            ? '${posts.length} results'
                                            : 'Latest posts',
                                        style: Theme.of(
                                          context,
                                        ).textTheme.bodySmall,
                                      ),
                                      const SizedBox(width: 12),
                                      const Icon(
                                        Icons.sort_rounded,
                                        color: AppColors.muted,
                                        size: 16,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              if (provider.isLoading)
                                const SliverToBoxAdapter(
                                  child: Padding(
                                    padding: EdgeInsets.all(48),
                                    child: Center(
                                      child: CircularProgressIndicator(),
                                    ),
                                  ),
                                )
                              else if (posts.isEmpty)
                                SliverToBoxAdapter(child: _buildEmptyState())
                              else
                                SliverList.builder(
                                  itemCount: posts.length,
                                  itemBuilder: (_, index) => Padding(
                                    padding: const EdgeInsets.only(bottom: 18),
                                    child: PostCard(
                                      key: ValueKey(posts[index].id),
                                      post: posts[index],
                                      index: index,
                                    ),
                                  ),
                                ),
                              const SliverToBoxAdapter(
                                child: SizedBox(height: 28),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  if (showDiscover) ...[
                    const SizedBox(width: 28),
                    SizedBox(
                      width: 264,
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(vertical: 28),
                        child: _buildDiscover(allPosts),
                      ),
                    ),
                  ],
                ],
>>>>>>> feature/ui-change
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFeedHeader(BuildContext context, bool showSidebar) {
    return Padding(
      padding: const EdgeInsets.only(top: 28, bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(switch (_filter) {
            _FeedFilter.all => 'A fresh perspective.',
            _FeedFilter.yours => 'Your little corner.',
            _FeedFilter.liked => 'Worth another look.',
          }, style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 6),
          const Text(
            'Good moments. New ideas. Real conversations.',
            style: TextStyle(color: AppColors.muted),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _searchController,
            onChanged: (value) => setState(() => _query = value),
            decoration: InputDecoration(
              hintText: 'Search posts, hashtags, or mentions',
              prefixIcon: const Icon(
                Icons.search_rounded,
                color: AppColors.muted,
                size: 21,
              ),
              suffixIcon: _query.isEmpty
                  ? null
                  : IconButton(
                      tooltip: 'Clear search',
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _query = '');
                      },
                      icon: const Icon(Icons.close_rounded, size: 19),
                    ),
            ),
          ),
          if (!showSidebar) ...[
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final filter in _FeedFilter.values)
                  ChoiceChip(
                    label: Text(_filterLabel(filter)),
                    selected: _filter == filter,
                    onSelected: (_) => _selectFilter(filter),
                    showCheckmark: false,
                    labelStyle: TextStyle(
                      color: _filter == filter
                          ? AppColors.primary
                          : AppColors.muted,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildComposer() => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              const UserAvatar(),
              const SizedBox(width: 12),
              Expanded(
                child: InkWell(
                  onTap: _createPost,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      "What's on your mind?",
                      style: TextStyle(color: AppColors.muted),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            alignment: WrapAlignment.spaceBetween,
            children: [
              TextButton.icon(
                onPressed: _createPost,
                icon: const Icon(Icons.add_photo_alternate_outlined, size: 20),
                label: const Text('Photo / video'),
                style: TextButton.styleFrom(alignment: Alignment.centerLeft),
              ),
              TextButton(
                onPressed: _createPost,
                child: const Text('Share a moment'),
              ),
            ],
          ),
        ],
      ),
    ),
  );

  Widget _buildSidebar(PostProvider provider) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              const UserAvatar(radius: 30),
              const SizedBox(height: 12),
              Text(
                'Your space',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 4),
              const Text(
                'Make room for what matters.',
                style: TextStyle(color: AppColors.muted, fontSize: 12),
                textAlign: TextAlign.center,
              ),
              const Divider(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _stat(
                    '${provider.posts.where((post) => !post.id.startsWith('static-')).length}',
                    'Posts',
                  ),
                  _stat(
                    '${provider.posts.where((post) => post.isLiked).length}',
                    'Liked',
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      const SizedBox(height: 24),
      for (final filter in _FeedFilter.values)
        Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Material(
            color: _filter == filter ? AppColors.tint : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            child: ListTile(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              selected: _filter == filter,
              selectedColor: AppColors.primary,
              leading: Icon(switch (filter) {
                _FeedFilter.all => Icons.grid_view_rounded,
                _FeedFilter.yours => Icons.person_outline_rounded,
                _FeedFilter.liked => Icons.favorite_border_rounded,
              }, size: 21),
              title: Text(
                _filterLabel(filter),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              onTap: () => _selectFilter(filter),
            ),
          ),
        ),
      const SizedBox(height: 20),
      FilledButton.icon(
        onPressed: _createPost,
        icon: const Icon(Icons.edit_outlined, size: 18),
        label: const Text('Create a post'),
      ),
      const SizedBox(height: 24),
      const Padding(
        padding: EdgeInsets.symmetric(horizontal: 12),
        child: Text(
          'A little less noise.\nA little more connection.',
          style: TextStyle(color: AppColors.muted, fontSize: 12, height: 1.8),
        ),
      ),
    ],
  );

  Widget _stat(String value, String label) => Column(
    children: [
      Text(
        value,
        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 22),
      ),
      Text(label, style: Theme.of(context).textTheme.bodySmall),
    ],
  );

  Widget _buildDiscover(List<Post> posts) {
    final tags = <String, int>{};
    for (final post in posts) {
      for (final tag in post.hashtags) {
        tags.update(tag, (count) => count + 1, ifAbsent: () => 1);
      }
    }
    final sorted = tags.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.explore_outlined,
                      size: 21,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Explore topics',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                const Text(
                  'Find something that speaks to you.',
                  style: TextStyle(color: AppColors.muted, fontSize: 12),
                ),
                const SizedBox(height: 16),
                for (final tag in sorted.take(5))
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      tag.key,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    subtitle: Text(
                      '${tag.value} ${tag.value == 1 ? 'post' : 'posts'}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    trailing: const Icon(
                      Icons.north_east_rounded,
                      size: 16,
                      color: AppColors.muted,
                    ),
                    onTap: () => _searchTag(tag.key),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: AppColors.tint,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.auto_awesome_outlined,
                color: AppColors.primary,
                size: 26,
              ),
              const SizedBox(height: 14),
              Text(
                'Every moment has a story.',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 10),
              const Text(
                'A small win, a new idea, or a view worth sharing. Make it a post.',
                style: TextStyle(color: AppColors.muted),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: _createPost,
                child: const Text('Tell yours  →'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 8),
          child: Text(
            'Your posts and comments are saved on this device. Sample posts help you explore the feed.',
            style: TextStyle(color: AppColors.muted, fontSize: 12, height: 1.7),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() => Card(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          const Icon(Icons.forum_outlined, size: 40, color: AppColors.primary),
          const SizedBox(height: 16),
          Text(
            _query.isNotEmpty
                ? 'No matching posts'
                : _filter == _FeedFilter.liked
                ? 'Keep your favorites close'
                : 'Your story starts here',
            style: Theme.of(context).textTheme.titleMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            _query.isNotEmpty
                ? 'Try a different word or hashtag.'
                : _filter == _FeedFilter.liked
                ? 'Like a post to find it here.'
                : 'Share a thought, a photo, or a moment from your day.',
            style: const TextStyle(color: AppColors.muted),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          if (_query.isNotEmpty)
            TextButton(
              onPressed: () {
                _searchController.clear();
                setState(() => _query = '');
              },
              child: const Text('Clear search'),
            )
          else if (_filter == _FeedFilter.liked)
            TextButton(
              onPressed: () => _selectFilter(_FeedFilter.all),
              child: const Text('Explore the feed'),
            )
          else
            FilledButton(
              onPressed: _createPost,
              child: const Text('Create your first post'),
            ),
        ],
      ),
    ),
  );

  String _filterLabel(_FeedFilter filter) => switch (filter) {
    _FeedFilter.all => 'Home feed',
    _FeedFilter.yours => 'Your posts',
    _FeedFilter.liked => 'Liked posts',
  };
}
