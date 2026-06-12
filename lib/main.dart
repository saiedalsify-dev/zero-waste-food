import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/config/app_constants.dart';
import 'core/providers/app_providers.dart';
import 'core/routing/app_router.dart';
import 'core/services/firebase_bootstrap.dart';
import 'core/theme/app_theme.dart';
import 'services/notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final startupResult = await FirebaseBootstrap.initialize();
  if (startupResult.usesFirebase) {
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  }

  runApp(
    ProviderScope(
      overrides: [startupResultProvider.overrideWithValue(startupResult)],
      child: const ZeroWasteFoodApp(),
    ),
  );
}

class ZeroWasteFoodApp extends StatelessWidget {
  const ZeroWasteFoodApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      initialRoute: AppRoutes.splash,
      onGenerateRoute: AppRouter.onGenerateRoute,
      
    );
  }
}
