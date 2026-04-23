import 'package:flutter/material.dart';
import 'package:jobswipe/app/router.dart';
import 'package:jobswipe/app/theme/app_theme.dart';

class JobSwipeApp extends StatelessWidget {
  const JobSwipeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'JobSwipe',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      routerConfig: appRouter,
    );
  }
}