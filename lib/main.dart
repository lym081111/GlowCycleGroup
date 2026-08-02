import 'package:flutter/material.dart';

import 'screens/splash_gate.dart';
import 'services/firebase_bootstrap.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await FirebaseBootstrap.initialize();
  runApp(const GlowCycleApp());
}

/// Root widget. Applies the shared theme and starts at the splash screen.
class GlowCycleApp extends StatelessWidget {
  const GlowCycleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GlowCycle',
      debugShowCheckedModeBanner: false,
      theme: glowCycleTheme(),
      home: const SplashGate(),
    );
  }
}
