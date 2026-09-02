import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import '../firebase_options.dart';

/// Initialises Firebase once at startup.
///
/// Failure is deliberately non-fatal: [configured] stays false and the app
/// falls back to the offline demo login and local storage.
class FirebaseBootstrap {
  static bool configured = false;
  static String? error;

  static Future<void> initialize() async {
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      ).timeout(const Duration(seconds: 6));
      configured = Firebase.apps.isNotEmpty;
      if (configured) {
        await FirebaseAppCheck.instance.activate(
          providerAndroid: kDebugMode
              ? const AndroidDebugProvider()
              : const AndroidPlayIntegrityProvider(),
          providerApple: kDebugMode
              ? const AppleDebugProvider()
              : const AppleAppAttestWithDeviceCheckFallbackProvider(),
        );
      }
    } catch (exception) {
      configured = false;
      error = exception.toString();
      if (kDebugMode) {
        debugPrint('Firebase bootstrap failed: $exception');
      }
    }
  }
}
