import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:social_media/providers/post_provider.dart';
import 'package:social_media/screens/create_post_screen.dart';
import 'package:social_media/screens/feed_screen.dart';
import 'package:social_media/theme/app_theme.dart';
import 'package:social_media/widgets/comments_sheet.dart';

Widget app(PostProvider provider, Widget home, {double textScale = 1}) =>
    ChangeNotifierProvider.value(
      value: provider,
      child: MaterialApp(
        theme: buildAppTheme(),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(textScale)),
          child: child!,
        ),
        home: home,
      ),
    );

class RetryPostProvider extends PostProvider {
  bool failNextComment = true;

  @override
  Future<bool> addComment(String postId, String content) async {
    if (failNextComment) {
      failNextComment = false;
      throw StateError('Storage unavailable');
    }
    return super.addComment(postId, content);
  }
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  for (final size in [
    const Size(320, 740),
    const Size(390, 844),
    const Size(768, 1024),
    const Size(1024, 768),
    const Size(1440, 1000),
    const Size(740, 360),
  ]) {
    testWidgets('feed and editor fit ${size.width} x ${size.height}', (
      tester,
    ) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = size;
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);
      final provider = PostProvider();
      await provider.initialize();
      await tester.pumpWidget(app(provider, const FeedScreen()));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('A fresh perspective.'), findsOneWidget);
      expect(
        find.text('Explore topics'),
        size.width >= 1280 ? findsOneWidget : findsNothing,
      );

      await tester.pumpWidget(app(provider, const CreatePostScreen()));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('Publish post'), findsOneWidget);
      await tester.pumpWidget(const SizedBox.shrink());
      provider.dispose();
    });
  }

  testWidgets('search and filters select matching posts and liked posts', (
    tester,
  ) async {
    final provider = PostProvider();
    await provider.initialize();
    await provider.toggleLike('static-1');
    await tester.pumpWidget(app(provider, const FeedScreen()));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ChoiceChip, 'Liked posts'));
    await tester.pumpAndSettle();
    expect(find.text('Worth another look.'), findsOneWidget);
    await tester.enterText(find.byType(TextField).first, 'no matching phrase');
    await tester.pumpAndSettle();
    expect(find.text('No matching posts'), findsOneWidget);
    await tester.tap(find.byTooltip('Clear search'));
    await tester.pumpAndSettle();
    expect(find.text('No matching posts'), findsNothing);
    await tester.tap(find.widgetWithText(ChoiceChip, 'Your posts'));
    await tester.pumpAndSettle();
    expect(find.text('Your story starts here'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
    provider.dispose();
  });

  testWidgets(
    'publish from the editor and add a comment from the resulting card',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(390, 844);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);
      final provider = PostProvider();
      await provider.initialize();
      await tester.pumpWidget(app(provider, const FeedScreen()));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('New post'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'A moment worth sharing');
      await tester.pump();
      await tester.tap(find.text('Publish post'));
      await tester.pumpAndSettle();
      expect(find.byType(CreatePostScreen), findsNothing);
      expect(provider.posts.first.content, 'A moment worth sharing');
      final commentAction = find.widgetWithText(TextButton, 'Comment').first;
      await tester.ensureVisible(commentAction);
      await tester.pumpAndSettle();
      await tester.tap(commentAction);
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const ValueKey('comment-input')),
        'A comment with a purpose',
      );
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('send-comment')));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Close comments'));
      await tester.pumpAndSettle();
      expect(find.text('1 comment'), findsOneWidget);
      expect(
        provider.posts.first.comments.single.content,
        'A comment with a purpose',
      );
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      provider.dispose();
    },
  );

  testWidgets('landscape comment panel stays usable above a keyboard', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(740, 390);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    final provider = PostProvider();
    await provider.initialize();
    await tester.pumpWidget(
      app(
        provider,
        Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: FilledButton(
                onPressed: () => showPostComments(context, 'static-1'),
                child: const Text('Open comments'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open comments'));
    await tester.pumpAndSettle();
    tester.view.viewInsets = const FakeViewPadding(bottom: 240);
    addTearDown(tester.view.resetViewInsets);
    await tester.pumpAndSettle();
    final input = find.byKey(const ValueKey('comment-input'));
    await tester.ensureVisible(input);
    await tester.enterText(input, 'A landscape comment');
    await tester.pumpAndSettle();
    final send = find.byKey(const ValueKey('send-comment'));
    await tester.ensureVisible(send);
    await tester.tap(send);
    await tester.pumpAndSettle();
    expect(provider.posts.first.commentCount, 1);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    provider.dispose();
  });

  testWidgets(
    'comment modal submits text, updates count and retains it after reopening',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(390, 844);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);
      final provider = PostProvider();
      await provider.initialize();
      await tester.pumpWidget(
        app(
          provider,
          Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: FilledButton(
                  onPressed: () => showPostComments(context, 'static-1'),
                  child: const Text('Open comments'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open comments'));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<IconButton>(find.byKey(const ValueKey('send-comment')))
            .onPressed,
        isNull,
      );
      await tester.enterText(
        find.byKey(const ValueKey('comment-input')),
        'A real conversation',
      );
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('send-comment')));
      await tester.pumpAndSettle();
      expect(find.text('Comments (1)'), findsOneWidget);
      expect(find.text('A real conversation'), findsOneWidget);
      expect(
        tester
            .widget<TextField>(find.byKey(const ValueKey('comment-input')))
            .controller!
            .text,
        isEmpty,
      );
      await tester.tap(find.byTooltip('Close comments'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Open comments'));
      await tester.pumpAndSettle();
      expect(find.text('A real conversation'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      provider.dispose();
    },
  );

  testWidgets('comment failure preserves text and allows a successful retry', (
    tester,
  ) async {
    final provider = RetryPostProvider();
    await provider.initialize();
    await tester.pumpWidget(
      app(provider, const Scaffold(body: CommentsSheet(postId: 'static-1'))),
    );
    await tester.enterText(
      find.byKey(const ValueKey('comment-input')),
      'Keep this draft',
    );
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('send-comment')));
    await tester.pumpAndSettle();
    expect(find.textContaining('Your text is still here'), findsOneWidget);
    expect(
      tester
          .widget<TextField>(find.byKey(const ValueKey('comment-input')))
          .controller!
          .text,
      'Keep this draft',
    );
    expect(provider.posts.first.commentCount, 0);
    await tester.tap(find.byKey(const ValueKey('send-comment')));
    await tester.pumpAndSettle();
    expect(find.text('Comments (1)'), findsOneWidget);
    expect(find.textContaining('Your text is still here'), findsNothing);
    await tester.pumpWidget(const SizedBox.shrink());
    provider.dispose();
  });

  testWidgets(
    'phone layout supports larger text and the comment keyboard inset',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(390, 844);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);
      final provider = PostProvider();
      await provider.initialize();
      await tester.pumpWidget(
        app(provider, const FeedScreen(), textScale: 1.5),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(
        app(
          provider,
          Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: FilledButton(
                  onPressed: () => showPostComments(context, 'static-1'),
                  child: const Text('Open comments'),
                ),
              ),
            ),
          ),
          textScale: 1.5,
        ),
      );
      await tester.tap(find.text('Open comments'));
      await tester.pumpAndSettle();
      tester.view.viewInsets = const FakeViewPadding(bottom: 300);
      addTearDown(tester.view.resetViewInsets);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.enterText(
        find.byKey(const ValueKey('comment-input')),
        'With the keyboard open',
      );
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('send-comment')));
      await tester.pumpAndSettle();
      expect(find.text('Comments (1)'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      provider.dispose();
    },
  );
}
