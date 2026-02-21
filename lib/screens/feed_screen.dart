import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/post_provider.dart';
import '../widgets/post_card.dart';
import 'create_post_screen.dart';

class FeedScreen extends StatelessWidget {
  const FeedScreen({super.key});

  Future<void> _reload(BuildContext context) async {
    await context.read<PostProvider>().initialize();
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
            child: provider.isLoading
                ? const Center(child: CircularProgressIndicator())
                : provider.posts.isEmpty
                ? RefreshIndicator(
                    onRefresh: () => _reload(context),
                    child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: <Widget>[
                        SizedBox(
                          height: MediaQuery.sizeOf(context).height * 0.25,
                        ),
                        Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: const <Widget>[
                              Icon(Icons.post_add_outlined, size: 56),
                              SizedBox(height: 12),
                              Text(
                                'No posts yet. Create your first local post.',
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: () => _reload(context),
                    child: ListView.builder(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: EdgeInsets.only(
                        top: 8,
                        bottom: 92 + bottomInset,
                      ),
                      itemCount: provider.posts.length,
                      itemBuilder: (_, int index) {
                        return PostCard(
                          post: provider.posts[index],
                          index: index,
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
