import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' hide EmailAuthProvider;
import 'package:flutter/material.dart';

import '../services/firebase_bootstrap.dart';
import '../theme/app_colors.dart';
import '../widgets/info_widgets.dart';

/// Email/password sign-in and registration.
///
/// When [firebaseEnabled] is false the form falls back to [onLocalSignIn],
/// which stores a demo identity on the device instead.
class LoginScreen extends StatefulWidget {
  const LoginScreen({
    super.key,
    required this.firebaseEnabled,
    this.onLocalSignIn,
  });

  final bool firebaseEnabled;
  final Future<void> Function(String email)? onLocalSignIn;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  var _creatingAccount = false;
  var _loading = false;
  var _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    setState(() => _loading = true);
    try {
      final email = _emailController.text.trim().toLowerCase();
      final password = _passwordController.text;
      if (widget.firebaseEnabled) {
        if (_creatingAccount) {
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
            email: email,
            password: password,
          );
          await FirebaseFirestore.instance
              .collection('users')
              .doc(FirebaseAuth.instance.currentUser!.uid)
              .set({
                'email': email,
                'createdAt': FieldValue.serverTimestamp(),
              }, SetOptions(merge: true));
        } else {
          await FirebaseAuth.instance.signInWithEmailAndPassword(
            email: email,
            password: password,
          );
        }
      } else {
        await widget.onLocalSignIn?.call(email);
      }
    } on FirebaseAuthException catch (error) {
      _showAuthError(error.message ?? error.code);
    } catch (error) {
      _showAuthError(error.toString());
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _forgotPassword() async {
    final email = _emailController.text.trim().toLowerCase();
    if (email.isEmpty || !email.contains('@')) {
      _showAuthError('Enter your email first.');
      return;
    }
    if (!widget.firebaseEnabled) {
      _showAuthError('Password reset is available after Firebase setup.');
      return;
    }
    await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Password reset email sent.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showAuthError(String message) {
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: cream,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
          children: [
            Row(
              children: [
                Image.asset('assets/icon/glowcycle_icon.png', width: 62),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'GlowCycle',
                    style: TextStyle(
                      color: ink,
                      fontSize: 30,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 34),
            Text(
              _creatingAccount ? 'Create your beauty shelf' : 'Welcome back',
              style: const TextStyle(
                color: ink,
                fontSize: 34,
                fontWeight: FontWeight.w900,
                letterSpacing: 0,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              widget.firebaseEnabled
                  ? 'Sign in to sync products, scans, photos, and assistant history securely.'
                  : 'Firebase is not configured yet. Use demo login to preview the app on your phone.',
              style: TextStyle(color: ink.withValues(alpha: 0.68), height: 1.4),
            ),
            if (!widget.firebaseEnabled && FirebaseBootstrap.error != null) ...[
              const SizedBox(height: 12),
              InfoPill(
                icon: Icons.info_outline,
                text: 'Demo mode: add Firebase config before store release.',
              ),
            ],
            const SizedBox(height: 26),
            Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      prefixIcon: Icon(Icons.mail_outline),
                    ),
                    validator: (value) {
                      final text = value?.trim() ?? '';
                      if (!text.contains('@')) {
                        return 'Enter a valid email';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        tooltip: _obscurePassword
                            ? 'Show password'
                            : 'Hide password',
                        onPressed: () => setState(
                          () => _obscurePassword = !_obscurePassword,
                        ),
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                        ),
                      ),
                    ),
                    validator: (value) {
                      if ((value ?? '').length < 6) {
                        return 'Password must be at least 6 characters';
                      }
                      return null;
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            FilledButton.icon(
              onPressed: _loading ? null : _submit,
              icon: _loading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Icon(
                      _creatingAccount
                          ? Icons.person_add_alt
                          : Icons.login_rounded,
                    ),
              label: Text(_creatingAccount ? 'Create Account' : 'Login'),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(54),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            const SizedBox(height: 10),
            TextButton(
              onPressed: _loading
                  ? null
                  : () => setState(() => _creatingAccount = !_creatingAccount),
              child: Text(
                _creatingAccount
                    ? 'Already have an account? Login'
                    : 'New to GlowCycle? Create account',
              ),
            ),
            TextButton(
              onPressed: _loading ? null : _forgotPassword,
              child: const Text('Forgot password'),
            ),
          ],
        ),
      ),
    );
  }
}
