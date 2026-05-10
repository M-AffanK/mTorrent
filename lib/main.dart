import 'package:flutter/material.dart';

import '../utils/app_colors.dart';
import '../routes/app_pages.dart';
import '../routes/app_routes.dart';

void main() {
  runApp(const MTorrentApp());
}

class MTorrentApp extends StatelessWidget {
  const MTorrentApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'mTorrent',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primaryBlue),
        useMaterial3: true,
      ),
      initialRoute: AppRoutes.splash,
      onGenerateRoute: AppPages.onGenerateRoute,
    );
  }
}