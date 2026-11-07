import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'providers/post_provider.dart';
import 'providers/story_provider.dart';
import 'screens/feed_screen.dart';
import 'theme/app_theme.dart';

void main() {
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<PostProvider>(
          create: (_) => PostProvider()..initialize(),
        ),
        ChangeNotifierProvider<StoryProvider>(
          create: (_) => StoryProvider()..initialize(),
          lazy: false,
        ),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Feedify',
        theme: buildAppTheme(),
        home: const FeedScreen(),
      ),
    );
  }
}
