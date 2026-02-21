import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'providers/post_provider.dart';
import 'screens/feed_screen.dart';

void main() {
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<PostProvider>(
      create: (_) => PostProvider()..initialize(),
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Feedify',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF0057FF)),
          scaffoldBackgroundColor: const Color(0xFFF3F6FF),
          appBarTheme: const AppBarTheme(
            centerTitle: false,
            foregroundColor: Color(0xFF0A1640),
            backgroundColor: Colors.transparent,
            elevation: 0,
          ),
          cardTheme: const CardThemeData(color: Colors.white),
          useMaterial3: true,
        ),
        home: const FeedScreen(),
      ),
    );
  }
}
