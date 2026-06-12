import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import '../config/firebase_options.dart';

enum FirebaseMode { firebase, demo }

class AppStartupResult {
  const AppStartupResult({required this.mode, this.error});

  final FirebaseMode mode;
  final Object? error;

  bool get usesFirebase => mode == FirebaseMode.firebase;
  bool get usesDemoServices => mode == FirebaseMode.demo;
}

class FirebaseBootstrap {
  const FirebaseBootstrap._();

  static Future<AppStartupResult> initialize() async {
    if (!DefaultFirebaseOptions.isConfigured) {
      return const AppStartupResult(mode: FirebaseMode.demo);
    }

    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
      }
      return const AppStartupResult(mode: FirebaseMode.firebase);
    } catch (error, stackTrace) {
      FlutterError.reportError(
        FlutterErrorDetails(
          exception: error,
          stack: stackTrace,
          library: 'firebase bootstrap',
          context: ErrorDescription('while initializing Firebase'),
        ),
      );
      return AppStartupResult(mode: FirebaseMode.demo, error: error);
    }
  }
}
