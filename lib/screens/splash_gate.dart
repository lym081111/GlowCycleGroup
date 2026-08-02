import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import 'auth_gate.dart';

/// Brand splash shown briefly before handing off to [AuthGate].
class SplashGate extends StatefulWidget {
  const SplashGate({super.key});

  @override
  State<SplashGate> createState() => _SplashGateState();
}

class _SplashGateState extends State<SplashGate> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 1200), () {
      if (mounted) {
        Navigator.of(
          context,
        ).pushReplacement(MaterialPageRoute(builder: (_) => const AuthGate()));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset('assets/icon/glowcycle_icon.png', width: 148),
                const SizedBox(height: 20),
                const Text(
                  'GlowCycle',
                  style: TextStyle(
                    color: ink,
                    fontSize: 36,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Track beauty. Reduce waste. Glow responsibly.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: ink.withValues(alpha: 0.68),
                    fontSize: 15,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 28),
                const SizedBox(
                  width: 34,
                  height: 34,
                  child: CircularProgressIndicator(strokeWidth: 3),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
