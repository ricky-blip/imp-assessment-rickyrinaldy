import 'package:flutter/material.dart';

import 'package:imp_assessment_flutter_dev/pages/splash_screen_page.dart';
import 'package:imp_assessment_flutter_dev/pages/login_page.dart';
import 'package:imp_assessment_flutter_dev/pages/posts_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const SplashScreen(),
      routes: {
        '/login': (context) => const LoginPage(),
        '/posts': (context) => const PostsPage(),
      },
    );
  }
}
