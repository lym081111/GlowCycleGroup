import 'package:firebase_auth/firebase_auth.dart' hide EmailAuthProvider;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/app_user.dart';
import '../services/firebase_bootstrap.dart';
import 'glow_cycle_home.dart';
import 'login_screen.dart';

/// Chooses between the Firebase auth stream and the offline demo login,
/// then hands the resulting [AppUser] to [GlowCycleHome].
class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  static const _localUserIdKey = 'glowcycle_local_user_id';
  static const _localEmailKey = 'glowcycle_local_email';

  AppUser? _localUser;
  var _loadingLocalUser = true;

  @override
  void initState() {
    super.initState();
    _loadLocalUser();
  }

  Future<void> _loadLocalUser() async {
    if (FirebaseBootstrap.configured) {
      setState(() => _loadingLocalUser = false);
      return;
    }
    final prefs = await SharedPreferences.getInstance();
    final uid = prefs.getString(_localUserIdKey);
    final email = prefs.getString(_localEmailKey);
    setState(() {
      _localUser = uid == null || email == null
          ? null
          : AppUser(uid: uid, email: email, isFirebaseUser: false);
      _loadingLocalUser = false;
    });
  }

  Future<void> _signInLocal(String email) async {
    final prefs = await SharedPreferences.getInstance();
    final user = AppUser(
      uid: 'demo-${email.trim().toLowerCase()}',
      email: email.trim().toLowerCase(),
      isFirebaseUser: false,
    );
    await prefs.setString(_localUserIdKey, user.uid);
    await prefs.setString(_localEmailKey, user.email);
    setState(() => _localUser = user);
  }

  Future<void> _signOutLocal() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_localUserIdKey);
    await prefs.remove(_localEmailKey);
    setState(() => _localUser = null);
  }

  @override
  Widget build(BuildContext context) {
    if (_loadingLocalUser) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (!FirebaseBootstrap.configured) {
      if (_localUser == null) {
        return LoginScreen(firebaseEnabled: false, onLocalSignIn: _signInLocal);
      }
      return GlowCycleHome(user: _localUser!, onSignOut: _signOutLocal);
    }

    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        final firebaseUser = snapshot.data;
        if (firebaseUser == null) {
          return const LoginScreen(firebaseEnabled: true);
        }
        return GlowCycleHome(
          user: AppUser(
            uid: firebaseUser.uid,
            email: firebaseUser.email ?? 'glowcycle_user@app.local',
            isFirebaseUser: true,
          ),
          onSignOut: FirebaseAuth.instance.signOut,
        );
      },
    );
  }
}
