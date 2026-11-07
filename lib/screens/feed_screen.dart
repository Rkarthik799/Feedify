import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/post_provider.dart';
import '../providers/story_provider.dart';
import '../widgets/post_card.dart';
import '../widgets/story_tray.dart';
import 'create_post_screen.dart';

class FeedScreen extends StatelessWidget {
  const FeedScreen({super.key});

  Future<void> _reload(BuildContext context) async {
    await Future.wait<void>(<Future<void>>[
      context.read<PostProvider>().initialize(),
      context.read<StoryProvider>().initialize(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final EdgeInsets viewPadding = MediaQuery.paddingOf(context);
    final double bottomInset = viewPadding.bottom;

    return Consumer<PostProvider>(
      builder: (BuildContext context, PostProvider provider, Widget? child) {
        return Scaffold(
          backgroundColor: const Color(0xFFF3F6FF),
          appBar: AppBar(
            centerTitle: true,
            title: const Text('Feedify'),
            actions: <Widget>[
              IconButton(
                tooltip: 'Reload',
                onPressed: provider.isLoading ? null : () => _reload(context),
                icon: provider.isLoading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.refresh_rounded),
              ),
            ],
            flexibleSpace: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: <Color>[Color(0xFF00C2FF), Color(0xFF6A11CB)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const CreatePostScreen(),
                ),
              );
            },
            backgroundColor: const Color(0xFFFF6B00),
            foregroundColor: Colors.white,
            icon: const Icon(Icons.add),
            label: const Text('Create'),
          ),
          body: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: <Color>[Color(0xFFF3F6FF), Color(0xFFE6EDFF)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
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
              ),
            ),
          ),
        );
      },
    );
  }
}
