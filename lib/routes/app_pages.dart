import 'package:flutter/material.dart';

import '../screens/splash_screen.dart';
import '../screens/server_setup.dart';
import '../screens/home_screen.dart';
import '../screens/upload_page.dart';
import '../screens/download_page.dart';
import 'app_routes.dart';

class AppPages {
  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case AppRoutes.splash:
        return MaterialPageRoute(builder: (_) => const SplashPage());

      case AppRoutes.setup:
        final args = settings.arguments as Map<String, dynamic>?;
        return MaterialPageRoute(
          builder: (_) => SetupPage(
            isFromHome: args?['isFromHome'] ?? false,
          ),
        );

      case AppRoutes.home:
        final args = settings.arguments as Map<String, dynamic>;
        return MaterialPageRoute(
          builder: (_) => HomePage(
            host: args['host'],
            port: args['port'],
          ),
        );

      case AppRoutes.upload:
        final args = settings.arguments as Map<String, dynamic>;
        return MaterialPageRoute(
          builder: (_) => UploadPage(
            host: args['host'],
            port: args['port'],
          ),
        );

      case AppRoutes.download:
        final args = settings.arguments as Map<String, dynamic>;
        return MaterialPageRoute(
          builder: (_) => DownloadPage(
            host: args['host'],
            port: args['port'],
          ),
        );

      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(child: Text('No route defined for ${settings.name}')),
          ),
        );
    }
  }
}
