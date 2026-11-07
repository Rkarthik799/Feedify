import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:social_media/models/post.dart';
import 'package:social_media/providers/post_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  test(
    'comments on sample and user posts survive a provider restart',
    () async {
      final provider = PostProvider();
      await provider.initialize();
      provider.updateDraftText('A real post #flutter');
      expect(await provider.submitPost(), isTrue);
      final postId = provider.posts.first.id;

      expect(await provider.addComment(postId, '  A useful thought  '), isTrue);
      expect(
        await provider.addComment('static-1', 'Thanks for sharing!'),
        isTrue,
      );
      expect(await provider.addComment(postId, 'Another thought'), isTrue);

      final restarted = PostProvider();
      await restarted.initialize();
      final post = restarted.posts.singleWhere((post) => post.id == postId);
      expect(post.commentCount, 2);
      expect(post.comments.map((comment) => comment.content), [
        'A useful thought',
        'Another thought',
      ]);
      expect(post.comments.map((comment) => comment.id).toSet(), hasLength(2));
      expect(post.comments.first.author, 'You');
      expect(
        post.comments.first.createdAt.isBefore(
          DateTime.now().add(const Duration(seconds: 1)),
        ),
        isTrue,
      );
      expect(
        restarted.posts
            .singleWhere((post) => post.id == 'static-1')
            .comments
            .single
            .content,
        'Thanks for sharing!',
      );
      expect(
        restarted.posts
            .singleWhere((post) => post.id == 'static-2')
            .commentCount,
        0,
      );
      provider.dispose();
      restarted.dispose();
    },
  );

  test(
    'empty, oversized and missing-post comments do not change the count',
    () async {
      final provider = PostProvider();
      await provider.initialize();
      expect(await provider.addComment('static-1', ' \n\t '), isFalse);
      expect(
        await provider.addComment(
          'static-1',
          'a' * (PostProvider.maxCommentLength + 1),
        ),
        isFalse,
      );
      expect(await provider.addComment('missing-post', 'Hello'), isFalse);
      expect(provider.posts.first.commentCount, 0);
      expect(
        await provider.addComment(
          'static-1',
          'a' * PostProvider.maxCommentLength,
        ),
        isTrue,
      );
      expect(provider.posts.first.commentCount, 1);
      expect(
        () => provider.posts.first.comments.clear(),
        throwsUnsupportedError,
      );
      provider.dispose();
    },
  );

  test('legacy dummy counts are replaced by the actual comment list', () async {
    final oldPost = Post(
      id: 'existing-user-post',
      content: 'An older post',
      media: [],
      visibility: PostVisibility.public,
      createdAt: DateTime(2026),
      hashtags: [],
      mentions: [],
    );
    final legacyMap = oldPost.toMap()..remove('comments');
    legacyMap['commentCount'] = 12;
    final migrated = Post.fromMap(legacyMap);
    expect(migrated.content, oldPost.content);
    expect(migrated.commentCount, 0);

    SharedPreferences.setMockInitialValues({
      'local_posts': [migrated.toJson()],
    });
    final provider = PostProvider();
    await provider.initialize();
    expect(await provider.addComment(oldPost.id, 'First real comment'), isTrue);
    expect(
      provider.posts.singleWhere((post) => post.id == oldPost.id).commentCount,
      1,
    );
    provider.dispose();
  });

  test(
    'invalid storage clears the loading state and exposes a retryable error',
    () async {
      SharedPreferences.setMockInitialValues({
        'post_comments_v1': 'invalid json',
      });
      final provider = PostProvider();
      await provider.initialize();
      expect(provider.isLoading, isFalse);
      expect(provider.loadError, isNotNull);
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('post_comments_v1');
      await provider.initialize();
      expect(provider.loadError, isNull);
      expect(provider.posts, isNotEmpty);
      provider.dispose();
    },
  );
}
