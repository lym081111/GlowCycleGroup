import 'dart:convert';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_ai/firebase_ai.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_auth/firebase_auth.dart' hide EmailAuthProvider;
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await FirebaseBootstrap.initialize();
  runApp(const GlowCycleApp());
}

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

const productCategories = [
  'Skincare',
  'Makeup',
  'Haircare',
  'Bodycare',
  'Fragrance',
  'Others',
];

const editableStatuses = ['Unopened', 'Opened', 'Finished', 'Recycled'];

const categoryExpiryMonths = {
  'Skincare': 12,
  'Makeup': 12,
  'Haircare': 18,
  'Bodycare': 12,
  'Fragrance': 24,
  'Others': 12,
};

const primary = Color(0xFF416743);
const primaryContainer = Color(0xFFC2EEC0);
const primaryFixedDim = Color(0xFFA7D1A5);
const secondary = Color(0xFF6F5A4D);
const secondaryContainer = Color(0xFFF7DAC9);
const tertiary = Color(0xFF4E635E);
const surface = Color(0xFFF9F9F8);
const surfaceLow = Color(0xFFF3F4F3);
const surfaceContainer = Color(0xFFEEEEED);
const surfaceHigh = Color(0xFFE8E8E7);
const surfaceHighest = Color(0xFFE2E2E2);
const outlineVariant = Color(0xFFC2C8BE);
const brandPink = Color(0xFFD8788D);
const petal = Color(0xFFFFDDE4);
const blush = Color(0xFFFFF0ED);
const cream = Color(0xFFFFF8F4);
const champagne = Color(0xFFFFEBC8);
const sage = primary;
const mint = Color(0xFFDDEEDF);
const ink = Color(0xFF1A1C1C);
const cocoa = secondary;
const amber = Color(0xFFE8A041);
const danger = Color(0xFFC95C5C);
const blue = Color(0xFF6389B8);

final dateFormat = DateFormat('yyyy-MM-dd');

class GlowCycleApp extends StatelessWidget {
  const GlowCycleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GlowCycle',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: surface,
        colorScheme: ColorScheme.fromSeed(
          seedColor: primary,
          primary: primary,
          secondary: secondary,
          tertiary: tertiary,
          surface: surface,
          onSurface: ink,
        ),
        fontFamily: 'Roboto',
        appBarTheme: const AppBarTheme(
          backgroundColor: surface,
          foregroundColor: ink,
          elevation: 0,
          centerTitle: false,
        ),
        cardTheme: CardThemeData(
          color: Colors.white,
          elevation: 0.4,
          shadowColor: brandPink.withValues(alpha: 0.16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: BorderSide(color: Colors.black.withValues(alpha: 0.06)),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: surfaceLow,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: outlineVariant),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: outlineVariant),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: primary, width: 1.6),
          ),
        ),
      ),
      home: const SplashGate(),
    );
  }
}

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

class AppUser {
  const AppUser({
    required this.uid,
    required this.email,
    required this.isFirebaseUser,
  });

  final String uid;
  final String email;
  final bool isFirebaseUser;

  String get displayName => email.split('@').first;
}

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

class GlowCycleHome extends StatefulWidget {
  const GlowCycleHome({super.key, required this.user, required this.onSignOut});

  final AppUser user;
  final Future<void> Function() onSignOut;

  @override
  State<GlowCycleHome> createState() => _GlowCycleHomeState();
}

class _GlowCycleHomeState extends State<GlowCycleHome> {
  late final GlowStore _store;
  var _products = <BeautyProduct>[];
  var _actions = <EcoAction>[];
  var _selectedIndex = 0;
  var _loading = true;

  @override
  void initState() {
    super.initState();
    _store = GlowStore(user: widget.user);
    _load();
  }

  Future<void> _load() async {
    final data = await _store.load();
    setState(() {
      _products = data.products;
      _actions = data.actions;
      _loading = false;
    });
  }

  Future<void> _persist() async {
    await _store.save(_products, _actions);
  }

  Future<void> _addProduct(BeautyProduct product) async {
    setState(() {
      _products = [..._products, product];
      _actions = [
        EcoAction.created(
          actionType: 'Add product',
          pointsEarned: 1,
          description: '${product.name} added to your beauty shelf.',
          relatedProductId: product.id,
        ),
        ..._actions,
      ];
    });
    await _persist();
  }

  Future<void> _updateProduct(BeautyProduct product) async {
    setState(() {
      _products = _products
          .map(
            (item) => item.id == product.id
                ? product.copyWith(updatedAt: DateTime.now())
                : item,
          )
          .toList();
    });
    await _persist();
  }

  Future<void> _deleteProduct(String id) async {
    setState(() {
      _products = _products.where((item) => item.id != id).toList();
    });
    await _persist();
  }

  Future<void> _markFinished(BeautyProduct product) async {
    final now = DateTime.now();
    final beforeExpiry = product.daysRemaining(now) >= 0;
    final points = beforeExpiry ? 15 : 10;
    final updated = product.copyWith(status: 'Finished', updatedAt: now);
    setState(() {
      _products = _products
          .map((item) => item.id == product.id ? updated : item)
          .toList();
      _actions = [
        EcoAction.created(
          actionType: 'Finish product',
          pointsEarned: points,
          description: beforeExpiry
              ? '${product.name} finished before expiry.'
              : '${product.name} finished and removed from waste risk.',
          relatedProductId: product.id,
        ),
        ..._actions,
      ];
    });
    await _persist();
  }

  Future<void> _markRecycled(BeautyProduct product) async {
    final now = DateTime.now();
    final updated = product.copyWith(status: 'Recycled', updatedAt: now);
    setState(() {
      _products = _products
          .map((item) => item.id == product.id ? updated : item)
          .toList();
      _actions = [
        EcoAction.created(
          actionType: 'Recycle container',
          pointsEarned: 15,
          description: '${product.name} container recycled responsibly.',
          relatedProductId: product.id,
        ),
        ..._actions,
      ];
    });
    await _persist();
  }

  Future<void> _avoidDuplicate(String category) async {
    setState(() {
      _actions = [
        EcoAction.created(
          actionType: 'Avoid duplicate',
          pointsEarned: 25,
          description: 'Skipped a duplicate $category purchase.',
        ),
        ..._actions,
      ];
    });
    await _persist();
  }

  Future<void> _completeNoBuyChallenge() async {
    setState(() {
      _actions = [
        EcoAction.created(
          actionType: 'No-buy challenge',
          pointsEarned: 60,
          description: 'Completed a mindful no-buy challenge.',
        ),
        ..._actions,
      ];
    });
    await _persist();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final screens = [
      DashboardScreen(
        products: _products,
        actions: _actions,
        onAddTap: () => _openProductForm(),
        onWishlistTap: _openWishlistCheck,
        onNavigate: (index) => setState(() => _selectedIndex = index),
      ),
      InventoryScreen(products: _products, onProductTap: _openProductDetail),
      ProductFormScreen(
        onSave: _addProduct,
        store: _store,
        closeOnSave: false,
        onSaved: () => setState(() => _selectedIndex = 1),
      ),
      GlowAssistantScreen(products: _products, store: _store),
      GlowSaverScreen(
        products: _products,
        actions: _actions,
        onNoBuyChallenge: _completeNoBuyChallenge,
        onOpenRecycleMap: _openRecycleMap,
        onOpenWishlistCheck: _openWishlistCheck,
      ),
    ];

    return Scaffold(
      body: Container(
        color: surface,
        child: SafeArea(
          child: Column(
            children: [
              if (_selectedIndex != 2)
                GlowTopBar(
                  user: widget.user,
                  onSearch: () => setState(() => _selectedIndex = 1),
                  onNotifications: () => setState(() => _selectedIndex = 4),
                  onSignOut: widget.onSignOut,
                ),
              Expanded(child: screens[_selectedIndex]),
            ],
          ),
        ),
      ),
      bottomNavigationBar: GlowBottomNav(
        selectedIndex: _selectedIndex,
        onSelected: (value) => setState(() => _selectedIndex = value),
      ),
    );
  }

  Future<void> _openProductForm({BeautyProduct? product}) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ProductFormScreen(
          product: product,
          onSave: product == null ? _addProduct : _updateProduct,
          store: _store,
        ),
      ),
    );
  }

  Future<void> _openWishlistCheck() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => WishlistScreen(
          products: _products,
          onAvoidDuplicate: _avoidDuplicate,
        ),
      ),
    );
  }

  Future<void> _openProductDetail(BeautyProduct product) async {
    final latest = _products.firstWhere(
      (item) => item.id == product.id,
      orElse: () => product,
    );
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ProductDetailScreen(
          product: latest,
          onEdit: () => _openProductForm(product: latest),
          onDelete: () => _deleteProduct(latest.id),
          onFinished: () => _markFinished(latest),
          onRecycled: () => _markRecycled(latest),
        ),
      ),
    );
  }

  Future<void> _openRecycleMap() async {
    await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const RecycleScreen()));
  }
}

class GlowTopBar extends StatelessWidget {
  const GlowTopBar({
    super.key,
    required this.user,
    required this.onSearch,
    required this.onNotifications,
    required this.onSignOut,
  });

  final AppUser user;
  final VoidCallback onSearch;
  final VoidCallback onNotifications;
  final Future<void> Function() onSignOut;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 14, 24, 12),
      decoration: BoxDecoration(
        color: surface.withValues(alpha: 0.94),
        border: Border(
          bottom: BorderSide(color: outlineVariant.withValues(alpha: 0.55)),
        ),
        boxShadow: [
          BoxShadow(
            color: ink.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [primaryContainer, secondaryContainer],
              ),
            ),
            child: const Icon(Icons.spa_outlined, color: primary, size: 20),
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'GlowCycle',
              style: TextStyle(
                color: primary,
                fontWeight: FontWeight.w900,
                fontSize: 24,
                letterSpacing: 0,
              ),
            ),
          ),
          IconButton(
            tooltip: 'Search inventory',
            onPressed: onSearch,
            icon: const Icon(Icons.search, color: Color(0xFF424941)),
          ),
          IconButton(
            tooltip: 'Eco impact',
            onPressed: onNotifications,
            icon: const Icon(
              Icons.notifications_outlined,
              color: Color(0xFF424941),
            ),
          ),
          PopupMenuButton<String>(
            tooltip: 'Profile',
            onSelected: (value) {
              if (value == 'logout') {
                onSignOut();
              }
            },
            icon: CircleAvatar(
              radius: 16,
              backgroundColor: primaryContainer,
              child: Text(
                user.displayName.characters.first.toUpperCase(),
                style: const TextStyle(
                  color: primary,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            itemBuilder: (context) => [
              PopupMenuItem(
                enabled: false,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Signed in as',
                      style: TextStyle(fontSize: 12, color: secondary),
                    ),
                    Text(
                      user.email,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout, size: 18),
                    SizedBox(width: 8),
                    Text('Logout'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class GlowBottomNav extends StatelessWidget {
  const GlowBottomNav({
    super.key,
    required this.selectedIndex,
    required this.onSelected,
  });

  final int selectedIndex;
  final ValueChanged<int> onSelected;

  static const _items = [
    (Icons.home_outlined, Icons.home, 'Home'),
    (Icons.inventory_2_outlined, Icons.inventory_2, 'Shelf'),
    (Icons.document_scanner_outlined, Icons.document_scanner, 'Scan'),
    (Icons.auto_awesome_outlined, Icons.auto_awesome, 'Assistant'),
    (Icons.savings_outlined, Icons.savings, 'Saver'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 16),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
        border: const Border(top: BorderSide(color: outlineVariant)),
        boxShadow: [
          BoxShadow(
            color: ink.withValues(alpha: 0.10),
            blurRadius: 18,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          for (var i = 0; i < _items.length; i++)
            _GlowNavItem(
              icon: _items[i].$1,
              selectedIcon: _items[i].$2,
              label: _items[i].$3,
              selected: selectedIndex == i,
              onTap: () => onSelected(i),
            ),
        ],
      ),
    );
  }
}

class _GlowNavItem extends StatelessWidget {
  const _GlowNavItem({
    required this.icon,
    required this.selectedIcon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: EdgeInsets.symmetric(
          horizontal: selected ? 13 : 10,
          vertical: 7,
        ),
        decoration: BoxDecoration(
          color: selected ? primaryContainer : Colors.transparent,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              selected ? selectedIcon : icon,
              color: selected ? primary : const Color(0xFF424941),
              size: 23,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                color: selected ? primary : const Color(0xFF424941),
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({
    super.key,
    required this.products,
    required this.actions,
    required this.onAddTap,
    required this.onWishlistTap,
    required this.onNavigate,
  });

  final List<BeautyProduct> products;
  final List<EcoAction> actions;
  final VoidCallback onAddTap;
  final VoidCallback onWishlistTap;
  final ValueChanged<int> onNavigate;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final stats = InventoryStats.from(products, actions, now);
    final expiringProducts =
        products
            .where(
              (item) =>
                  ['Use Soon', 'Expired'].contains(item.resolvedStatus(now)),
            )
            .toList()
          ..sort((a, b) => a.expiryDate.compareTo(b.expiryDate));
    final activeProducts = products
        .where(
          (item) =>
              !['Finished', 'Recycled'].contains(item.resolvedStatus(now)),
        )
        .toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
      children: [
        DashboardWelcomeCard(stats: stats),
        const SizedBox(height: 28),
        SectionHeading(
          title: 'Expiring Soon',
          actionLabel: 'View All',
          onAction: () => onNavigate(1),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 244,
          child: expiringProducts.isEmpty
              ? const CalmShelfCard()
              : ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: min(expiringProducts.length, 6),
                  separatorBuilder: (_, _) => const SizedBox(width: 12),
                  itemBuilder: (context, index) {
                    final product = expiringProducts[index];
                    return DashboardExpiryCard(product: product);
                  },
                ),
        ),
        const SizedBox(height: 28),
        const SectionHeading(title: 'Quick Actions'),
        const SizedBox(height: 12),
        Column(
          children: [
            QuickActionButton(
              icon: Icons.add_circle_outline,
              label: 'Add New Product',
              color: primary,
              filled: true,
              onTap: onAddTap,
            ),
            const SizedBox(height: 8),
            QuickActionButton(
              icon: Icons.qr_code_scanner,
              label: 'Scan Barcode',
              color: primary,
              onTap: onAddTap,
            ),
            const SizedBox(height: 8),
            QuickActionButton(
              icon: Icons.eco_outlined,
              label: 'Log Empty Container',
              color: tertiary,
              onTap: () => onNavigate(4),
            ),
            const SizedBox(height: 8),
            QuickActionButton(
              icon: Icons.search,
              label: 'Check Duplicate Purchase',
              color: secondary,
              onTap: onWishlistTap,
            ),
          ],
        ),
        const SizedBox(height: 28),
        const SectionHeading(title: 'Recent Activity'),
        const SizedBox(height: 12),
        ActivityPanel(actions: actions, activeProducts: activeProducts),
      ],
    );
  }
}

class DashboardWelcomeCard extends StatelessWidget {
  const DashboardWelcomeCard({super.key, required this.stats});

  final InventoryStats stats;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const RadialGradient(
          center: Alignment.topLeft,
          radius: 1.35,
          colors: [primaryContainer, Color(0xFFFFF5F0), Color(0xFFD0E7E1)],
          stops: [0, 0.58, 1],
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: outlineVariant.withValues(alpha: 0.34)),
        boxShadow: [
          BoxShadow(
            color: primary.withValues(alpha: 0.08),
            blurRadius: 22,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Hello, User!',
            style: TextStyle(
              color: Color(0xFF153B1C),
              fontSize: 30,
              fontWeight: FontWeight.w900,
              letterSpacing: 0,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            'Your mindful routine is flourishing.',
            style: TextStyle(color: ink.withValues(alpha: 0.66), fontSize: 15),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: DashboardMetricTile(
                  label: 'Expiring Soon',
                  value: stats.useSoon.toString(),
                  suffix: 'items',
                  color: primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DashboardMetricTile(
                  label: 'Eco Points',
                  value: stats.points.toString(),
                  icon: Icons.eco,
                  color: tertiary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class DashboardMetricTile extends StatelessWidget {
  const DashboardMetricTile({
    super.key,
    required this.label,
    required this.value,
    required this.color,
    this.suffix,
    this.icon,
  });

  final String label;
  final String value;
  final String? suffix;
  final IconData? icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.62),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.48)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Flexible(
                child: Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: ink,
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0,
                    height: 1,
                  ),
                ),
              ),
              if (suffix != null) ...[
                const SizedBox(width: 4),
                Padding(
                  padding: const EdgeInsets.only(bottom: 2),
                  child: Text(
                    suffix!,
                    style: TextStyle(color: ink.withValues(alpha: 0.58)),
                  ),
                ),
              ],
              if (icon != null) ...[
                const SizedBox(width: 4),
                Padding(
                  padding: const EdgeInsets.only(bottom: 3),
                  child: Icon(icon, color: color, size: 20),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class SectionHeading extends StatelessWidget {
  const SectionHeading({
    super.key,
    required this.title,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: ink,
            fontSize: 22,
            fontWeight: FontWeight.w900,
            letterSpacing: 0,
          ),
        ),
        if (actionLabel != null)
          TextButton(onPressed: onAction, child: Text(actionLabel!)),
      ],
    );
  }
}

class DashboardExpiryCard extends StatelessWidget {
  const DashboardExpiryCard({super.key, required this.product});

  final BeautyProduct product;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final status = product.resolvedStatus(now);
    final days = product.daysRemaining(now);
    final totalDays = max(
      1,
      product.expiryDate.difference(product.openingDate).inDays,
    );
    final usedDays = now
        .difference(product.openingDate)
        .inDays
        .clamp(0, totalDays);
    final progress = usedDays / totalDays;
    final color = days <= 7 || status == 'Expired'
        ? danger
        : statusColor(status);

    return Container(
      width: 200,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: outlineVariant.withValues(alpha: 0.24)),
        boxShadow: [
          BoxShadow(
            color: primary.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 130,
            width: double.infinity,
            child: Stack(
              fit: StackFit.expand,
              children: [
                ProductImageMock(product: product, status: status),
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      status == 'Expired' ? 'Expired' : '$days Days',
                      style: TextStyle(
                        color: color,
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: ink,
                    fontWeight: FontWeight.w900,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  product.brand,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: ink.withValues(alpha: 0.58)),
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    minHeight: 6,
                    value: progress,
                    color: color,
                    backgroundColor: surfaceHighest,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class CalmShelfCard extends StatelessWidget {
  const CalmShelfCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: outlineVariant.withValues(alpha: 0.22)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.self_improvement, color: primary, size: 36),
          const SizedBox(height: 10),
          const Text(
            'No urgent products',
            style: TextStyle(color: ink, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 4),
          Text(
            'Your shelf is calm today.',
            textAlign: TextAlign.center,
            style: TextStyle(color: ink.withValues(alpha: 0.62)),
          ),
        ],
      ),
    );
  }
}

class QuickActionButton extends StatelessWidget {
  const QuickActionButton({
    super.key,
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
    this.filled = false,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: filled ? color : surfaceLow,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: filled
                ? null
                : Border.all(color: outlineVariant.withValues(alpha: 0.36)),
          ),
          child: Row(
            children: [
              Icon(icon, color: filled ? Colors.white : color),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    color: filled ? Colors.white : ink,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: filled ? Colors.white : ink.withValues(alpha: 0.58),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ActivityPanel extends StatelessWidget {
  const ActivityPanel({
    super.key,
    required this.actions,
    required this.activeProducts,
  });

  final List<EcoAction> actions;
  final List<BeautyProduct> activeProducts;

  @override
  Widget build(BuildContext context) {
    final displayActions = actions.take(3).toList();
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: outlineVariant.withValues(alpha: 0.2)),
      ),
      clipBehavior: Clip.antiAlias,
      child: displayActions.isEmpty
          ? Padding(
              padding: const EdgeInsets.all(18),
              child: Text(
                activeProducts.isEmpty
                    ? 'Add your first product to begin tracking your beauty cycle.'
                    : 'Your activity timeline will appear here.',
                style: TextStyle(color: ink.withValues(alpha: 0.62)),
              ),
            )
          : Column(
              children: [
                for (var i = 0; i < displayActions.length; i++) ...[
                  ActivityRow(action: displayActions[i]),
                  if (i != displayActions.length - 1)
                    Divider(
                      height: 1,
                      color: outlineVariant.withValues(alpha: 0.2),
                    ),
                ],
              ],
            ),
    );
  }
}

class ActivityRow extends StatelessWidget {
  const ActivityRow({super.key, required this.action});

  final EcoAction action;

  @override
  Widget build(BuildContext context) {
    final icon = action.actionType.contains('Recycle')
        ? Icons.eco
        : action.actionType.contains('Add')
        ? Icons.add
        : Icons.check_circle;
    final color = action.actionType.contains('Recycle')
        ? tertiary
        : action.actionType.contains('Add')
        ? secondary
        : primary;
    return Padding(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.18),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  action.description,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: ink,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Earned ${action.pointsEarned} Eco Points - ${dateFormat.format(action.date)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: ink.withValues(alpha: 0.58),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({
    super.key,
    required this.products,
    required this.onProductTap,
  });

  final List<BeautyProduct> products;
  final ValueChanged<BeautyProduct> onProductTap;

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  var _query = '';
  var _category = 'All';
  var _status = 'All';

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final filtered = widget.products.where((product) {
      final text = '${product.name} ${product.brand}'.toLowerCase();
      final matchesQuery = text.contains(_query.toLowerCase());
      final matchesCategory =
          _category == 'All' || product.category == _category;
      final matchesStatus =
          _status == 'All' || product.resolvedStatus(now) == _status;
      return matchesQuery && matchesCategory && matchesStatus;
    }).toList()..sort((a, b) => a.expiryDate.compareTo(b.expiryDate));

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      children: [
        const AppHeader(
          title: 'My Beauty Shelf',
          subtitle: 'Curated by expiry, category, and what deserves attention.',
        ),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFFFF5F0), Color(0xFFE7F2E7)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.white.withValues(alpha: 0.92)),
          ),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.78),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.auto_awesome, color: primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${filtered.length} item(s) on display',
                      style: const TextStyle(
                        color: ink,
                        fontWeight: FontWeight.w900,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Smart sort highlights products to finish first.',
                      style: TextStyle(
                        color: ink.withValues(alpha: 0.64),
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        TextField(
          onChanged: (value) => setState(() => _query = value),
          decoration: const InputDecoration(
            prefixIcon: Icon(Icons.search),
            hintText: 'Search your shelf',
          ),
        ),
        const SizedBox(height: 10),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (final category in ['All', ...productCategories])
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    selected: _category == category,
                    label: Text(category == 'All' ? 'All Items' : category),
                    onSelected: (_) => setState(() => _category = category),
                    selectedColor: primaryContainer,
                    backgroundColor: surfaceHigh,
                    checkmarkColor: primary,
                    labelStyle: TextStyle(
                      color: _category == category
                          ? primary
                          : const Color(0xFF424941),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ActionChip(
                  avatar: const Icon(
                    Icons.auto_awesome,
                    size: 18,
                    color: primary,
                  ),
                  label: const Text('Smart Sort'),
                  backgroundColor: primaryContainer,
                  labelStyle: const TextStyle(
                    color: primary,
                    fontWeight: FontWeight.w800,
                  ),
                  onPressed: () => setState(() => _status = 'Use Soon'),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (final status in [
                'All',
                'Safe',
                'Use Soon',
                'Expired',
                'Finished',
                'Recycled',
              ])
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    selected: _status == status,
                    label: Text(status),
                    onSelected: (_) => setState(() => _status = status),
                    selectedColor: secondaryContainer,
                    backgroundColor: surfaceLow,
                    labelStyle: TextStyle(
                      color: _status == status
                          ? secondary
                          : const Color(0xFF424941),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        if (filtered.isEmpty)
          const EmptyState(
            icon: Icons.inventory_2_outlined,
            title: 'No products found',
            message:
                'Try another filter or add a product to your beauty shelf.',
          )
        else
          BeautyShelfView(
            products: filtered,
            onProductTap: widget.onProductTap,
          ),
      ],
    );
  }
}

class ProductFormScreen extends StatefulWidget {
  const ProductFormScreen({
    super.key,
    this.product,
    required this.onSave,
    required this.store,
    this.closeOnSave = true,
    this.onSaved,
  });

  final BeautyProduct? product;
  final Future<void> Function(BeautyProduct product) onSave;
  final GlowStore store;
  final bool closeOnSave;
  final VoidCallback? onSaved;

  @override
  State<ProductFormScreen> createState() => _ProductFormScreenState();
}

class _ProductFormScreenState extends State<ProductFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _picker = ImagePicker();
  late final TextEditingController _nameController;
  late final TextEditingController _brandController;
  late final TextEditingController _expiryController;
  late final TextEditingController _photoController;
  late final TextEditingController _notesController;
  late final TextEditingController _ingredientsController;
  late final TextEditingController _batchController;
  late final TextEditingController _priceController;
  late DateTime _purchaseDate;
  late DateTime _openingDate;
  DateTime? _manufactureDate;
  DateTime? _directExpiryDate;
  late String _category;
  late String _status;
  Uint8List? _photoPreviewBytes;
  String? _lastPickedPhotoPath;
  var _scanning = false;
  var _saving = false;
  var _scanConfidence = 0.0;
  var _scanSource = 'manual';

  @override
  void initState() {
    super.initState();
    final product = widget.product;
    _nameController = TextEditingController(text: product?.name ?? '');
    _brandController = TextEditingController(text: product?.brand ?? '');
    _expiryController = TextEditingController(
      text: (product?.expiryMonths ?? 12).toString(),
    );
    _photoController = TextEditingController(text: product?.imagePath ?? '');
    _notesController = TextEditingController(text: product?.notes ?? '');
    _ingredientsController = TextEditingController(
      text: product?.ingredients.join(', ') ?? '',
    );
    _batchController = TextEditingController(text: product?.batchNumber ?? '');
    _priceController = TextEditingController(
      text: product?.price == null ? '' : product!.price!.toStringAsFixed(2),
    );
    _photoPreviewBytes = decodeProductImage(product?.imagePath ?? '');
    _purchaseDate = product?.purchaseDate ?? DateTime.now();
    _openingDate = product?.openingDate ?? DateTime.now();
    _manufactureDate = product?.manufactureDate;
    _directExpiryDate = product?.directExpiryDate;
    _scanConfidence = product?.scanConfidence ?? 0;
    _scanSource = product?.scanSource ?? 'manual';
    _category = product?.category ?? 'Skincare';
    _status = editableStatuses.contains(product?.status)
        ? product!.status
        : 'Opened';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _brandController.dispose();
    _expiryController.dispose();
    _photoController.dispose();
    _notesController.dispose();
    _ingredientsController.dispose();
    _batchController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.product != null;
    final selectedExpiry = int.tryParse(_expiryController.text.trim());
    return Scaffold(
      backgroundColor: surface,
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Product' : 'Add Product'),
        actions: [
          IconButton(
            tooltip: 'Save',
            onPressed: _save,
            icon: const Icon(Icons.check),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 110),
          children: [
            Text(
              isEditing ? 'Refresh product details' : 'Add New Product',
              style: const TextStyle(
                color: ink,
                fontSize: 30,
                fontWeight: FontWeight.w900,
                letterSpacing: 0,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              'Track its opening date, PAO, and lifecycle status in one place.',
              style: TextStyle(
                color: ink.withValues(alpha: 0.64),
                height: 1.35,
              ),
            ),
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFFF1F4), Color(0xFFE7F2E7)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.white.withValues(alpha: 0.86)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      children: [
                        AspectRatio(
                          aspectRatio: 1.1,
                          child: Container(
                            clipBehavior: Clip.antiAlias,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.62),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.86),
                              ),
                            ),
                            child: _photoPreviewBytes == null
                                ? Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.add_a_photo_outlined,
                                        color: primary.withValues(alpha: 0.9),
                                        size: 30,
                                      ),
                                      const SizedBox(height: 8),
                                      const Text(
                                        'Photo',
                                        style: TextStyle(
                                          color: ink,
                                          fontWeight: FontWeight.w900,
                                        ),
                                      ),
                                    ],
                                  )
                                : Image.memory(
                                    _photoPreviewBytes!,
                                    fit: BoxFit.cover,
                                    width: double.infinity,
                                    height: double.infinity,
                                  ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () =>
                                    _pickProductPhoto(ImageSource.camera),
                                child: const Icon(Icons.photo_camera_outlined),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () =>
                                    _pickProductPhoto(ImageSource.gallery),
                                child: const Icon(Icons.photo_library_outlined),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        FilledButton.icon(
                          onPressed: _scanning
                              ? null
                              : () => _scanPhotoWithAi(
                                  _lastPickedPhotoPath == null
                                      ? ImageSource.camera
                                      : null,
                                ),
                          icon: _scanning
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.auto_awesome),
                          label: Text(
                            _scanning
                                ? 'Scanning...'
                                : _lastPickedPhotoPath == null
                                ? 'AI scan'
                                : 'Extract details',
                          ),
                          style: FilledButton.styleFrom(
                            minimumSize: const Size.fromHeight(42),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'AI Smart Fill',
                          style: TextStyle(
                            color: ink,
                            fontWeight: FontWeight.w900,
                            fontSize: 18,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _scanSource == 'manual'
                              ? 'Scan packaging text to auto-fill ingredients, dates, batch number, and category.'
                              : 'Last scan confidence: ${(_scanConfidence * 100).round()}%',
                          style: TextStyle(
                            color: ink.withValues(alpha: 0.66),
                            height: 1.3,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            for (final months in [6, 12, 18, 24])
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.72),
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Text(
                                  '${months}M',
                                  style: const TextStyle(
                                    color: primary,
                                    fontWeight: FontWeight.w900,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            _FormPanel(
              title: 'Product Identity',
              child: Column(
                children: [
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Product name',
                      prefixIcon: Icon(Icons.spa_outlined),
                    ),
                    validator: requiredText,
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _brandController,
                    decoration: const InputDecoration(
                      labelText: 'Brand',
                      prefixIcon: Icon(Icons.local_offer_outlined),
                    ),
                    validator: requiredText,
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    initialValue: _category,
                    items: productCategories
                        .map(
                          (item) =>
                              DropdownMenuItem(value: item, child: Text(item)),
                        )
                        .toList(),
                    onChanged: (value) {
                      final category = value ?? 'Skincare';
                      setState(() {
                        _category = category;
                        _expiryController.text =
                            (categoryExpiryMonths[category] ?? 12).toString();
                      });
                    },
                    decoration: const InputDecoration(
                      labelText: 'Category',
                      prefixIcon: Icon(Icons.category_outlined),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            _FormPanel(
              title: 'Lifecycle',
              child: Column(
                children: [
                  DatePickerTile(
                    label: 'Purchase date',
                    date: _purchaseDate,
                    onPick: (date) => setState(() => _purchaseDate = date),
                  ),
                  const SizedBox(height: 10),
                  DatePickerTile(
                    label: 'Opening date',
                    date: _openingDate,
                    onPick: (date) => setState(() => _openingDate = date),
                  ),
                  const SizedBox(height: 10),
                  OptionalDatePickerTile(
                    label: 'Manufacturing date',
                    date: _manufactureDate,
                    onPick: (date) => setState(() => _manufactureDate = date),
                    onClear: () => setState(() => _manufactureDate = null),
                  ),
                  const SizedBox(height: 10),
                  OptionalDatePickerTile(
                    label: 'Printed expiry date',
                    date: _directExpiryDate,
                    onPick: (date) => setState(() => _directExpiryDate = date),
                    onClear: () => setState(() => _directExpiryDate = null),
                  ),
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'PAO duration',
                      style: TextStyle(
                        color: ink.withValues(alpha: 0.72),
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final months in [3, 6, 12, 18, 24])
                        ChoiceChip(
                          selected: selectedExpiry == months,
                          label: Text('${months}M'),
                          onSelected: (selected) {
                            if (selected) {
                              setState(
                                () =>
                                    _expiryController.text = months.toString(),
                              );
                            }
                          },
                          selectedColor: primaryContainer,
                          backgroundColor: surfaceLow,
                          labelStyle: TextStyle(
                            color: selectedExpiry == months
                                ? primary
                                : ink.withValues(alpha: 0.7),
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _expiryController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Custom expiry months',
                      prefixIcon: Icon(Icons.event_repeat_outlined),
                    ),
                    validator: (value) {
                      final parsed = int.tryParse(value ?? '');
                      if (parsed == null || parsed <= 0) {
                        return 'Enter a valid number of months';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    initialValue: _status,
                    items: editableStatuses
                        .map(
                          (item) =>
                              DropdownMenuItem(value: item, child: Text(item)),
                        )
                        .toList(),
                    onChanged: (value) =>
                        setState(() => _status = value ?? 'Opened'),
                    decoration: const InputDecoration(
                      labelText: 'Product status',
                      prefixIcon: Icon(Icons.check_circle_outline),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            _FormPanel(
              title: 'Optional Details',
              child: Column(
                children: [
                  TextFormField(
                    controller: _ingredientsController,
                    minLines: 2,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      labelText: 'Ingredients',
                      prefixIcon: Icon(Icons.science_outlined),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _batchController,
                    decoration: const InputDecoration(
                      labelText: 'Batch number',
                      prefixIcon: Icon(Icons.qr_code_2_outlined),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _priceController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Estimated price (RM)',
                      prefixIcon: Icon(Icons.payments_outlined),
                    ),
                    validator: (value) {
                      final text = value?.trim() ?? '';
                      if (text.isEmpty) {
                        return null;
                      }
                      final parsed = double.tryParse(text);
                      if (parsed == null || parsed < 0) {
                        return 'Enter a valid price';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _notesController,
                    minLines: 3,
                    maxLines: 5,
                    decoration: const InputDecoration(
                      labelText: 'Notes',
                      prefixIcon: Icon(Icons.notes_outlined),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 18),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.96),
          border: Border(top: BorderSide(color: ink.withValues(alpha: 0.06))),
        ),
        child: SafeArea(
          child: FilledButton.icon(
            onPressed: _saving ? null : _save,
            icon: _saving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.add_circle_outline),
            label: Text(
              _saving
                  ? 'Saving...'
                  : (isEditing ? 'Save Changes' : 'Add to Shelf'),
            ),
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(52),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _pickProductPhoto(ImageSource source) async {
    try {
      final picked = await _picker.pickImage(
        source: source,
        maxWidth: 1200,
        imageQuality: 70,
      );
      if (picked == null) {
        return;
      }
      final bytes = await picked.readAsBytes();
      if (bytes.isEmpty) {
        return;
      }
      setState(() {
        _photoPreviewBytes = bytes;
        _lastPickedPhotoPath = picked.path;
        _photoController.text = 'data:image/jpeg;base64,${base64Encode(bytes)}';
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Unable to open photo picker: $error'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _scanPhotoWithAi(ImageSource? sourceIfMissing) async {
    try {
      String? imagePath = _lastPickedPhotoPath;
      if (imagePath == null && sourceIfMissing != null) {
        final picked = await _picker.pickImage(
          source: sourceIfMissing,
          // Small packaging text is often lost by aggressive compression.
          maxWidth: 2048,
          imageQuality: 92,
        );
        if (picked == null) {
          return;
        }
        final bytes = await picked.readAsBytes();
        setState(() {
          _photoPreviewBytes = bytes;
          _lastPickedPhotoPath = picked.path;
          _photoController.text =
              'data:image/jpeg;base64,${base64Encode(bytes)}';
        });
        imagePath = picked.path;
      }
      if (imagePath == null) {
        _showFormMessage('Choose a product photo first.');
        return;
      }

      setState(() => _scanning = true);
      final result = await ProductScanService(
        store: widget.store,
      ).scan(imagePath: imagePath, imageDataUri: _photoController.text);
      if (!mounted) {
        return;
      }
      final shouldApply = await _showScanReview(result);
      if (shouldApply == true && mounted) {
        _applyScanResult(result);
        _showFormMessage(
          'Scan details added. Please check every field before saving.',
        );
      }
    } catch (error) {
      _showFormMessage('Unable to scan product details: $error');
    } finally {
      if (mounted) {
        setState(() => _scanning = false);
      }
    }
  }

  void _applyScanResult(ProductScanResult result) {
    setState(() {
      if (result.productName.isNotEmpty) {
        _nameController.text = result.productName;
      }
      if (result.brand.isNotEmpty) {
        _brandController.text = result.brand;
      }
      if (productCategories.contains(result.category)) {
        _category = result.category;
      }
      if (result.ingredients.isNotEmpty) {
        _ingredientsController.text = result.ingredients.join(', ');
      }
      if (result.batchNumber.isNotEmpty) {
        _batchController.text = result.batchNumber;
      }
      if (result.manufactureDate != null) {
        _manufactureDate = result.manufactureDate;
      }
      if (result.expiryDate != null) {
        _directExpiryDate = result.expiryDate;
      }
      if (result.paoMonths != null && result.paoMonths! > 0) {
        _expiryController.text = result.paoMonths.toString();
      }
      _scanConfidence = result.confidence;
      _scanSource = result.source;
      final existingNotes = _notesController.text.trim();
      final scanNote = 'AI scan text: ${result.rawTextPreview}';
      _notesController.text = existingNotes.isEmpty
          ? scanNote
          : '$existingNotes\n\n$scanNote';
    });
  }

  Future<bool?> _showScanReview(ProductScanResult result) {
    return showModalBottomSheet<bool>(
      context: context,
      showDragHandle: true,
      builder: (context) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Review scan result',
              style: TextStyle(
                color: ink,
                fontSize: 22,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 10),
            DetailRow(label: 'Name', value: result.productName),
            DetailRow(label: 'Brand', value: result.brand),
            DetailRow(label: 'Category', value: result.category),
            DetailRow(
              label: 'Ingredients',
              value: result.ingredients.isEmpty
                  ? 'Not detected'
                  : result.ingredients.take(8).join(', '),
            ),
            DetailRow(
              label: 'Expiry',
              value: result.expiryDate == null
                  ? 'Not detected'
                  : dateFormat.format(result.expiryDate!),
            ),
            DetailRow(
              label: 'Confidence',
              value: '${(result.confidence * 100).round()}%',
            ),
            if (result.confidence < 0.72) ...[
              const SizedBox(height: 8),
              const Text(
                'Some packaging text was unclear. Check the photo and edit any field that looks wrong.',
                style: TextStyle(color: secondary, fontWeight: FontWeight.w700),
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: const Text('Edit manually'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    child: const Text('Apply scan'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showFormMessage(String message) {
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      _showFormMessage(
        'Please complete Product name, Brand, and expiry months.',
      );
      return;
    }
    setState(() => _saving = true);
    try {
      final now = DateTime.now();
      final existing = widget.product;
      final id = existing?.id ?? now.microsecondsSinceEpoch.toString();
      final uploadedImagePath = await widget.store.uploadProductPhoto(
        productId: id,
        dataUri: _photoController.text.trim(),
      );
      final product = BeautyProduct(
        id: id,
        name: _nameController.text.trim(),
        brand: _brandController.text.trim(),
        category: _category,
        purchaseDate: _purchaseDate,
        openingDate: _openingDate,
        expiryMonths: int.parse(_expiryController.text.trim()),
        status: _status,
        imagePath: uploadedImagePath.isEmpty
            ? _photoController.text.trim()
            : uploadedImagePath,
        notes: _notesController.text.trim(),
        ingredients: parseIngredients(_ingredientsController.text),
        manufactureDate: _manufactureDate,
        directExpiryDate: _directExpiryDate,
        batchNumber: _batchController.text.trim(),
        price: _priceController.text.trim().isEmpty
            ? null
            : double.parse(_priceController.text.trim()),
        scanConfidence: _scanConfidence,
        scanSource: _scanSource,
        createdAt: existing?.createdAt ?? now,
        updatedAt: now,
      );
      await widget.onSave(product);
      if (!mounted) {
        return;
      }
      if (widget.closeOnSave && Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      } else {
        widget.onSaved?.call();
        _showFormMessage('${product.name} added to your beauty shelf.');
      }
    } catch (error) {
      _showFormMessage('Unable to save product: $error');
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }
}

class _FormPanel extends StatelessWidget {
  const _FormPanel({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: ink.withValues(alpha: 0.06)),
        boxShadow: [
          BoxShadow(
            color: primary.withValues(alpha: 0.05),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: ink,
              fontSize: 17,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class ProductDetailScreen extends StatelessWidget {
  const ProductDetailScreen({
    super.key,
    required this.product,
    required this.onEdit,
    required this.onDelete,
    required this.onFinished,
    required this.onRecycled,
  });

  final BeautyProduct product;
  final VoidCallback onEdit;
  final Future<void> Function() onDelete;
  final Future<void> Function() onFinished;
  final Future<void> Function() onRecycled;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final status = product.resolvedStatus(now);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Product detail'),
        actions: [
          IconButton(
            tooltip: 'Edit product',
            onPressed: onEdit,
            icon: const Icon(Icons.edit_outlined),
          ),
          IconButton(
            tooltip: 'Delete product',
            onPressed: () async {
              final ok = await showDialog<bool>(
                context: context,
                builder: (_) => AlertDialog(
                  title: const Text('Delete product?'),
                  content: Text(
                    '${product.name} will be removed from your local inventory.',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Cancel'),
                    ),
                    FilledButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('Delete'),
                    ),
                  ],
                ),
              );
              if (ok == true) {
                await onDelete();
                if (context.mounted) Navigator.pop(context);
              }
            },
            icon: const Icon(Icons.delete_outline),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: ink.withValues(alpha: 0.06)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CategoryIcon(category: product.category, size: 58),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            product.name,
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                              color: ink,
                              height: 1.1,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            product.brand,
                            style: TextStyle(
                              color: ink.withValues(alpha: 0.62),
                              fontSize: 15,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                StatusBadge(status: status),
                const SizedBox(height: 18),
                DetailRow(label: 'Category', value: product.category),
                DetailRow(
                  label: 'Purchase date',
                  value: dateFormat.format(product.purchaseDate),
                ),
                DetailRow(
                  label: 'Opening date',
                  value: dateFormat.format(product.openingDate),
                ),
                if (product.manufactureDate != null)
                  DetailRow(
                    label: 'MFG date',
                    value: dateFormat.format(product.manufactureDate!),
                  ),
                DetailRow(
                  label: 'Expiry date',
                  value: dateFormat.format(product.expiryDate),
                ),
                DetailRow(
                  label: 'Days remaining',
                  value: product.daysRemaining(now).toString(),
                ),
                DetailRow(
                  label: 'Expiry duration',
                  value: '${product.expiryMonths} months',
                ),
                if (product.batchNumber.isNotEmpty)
                  DetailRow(label: 'Batch', value: product.batchNumber),
                if (product.price != null)
                  DetailRow(
                    label: 'Price',
                    value: 'RM ${product.price!.toStringAsFixed(2)}',
                  ),
                if (product.ingredients.isNotEmpty)
                  DetailRow(
                    label: 'Ingredients',
                    value: product.ingredients.join(', '),
                  ),
                if (product.scanSource != 'manual')
                  DetailRow(
                    label: 'AI scan',
                    value:
                        '${product.scanSource} - ${(product.scanConfidence * 100).round()}%',
                  ),
                if (product.imagePath.isNotEmpty)
                  DetailRow(label: 'Photo reference', value: product.imagePath),
                if (product.notes.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Text(
                    'Notes',
                    style: TextStyle(
                      color: ink.withValues(alpha: 0.58),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    product.notes,
                    style: const TextStyle(color: ink, height: 1.35),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 18),
          FilledButton.icon(
            onPressed: ['Finished', 'Recycled'].contains(status)
                ? null
                : () async {
                    await onFinished();
                    if (context.mounted) Navigator.pop(context);
                  },
            icon: const Icon(Icons.check_circle_outline),
            label: const Text('Mark as finished'),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: status == 'Recycled'
                ? null
                : () async {
                    await onRecycled();
                    if (context.mounted) Navigator.pop(context);
                  },
            icon: const Icon(Icons.recycling),
            label: const Text('Mark container recycled'),
          ),
        ],
      ),
    );
  }
}

class GlowAssistantScreen extends StatefulWidget {
  const GlowAssistantScreen({
    super.key,
    required this.products,
    required this.store,
  });

  final List<BeautyProduct> products;
  final GlowStore store;

  @override
  State<GlowAssistantScreen> createState() => _GlowAssistantScreenState();
}

class _GlowAssistantScreenState extends State<GlowAssistantScreen> {
  final _controller = TextEditingController();
  final _messages = <AssistantChatMessage>[
    AssistantChatMessage(
      role: 'assistant',
      text:
          'Tell me what your skin feels like today. I will check your current shelf and suggest a simple, safe routine from products you already own.',
    ),
  ];
  var _sending = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _sending) {
      return;
    }
    setState(() {
      _controller.clear();
      _messages.add(AssistantChatMessage(role: 'user', text: text));
      _sending = true;
    });
    await widget.store.saveChatMessage(role: 'user', text: text);
    final reply = await widget.store.askAssistant(
      message: text,
      products: widget.products,
    );
    final replyText = '${reply.message}\n\n${reply.safetyNote}';
    if (!mounted) {
      return;
    }
    setState(() {
      _messages.add(AssistantChatMessage(role: 'assistant', text: replyText));
      _sending = false;
    });
    await widget.store.saveChatMessage(role: 'assistant', text: replyText);
  }

  @override
  Widget build(BuildContext context) {
    final usableProducts = widget.products
        .where((item) => item.resolvedStatus(DateTime.now()) == 'Safe')
        .length;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
          child: Column(
            children: [
              const AppHeader(
                title: 'Glow Assistant',
                subtitle:
                    'AI skincare guidance based on your current beauty shelf.',
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: mint,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.inventory_2_outlined, color: primary),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        '$usableProducts safe products available for recommendations.',
                        style: const TextStyle(
                          color: ink,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
            itemCount: _messages.length + (_sending ? 1 : 0),
            itemBuilder: (context, index) {
              if (_sending && index == _messages.length) {
                return const AssistantBubble(
                  message: AssistantChatMessage(
                    role: 'assistant',
                    text: 'Thinking through your shelf...',
                  ),
                );
              }
              return AssistantBubble(message: _messages[index]);
            },
          ),
        ),
        Container(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(top: BorderSide(color: ink.withValues(alpha: 0.06))),
          ),
          child: SafeArea(
            top: false,
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    minLines: 1,
                    maxLines: 4,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _send(),
                    decoration: const InputDecoration(
                      hintText: 'Example: My skin is red and itchy today',
                      prefixIcon: Icon(Icons.spa_outlined),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  tooltip: 'Send',
                  onPressed: _sending ? null : _send,
                  icon: const Icon(Icons.send),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class AssistantChatMessage {
  const AssistantChatMessage({required this.role, required this.text});

  final String role;
  final String text;
}

class AssistantBubble extends StatelessWidget {
  const AssistantBubble({super.key, required this.message});

  final AssistantChatMessage message;

  @override
  Widget build(BuildContext context) {
    final isUser = message.role == 'user';
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 320),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isUser ? primary : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: ink.withValues(alpha: 0.06)),
        ),
        child: Text(
          message.text,
          style: TextStyle(color: isUser ? Colors.white : ink, height: 1.35),
        ),
      ),
    );
  }
}

class GlowSaverScreen extends StatelessWidget {
  const GlowSaverScreen({
    super.key,
    required this.products,
    required this.actions,
    required this.onNoBuyChallenge,
    required this.onOpenRecycleMap,
    required this.onOpenWishlistCheck,
  });

  final List<BeautyProduct> products;
  final List<EcoAction> actions;
  final Future<void> Function() onNoBuyChallenge;
  final VoidCallback onOpenRecycleMap;
  final VoidCallback onOpenWishlistCheck;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final stats = InventoryStats.from(products, actions, now);
    final savedMoney = actions.fold<double>(
      0,
      (total, action) => total + action.pointsEarned,
    );
    final valueAtRisk = products
        .where(
          (item) =>
              item.resolvedStatus(now) == 'Use Soon' ||
              item.resolvedStatus(now) == 'Expired',
        )
        .fold<double>(0, (total, item) => total + (item.price ?? 0));
    final priority =
        products
            .where(
              (item) =>
                  item.resolvedStatus(now) == 'Use Soon' ||
                  item.resolvedStatus(now) == 'Expired',
            )
            .toList()
          ..sort(
            (a, b) => a.daysRemaining(now).compareTo(b.daysRemaining(now)),
          );
    final overloaded = _overloadedCategories(products, now);

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      children: [
        const AppHeader(
          title: 'Glow Saver',
          subtitle:
              'Turn mindful beauty habits into real savings and less waste.',
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: ink,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              const Icon(Icons.savings, color: Color(0xFFFFD977), size: 42),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'RM ${savedMoney.toStringAsFixed(0)}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 34,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      'estimated saved from skipped duplicates and no-buy actions',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.74),
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: StatTile(
                label: 'Value at risk',
                value: 'RM ${valueAtRisk.toStringAsFixed(0)}',
                icon: Icons.warning_amber_outlined,
                color: amber,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: StatTile(
                label: 'Recycled',
                value: stats.recycled.toString(),
                icon: Icons.recycling,
                color: sage,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: FilledButton.icon(
                onPressed: onOpenWishlistCheck,
                icon: const Icon(Icons.shopping_bag_outlined),
                label: const Text('Check before buying'),
              ),
            ),
            const SizedBox(width: 10),
            IconButton.filledTonal(
              tooltip: 'Recycle map',
              onPressed: onOpenRecycleMap,
              icon: const Icon(Icons.map_outlined),
            ),
          ],
        ),
        const SizedBox(height: 10),
        OutlinedButton.icon(
          onPressed: onNoBuyChallenge,
          icon: const Icon(Icons.calendar_month_outlined),
          label: const Text('Log no-buy challenge: RM 60 saved'),
        ),
        const SizedBox(height: 18),
        const SectionTitle('Use before buying'),
        const SizedBox(height: 10),
        if (priority.isEmpty)
          const EmptyState(
            icon: Icons.check_circle_outline,
            title: 'No urgent products',
            message: 'Your shelf has no expiring products right now.',
          )
        else
          ...priority
              .take(5)
              .map(
                (item) => ProductShelfCard(
                  product: item,
                  compact: true,
                  onTap: () {},
                ),
              ),
        const SizedBox(height: 18),
        const SectionTitle('Category overload'),
        const SizedBox(height: 10),
        if (overloaded.isEmpty)
          const EmptyState(
            icon: Icons.balance_outlined,
            title: 'Balanced shelf',
            message: 'No product category looks overloaded.',
          )
        else
          ...overloaded.map(
            (entry) => ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const CircleAvatar(
                backgroundColor: blush,
                child: Icon(Icons.priority_high, color: brandPink),
              ),
              title: Text(
                '${entry.key}: ${entry.value} active products',
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
              subtitle: const Text('Finish one before buying another.'),
            ),
          ),
        const SizedBox(height: 18),
        const SectionTitle('Impact history'),
        const SizedBox(height: 10),
        if (actions.isEmpty)
          const EmptyState(
            icon: Icons.history_outlined,
            title: 'No saver history yet',
            message:
                'Skipped purchases, finished products, and recycling will appear here.',
          )
        else
          ...actions
              .take(8)
              .map(
                (action) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(
                    backgroundColor: mint,
                    child: Text(
                      'RM',
                      style: const TextStyle(
                        color: ink,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  title: Text(
                    action.actionType,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  subtitle: Text(
                    '${action.description}\nSaved estimate: RM ${action.pointsEarned} - ${dateFormat.format(action.date)}',
                  ),
                  isThreeLine: true,
                ),
              ),
      ],
    );
  }

  static List<MapEntry<String, int>> _overloadedCategories(
    List<BeautyProduct> products,
    DateTime now,
  ) {
    final counts = <String, int>{};
    for (final product in products) {
      final status = product.resolvedStatus(now);
      if (status == 'Finished' || status == 'Recycled' || status == 'Expired') {
        continue;
      }
      counts.update(product.category, (value) => value + 1, ifAbsent: () => 1);
    }
    return counts.entries.where((entry) => entry.value >= 3).toList();
  }
}

class WishlistScreen extends StatefulWidget {
  const WishlistScreen({
    super.key,
    required this.products,
    required this.onAvoidDuplicate,
  });

  final List<BeautyProduct> products;
  final Future<void> Function(String category) onAvoidDuplicate;

  @override
  State<WishlistScreen> createState() => _WishlistScreenState();
}

class _WishlistScreenState extends State<WishlistScreen> {
  var _category = 'Makeup';
  var _productName = '';
  var _checked = false;
  var _saved = false;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final matches = widget.products
        .where(
          (item) =>
              item.category == _category &&
              !['Finished', 'Recycled'].contains(item.resolvedStatus(now)),
        )
        .toList();
    final useSoon = matches
        .where((item) => item.resolvedStatus(now) == 'Use Soon')
        .length;

    return Scaffold(
      appBar: AppBar(title: const Text('Wishlist check')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
        children: [
          const AppHeader(
            title: 'Think before buying',
            subtitle: 'Check your shelf before a new beauty purchase.',
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            initialValue: _category,
            items: productCategories
                .map((item) => DropdownMenuItem(value: item, child: Text(item)))
                .toList(),
            onChanged: (value) => setState(() {
              _category = value ?? 'Makeup';
              _checked = false;
              _saved = false;
            }),
            decoration: const InputDecoration(
              labelText: 'Product category you want to buy',
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            onChanged: (value) => setState(() => _productName = value),
            decoration: const InputDecoration(
              labelText: 'Product name (optional)',
              prefixIcon: Icon(Icons.shopping_bag_outlined),
            ),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: () => setState(() => _checked = true),
            icon: const Icon(Icons.search),
            label: const Text('Check inventory'),
          ),
          if (_checked) ...[
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: matches.isEmpty ? mint : blush,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    matches.isEmpty
                        ? Icons.check_circle
                        : Icons.lightbulb_outline,
                    color: matches.isEmpty ? sage : brandPink,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    matches.isEmpty
                        ? 'No active $_category products found.'
                        : 'You already have ${matches.length} active $_category product(s).',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: ink,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    matches.isEmpty
                        ? 'If this purchase is necessary, add it after buying so GlowCycle can track its lifecycle.'
                        : '$useSoon of them are expiring soon. Consider finishing one before buying ${_productName.isEmpty ? 'another item' : _productName}.',
                    style: TextStyle(
                      color: ink.withValues(alpha: 0.72),
                      height: 1.35,
                    ),
                  ),
                  if (matches.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    FilledButton.icon(
                      onPressed: _saved
                          ? null
                          : () async {
                              await widget.onAvoidDuplicate(_category);
                              setState(() => _saved = true);
                            },
                      icon: const Icon(Icons.eco_outlined),
                      label: Text(
                        _saved
                            ? 'Eco points added'
                            : 'I will skip this purchase',
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 14),
            ...matches
                .take(4)
                .map(
                  (item) => ProductShelfCard(
                    product: item,
                    compact: true,
                    onTap: () {},
                  ),
                ),
          ],
        ],
      ),
    );
  }
}

class RecycleScreen extends StatefulWidget {
  const RecycleScreen({super.key});

  @override
  State<RecycleScreen> createState() => _RecycleScreenState();
}

class _RecycleScreenState extends State<RecycleScreen> {
  late Future<List<RecyclePoint>> _points;

  @override
  void initState() {
    super.initState();
    _points = RecycleService.fetchRecyclePoints();
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      children: [
        const AppHeader(
          title: 'Recycle points',
          subtitle:
              'External endpoint data for responsible packaging disposal.',
        ),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: mint,
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Row(
            children: [
              Icon(Icons.cloud_sync_outlined, color: ink),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'This screen connects to OpenStreetMap Overpass API and falls back to curated demo points if the endpoint is unavailable.',
                  style: TextStyle(color: ink, height: 1.35),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        FutureBuilder<List<RecyclePoint>>(
          future: _points,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Padding(
                padding: EdgeInsets.all(34),
                child: Center(child: CircularProgressIndicator()),
              );
            }
            final points = snapshot.data ?? RecycleService.fallbackPoints;
            return Column(
              children: points
                  .map(
                    (point) => Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.place_outlined, color: sage),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    point.name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 18,
                                      color: ink,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Text(
                              point.address,
                              style: TextStyle(
                                color: ink.withValues(alpha: 0.74),
                                height: 1.35,
                              ),
                            ),
                            const SizedBox(height: 10),
                            InfoPill(
                              icon: Icons.recycling,
                              text: point.acceptedItems,
                            ),
                            const SizedBox(height: 8),
                            InfoPill(
                              icon: Icons.schedule,
                              text: point.openingHours,
                            ),
                            const SizedBox(height: 8),
                            InfoPill(
                              icon: Icons.social_distance,
                              text:
                                  '${point.distanceKm.toStringAsFixed(1)} km from UTAR Kampar reference',
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                  .toList(),
            );
          },
        ),
      ],
    );
  }
}

class EcoPointsScreen extends StatelessWidget {
  const EcoPointsScreen({
    super.key,
    required this.products,
    required this.actions,
    required this.onNoBuyChallenge,
  });

  final List<BeautyProduct> products;
  final List<EcoAction> actions;
  final Future<void> Function() onNoBuyChallenge;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final stats = InventoryStats.from(products, actions, now);
    final badges = BadgeRule.unlocked(products, actions, now);
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      children: [
        const AppHeader(
          title: 'Eco points',
          subtitle: 'Small sustainable actions, visible progress.',
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: ink,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.auto_awesome,
                color: Color(0xFFFFD977),
                size: 42,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${stats.points}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 38,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      'total eco points',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.72),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: StatTile(
                label: 'Finished',
                value: stats.finished.toString(),
                icon: Icons.check_circle_outline,
                color: blue,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: StatTile(
                label: 'Recycled',
                value: stats.recycled.toString(),
                icon: Icons.recycling,
                color: sage,
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        FilledButton.icon(
          onPressed: onNoBuyChallenge,
          icon: const Icon(Icons.calendar_month_outlined),
          label: const Text('Complete no-buy challenge +20'),
        ),
        const SizedBox(height: 18),
        const SectionTitle('Badges unlocked'),
        const SizedBox(height: 10),
        if (badges.isEmpty)
          const EmptyState(
            icon: Icons.emoji_events_outlined,
            title: 'No badges yet',
            message: 'Add, finish, or recycle products to unlock achievements.',
          )
        else
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: badges
                .map((badge) => BadgeChip(label: badge.label, icon: badge.icon))
                .toList(),
          ),
        const SizedBox(height: 18),
        const SectionTitle('Recent eco actions'),
        const SizedBox(height: 10),
        if (actions.isEmpty)
          const EmptyState(
            icon: Icons.eco_outlined,
            title: 'No actions yet',
            message: 'Your responsible beauty actions will appear here.',
          )
        else
          ...actions
              .take(8)
              .map(
                (action) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(
                    backgroundColor: mint,
                    child: Text(
                      '+${action.pointsEarned}',
                      style: const TextStyle(
                        color: ink,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  title: Text(
                    action.actionType,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      color: ink,
                    ),
                  ),
                  subtitle: Text(
                    '${action.description}\n${dateFormat.format(action.date)}',
                  ),
                  isThreeLine: true,
                ),
              ),
      ],
    );
  }
}

class BeautyProduct {
  BeautyProduct({
    required this.id,
    required this.name,
    required this.brand,
    required this.category,
    required this.purchaseDate,
    required this.openingDate,
    required this.expiryMonths,
    required this.status,
    required this.imagePath,
    required this.notes,
    required this.ingredients,
    this.manufactureDate,
    this.directExpiryDate,
    this.batchNumber = '',
    this.price,
    this.scanConfidence = 0,
    this.scanSource = 'manual',
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String name;
  final String brand;
  final String category;
  final DateTime purchaseDate;
  final DateTime openingDate;
  final int expiryMonths;
  final String status;
  final String imagePath;
  final String notes;
  final List<String> ingredients;
  final DateTime? manufactureDate;
  final DateTime? directExpiryDate;
  final String batchNumber;
  final double? price;
  final double scanConfidence;
  final String scanSource;
  final DateTime createdAt;
  final DateTime updatedAt;

  DateTime get expiryDate =>
      directExpiryDate ??
      DateTime(
        openingDate.year,
        openingDate.month + expiryMonths,
        openingDate.day,
      );

  int daysRemaining(DateTime now) {
    final today = DateTime(now.year, now.month, now.day);
    final expiry = DateTime(expiryDate.year, expiryDate.month, expiryDate.day);
    return expiry.difference(today).inDays;
  }

  String resolvedStatus(DateTime now) {
    if (status == 'Finished' || status == 'Recycled') {
      return status;
    }
    final days = daysRemaining(now);
    if (days < 0) {
      return 'Expired';
    }
    if (days <= 30) {
      return 'Use Soon';
    }
    if (status == 'Unopened') {
      return 'Unopened';
    }
    return 'Safe';
  }

  BeautyProduct copyWith({String? status, DateTime? updatedAt}) {
    return BeautyProduct(
      id: id,
      name: name,
      brand: brand,
      category: category,
      purchaseDate: purchaseDate,
      openingDate: openingDate,
      expiryMonths: expiryMonths,
      status: status ?? this.status,
      imagePath: imagePath,
      notes: notes,
      ingredients: ingredients,
      manufactureDate: manufactureDate,
      directExpiryDate: directExpiryDate,
      batchNumber: batchNumber,
      price: price,
      scanConfidence: scanConfidence,
      scanSource: scanSource,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'brand': brand,
    'category': category,
    'purchaseDate': purchaseDate.toIso8601String(),
    'openingDate': openingDate.toIso8601String(),
    'expiryMonths': expiryMonths,
    'status': status,
    'imagePath': imagePath,
    'notes': notes,
    'ingredients': ingredients,
    'manufactureDate': manufactureDate?.toIso8601String(),
    'directExpiryDate': directExpiryDate?.toIso8601String(),
    'batchNumber': batchNumber,
    'price': price,
    'scanConfidence': scanConfidence,
    'scanSource': scanSource,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };

  Map<String, dynamic> toAssistantJson() => {
    'name': name,
    'brand': brand,
    'category': category,
    'status': resolvedStatus(DateTime.now()),
    'expiryDate': expiryDate.toIso8601String(),
    'ingredients': ingredients,
    'notes': notes,
  };

  factory BeautyProduct.fromJson(Map<String, dynamic> json) {
    return BeautyProduct(
      id: json['id'] as String,
      name: json['name'] as String,
      brand: json['brand'] as String,
      category: json['category'] as String,
      purchaseDate: DateTime.parse(json['purchaseDate'] as String),
      openingDate: DateTime.parse(json['openingDate'] as String),
      expiryMonths: json['expiryMonths'] as int,
      status: json['status'] as String,
      imagePath: json['imagePath'] as String? ?? '',
      notes: json['notes'] as String? ?? '',
      ingredients: ((json['ingredients'] as List?) ?? [])
          .map((item) => item.toString())
          .toList(),
      manufactureDate: parseOptionalDate(json['manufactureDate']),
      directExpiryDate: parseOptionalDate(json['directExpiryDate']),
      batchNumber: json['batchNumber'] as String? ?? '',
      price: (json['price'] as num?)?.toDouble(),
      scanConfidence: (json['scanConfidence'] as num?)?.toDouble() ?? 0,
      scanSource: json['scanSource'] as String? ?? 'manual',
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }
}

class EcoAction {
  EcoAction({
    required this.id,
    required this.actionType,
    required this.pointsEarned,
    required this.description,
    required this.date,
    this.relatedProductId,
  });

  factory EcoAction.created({
    required String actionType,
    required int pointsEarned,
    required String description,
    String? relatedProductId,
  }) {
    final now = DateTime.now();
    return EcoAction(
      id: now.microsecondsSinceEpoch.toString(),
      actionType: actionType,
      pointsEarned: pointsEarned,
      description: description,
      date: now,
      relatedProductId: relatedProductId,
    );
  }

  final String id;
  final String actionType;
  final int pointsEarned;
  final String description;
  final DateTime date;
  final String? relatedProductId;

  Map<String, dynamic> toJson() => {
    'id': id,
    'actionType': actionType,
    'pointsEarned': pointsEarned,
    'description': description,
    'date': date.toIso8601String(),
    'relatedProductId': relatedProductId,
  };

  factory EcoAction.fromJson(Map<String, dynamic> json) {
    return EcoAction(
      id: json['id'] as String,
      actionType: json['actionType'] as String,
      pointsEarned: json['pointsEarned'] as int,
      description: json['description'] as String,
      date: DateTime.parse(json['date'] as String),
      relatedProductId: json['relatedProductId'] as String?,
    );
  }
}

class RecyclePoint {
  RecyclePoint({
    required this.id,
    required this.name,
    required this.address,
    required this.acceptedItems,
    required this.openingHours,
    required this.latitude,
    required this.longitude,
    required this.distanceKm,
  });

  final String id;
  final String name;
  final String address;
  final String acceptedItems;
  final String openingHours;
  final double latitude;
  final double longitude;
  final double distanceKm;
}

class GlowStore {
  GlowStore({required this.user});

  final AppUser user;

  static const _productsKey = 'glowcycle_products';
  static const _actionsKey = 'glowcycle_actions';
  static const _migrationKey = 'glowcycle_firestore_migrated';

  bool get _useFirebase => user.isFirebaseUser && FirebaseBootstrap.configured;

  String get _localProductsKey => '${_productsKey}_${user.uid}';
  String get _localActionsKey => '${_actionsKey}_${user.uid}';

  CollectionReference<Map<String, dynamic>> get _productsRef =>
      FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('products');

  CollectionReference<Map<String, dynamic>> get _actionsRef => FirebaseFirestore
      .instance
      .collection('users')
      .doc(user.uid)
      .collection('actions');

  Future<AppData> load() async {
    if (_useFirebase) {
      await _migrateLocalDataIfNeeded();
      final productSnapshot = await _productsRef
          .orderBy('updatedAt', descending: true)
          .get();
      final actionSnapshot = await _actionsRef
          .orderBy('date', descending: true)
          .get();
      final products = productSnapshot.docs
          .map((doc) => BeautyProduct.fromJson(doc.data()))
          .toList();
      final actions = actionSnapshot.docs
          .map((doc) => EcoAction.fromJson(doc.data()))
          .toList();
      if (products.isEmpty) {
        final seeded = _seedProducts();
        await save(seeded, actions);
        return AppData(products: seeded, actions: actions);
      }
      return AppData(products: products, actions: actions);
    }
    return _loadLocal();
  }

  Future<AppData> _loadLocal() async {
    final prefs = await SharedPreferences.getInstance();
    final productRaw =
        prefs.getString(_localProductsKey) ?? prefs.getString(_productsKey);
    final actionRaw =
        prefs.getString(_localActionsKey) ?? prefs.getString(_actionsKey);
    final products = productRaw == null
        ? _seedProducts()
        : (jsonDecode(productRaw) as List)
              .map(
                (item) => BeautyProduct.fromJson(item as Map<String, dynamic>),
              )
              .toList();
    final actions = actionRaw == null
        ? <EcoAction>[]
        : (jsonDecode(actionRaw) as List)
              .map((item) => EcoAction.fromJson(item as Map<String, dynamic>))
              .toList();
    if (productRaw == null) {
      await save(products, actions);
    }
    return AppData(products: products, actions: actions);
  }

  Future<void> save(
    List<BeautyProduct> products,
    List<EcoAction> actions,
  ) async {
    if (_useFirebase) {
      try {
        final batch = FirebaseFirestore.instance.batch();
        final currentProducts = await _productsRef.get();
        final currentActions = await _actionsRef.get();
        final productIds = products.map((item) => item.id).toSet();
        final actionIds = actions.map((item) => item.id).toSet();

        for (final doc in currentProducts.docs) {
          if (!productIds.contains(doc.id)) {
            batch.delete(doc.reference);
          }
        }
        for (final doc in currentActions.docs) {
          if (!actionIds.contains(doc.id)) {
            batch.delete(doc.reference);
          }
        }
        for (final product in products) {
          batch.set(_productsRef.doc(product.id), product.toJson());
        }
        for (final action in actions) {
          batch.set(_actionsRef.doc(action.id), action.toJson());
        }
        await batch.commit();
        return;
      } catch (_) {
        // Keep the user's shelf usable while Firebase rules or connectivity are unavailable.
      }
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _localProductsKey,
      jsonEncode(products.map((item) => item.toJson()).toList()),
    );
    await prefs.setString(
      _localActionsKey,
      jsonEncode(actions.map((item) => item.toJson()).toList()),
    );
  }

  Future<String> uploadProductPhoto({
    required String productId,
    required String dataUri,
  }) async {
    if (!_useFirebase || !dataUri.startsWith('data:image')) {
      return '';
    }
    final commaIndex = dataUri.indexOf(',');
    if (commaIndex == -1) {
      return '';
    }
    try {
      final bytes = base64Decode(dataUri.substring(commaIndex + 1));
      final ref = FirebaseStorage.instance
          .ref()
          .child('users')
          .child(user.uid)
          .child('product_photos')
          .child('$productId.jpg');
      await ref.putData(bytes, SettableMetadata(contentType: 'image/jpeg'));
      return ref.getDownloadURL();
    } catch (_) {
      return '';
    }
  }

  Future<ProductScanResult> extractProductData({
    required String ocrText,
    required String imageDataUri,
  }) async {
    if (_useFirebase) {
      try {
        final callable = FirebaseFunctions.instance.httpsCallable(
          'extractProductFromPackaging',
        );
        final response = await callable.call<Map<String, dynamic>>({
          'ocrText': ocrText,
          'imageDataUri': imageDataUri,
        });
        return ProductScanResult.fromJson(response.data, ocrText);
      } catch (_) {
        return ProductScanResult.fromOcrHeuristic(ocrText);
      }
    }
    return ProductScanResult.fromOcrHeuristic(ocrText);
  }

  Future<AssistantReply> askAssistant({
    required String message,
    required List<BeautyProduct> products,
  }) async {
    final activeProducts = products
        .where(
          (item) => ![
            'Expired',
            'Finished',
            'Recycled',
          ].contains(item.resolvedStatus(DateTime.now())),
        )
        .map((item) => item.toAssistantJson())
        .toList();

    if (_useFirebase) {
      try {
        final reply = await _askGemini(
          message: message,
          inventory: activeProducts,
        );
        return reply.isSafeFor(message, products)
            ? reply
            : AssistantReply.local(message, products);
      } catch (exception) {
        if (kDebugMode) {
          debugPrint('Gemini Assistant fallback: $exception');
        }
        return AssistantReply.local(message, products);
      }
    }
    return AssistantReply.local(message, products);
  }

  Future<AssistantReply> _askGemini({
    required String message,
    required List<Map<String, dynamic>> inventory,
  }) async {
    final responseSchema = Schema.object(
      properties: {
        'message': Schema.string(),
        'productNames': Schema.array(items: Schema.string()),
        'safetyNote': Schema.string(),
      },
    );
    final model = FirebaseAI.googleAI().generativeModel(
      model: 'gemini-3.5-flash',
      generationConfig: GenerationConfig(
        temperature: 0.2,
        maxOutputTokens: 500,
        responseMimeType: 'application/json',
        responseSchema: responseSchema,
      ),
    );
    final prompt = '''
You are Glow Assistant, a cautious beauty inventory helper. Give practical,
short skincare guidance based only on the user's Safe Shelf inventory below.

User concern: ${jsonEncode(message)}
Safe Shelf inventory JSON: ${jsonEncode(inventory)}

Rules:
- Reply with the required JSON only.
- productNames must contain only exact product names from Safe Shelf that you
  actively recommend. Never invent, rename, or recommend a product not listed.
- Do not recommend expired, finished, recycled, or unknown products.
- Give a simple routine with 2 to 4 clearly numbered steps when appropriate.
- Do not diagnose, claim to treat disease, or make medical guarantees.
- If symptoms are severe, painful, swollen, infected, involve vision changes,
  or persist, advise a doctor, dermatologist, or optometrist.
- For eye concerns: never recommend lip products, makeup, fragrance, acids,
  retinoids, vitamin C, or unlabelled skincare in or near the eye. Recommend an
  eye drop only when an exact shelf item is clearly an eye drop/lubricant.
- If no suitable shelf item exists, say so honestly and give low-risk general
  guidance without naming a product the user does not own.
- In message, do not mention a named product unless it also appears exactly in
  productNames. Keep the tone supportive and concise.
''';
    final response = await model
        .generateContent([Content.text(prompt)])
        .timeout(const Duration(seconds: 20));
    final raw = response.text;
    if (raw == null || raw.trim().isEmpty) {
      throw const FormatException('Gemini returned an empty response.');
    }
    final decoded = jsonDecode(raw);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Gemini returned an invalid response.');
    }
    return AssistantReply.fromJson(decoded);
  }

  Future<void> saveChatMessage({
    required String role,
    required String text,
  }) async {
    if (!_useFirebase) {
      return;
    }
    await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('chats')
        .add({
          'role': role,
          'text': text,
          'createdAt': FieldValue.serverTimestamp(),
        });
  }

  Future<void> _migrateLocalDataIfNeeded() async {
    final prefs = await SharedPreferences.getInstance();
    final key = '${_migrationKey}_${user.uid}';
    if (prefs.getBool(key) ?? false) {
      return;
    }
    final existing = await _productsRef.limit(1).get();
    if (existing.docs.isNotEmpty) {
      await prefs.setBool(key, true);
      return;
    }
    final localProducts = prefs.getString(_productsKey);
    final localActions = prefs.getString(_actionsKey);
    if (localProducts == null && localActions == null) {
      await prefs.setBool(key, true);
      return;
    }
    final products = localProducts == null
        ? <BeautyProduct>[]
        : (jsonDecode(localProducts) as List)
              .map(
                (item) => BeautyProduct.fromJson(item as Map<String, dynamic>),
              )
              .toList();
    final actions = localActions == null
        ? <EcoAction>[]
        : (jsonDecode(localActions) as List)
              .map((item) => EcoAction.fromJson(item as Map<String, dynamic>))
              .toList();
    if (products.isNotEmpty || actions.isNotEmpty) {
      await save(products, actions);
    }
    await prefs.setBool(key, true);
  }

  List<BeautyProduct> _seedProducts() {
    final now = DateTime.now();
    return [
      BeautyProduct(
        id: 'seed-serum',
        name: 'Vitamin Glow Serum',
        brand: 'LumiLab',
        category: 'Skincare',
        purchaseDate: now.subtract(const Duration(days: 80)),
        openingDate: now.subtract(const Duration(days: 330)),
        expiryMonths: 12,
        status: 'Opened',
        imagePath: '',
        notes: 'Use at night before moisturizer.',
        ingredients: const ['Vitamin C', 'Hyaluronic Acid', 'Panthenol'],
        manufactureDate: null,
        directExpiryDate: null,
        batchNumber: '',
        price: 89,
        scanConfidence: 0,
        scanSource: 'seed',
        createdAt: now,
        updatedAt: now,
      ),
      BeautyProduct(
        id: 'seed-lip',
        name: 'Rose Cream Lip Tint',
        brand: 'Petal Muse',
        category: 'Makeup',
        purchaseDate: now.subtract(const Duration(days: 40)),
        openingDate: now.subtract(const Duration(days: 20)),
        expiryMonths: 18,
        status: 'Opened',
        imagePath: '',
        notes: 'Everyday shade.',
        ingredients: const ['Shea Butter', 'Rosehip Oil'],
        manufactureDate: null,
        directExpiryDate: null,
        batchNumber: '',
        price: 42,
        scanConfidence: 0,
        scanSource: 'seed',
        createdAt: now,
        updatedAt: now,
      ),
    ];
  }
}

class AppData {
  AppData({required this.products, required this.actions});

  final List<BeautyProduct> products;
  final List<EcoAction> actions;
}

class ProductScanService {
  ProductScanService({required this.store});

  final GlowStore store;

  Future<ProductScanResult> scan({
    required String imagePath,
    required String imageDataUri,
  }) async {
    final recognizer = TextRecognizer(script: TextRecognitionScript.latin);
    try {
      final recognized = await recognizer.processImage(
        InputImage.fromFilePath(imagePath),
      );
      final text = recognized.text.trim();
      if (text.isEmpty) {
        return ProductScanResult.empty();
      }
      return store.extractProductData(
        ocrText: text,
        imageDataUri: imageDataUri,
      );
    } finally {
      await recognizer.close();
    }
  }
}

class ProductScanResult {
  ProductScanResult({
    required this.productName,
    required this.brand,
    required this.category,
    required this.ingredients,
    required this.manufactureDate,
    required this.expiryDate,
    required this.paoMonths,
    required this.batchNumber,
    required this.confidence,
    required this.source,
    required this.rawTextPreview,
  });

  final String productName;
  final String brand;
  final String category;
  final List<String> ingredients;
  final DateTime? manufactureDate;
  final DateTime? expiryDate;
  final int? paoMonths;
  final String batchNumber;
  final double confidence;
  final String source;
  final String rawTextPreview;

  factory ProductScanResult.empty() {
    return ProductScanResult(
      productName: '',
      brand: '',
      category: 'Skincare',
      ingredients: const [],
      manufactureDate: null,
      expiryDate: null,
      paoMonths: null,
      batchNumber: '',
      confidence: 0,
      source: 'ocr-empty',
      rawTextPreview: 'No readable text detected.',
    );
  }

  factory ProductScanResult.fromJson(
    Map<String, dynamic> json,
    String fallbackText,
  ) {
    return ProductScanResult(
      productName: (json['productName'] ?? '').toString(),
      brand: (json['brand'] ?? '').toString(),
      category: productCategories.contains(json['category'])
          ? json['category'].toString()
          : 'Skincare',
      ingredients: _cleanIngredients((json['ingredients'] as List?) ?? []),
      manufactureDate: parseOptionalDate(json['manufactureDate']),
      expiryDate: parseOptionalDate(json['expiryDate']),
      paoMonths: (json['paoMonths'] as num?)?.round(),
      batchNumber: (json['batchNumber'] ?? '').toString(),
      confidence: ((json['confidence'] as num?)?.toDouble() ?? 0).clamp(0, 1),
      source: 'firebase-ai',
      rawTextPreview: _previewText(fallbackText),
    );
  }

  factory ProductScanResult.fromOcrHeuristic(String text) {
    final lines = text
        .split(RegExp(r'\n+'))
        .map((item) => item.trim())
        .where((item) => item.length > 2)
        .toList();
    final ingredients = _extractIngredients(text);
    final pao = RegExp(
      r'(\d{1,2})\s*M\b',
      caseSensitive: false,
    ).firstMatch(text);
    final batch = RegExp(
      r'(?:batch|lot|bn|b/no)\s*[:#-]?\s*([A-Z0-9-]{3,})',
      caseSensitive: false,
    ).firstMatch(text);
    return ProductScanResult(
      productName: lines.length > 1
          ? lines[1]
          : (lines.isEmpty ? '' : lines[0]),
      brand: lines.isEmpty ? '' : lines.first,
      category: _guessCategory(text),
      ingredients: ingredients,
      manufactureDate: _extractDate(text, ['mfg', 'mfd', 'manufactured']),
      expiryDate: _extractDate(text, ['exp', 'expiry', 'expires']),
      paoMonths: pao == null ? null : int.tryParse(pao.group(1)!),
      batchNumber: batch?.group(1) ?? '',
      confidence: ingredients.isEmpty ? 0.46 : 0.62,
      source: 'local-ocr',
      rawTextPreview: _previewText(text),
    );
  }

  static List<String> _extractIngredients(String text) {
    final match = RegExp(
      r'(?:ingredients?|inci)\s*[:\-]?\s*([\s\S]{8,900})',
      caseSensitive: false,
    ).firstMatch(text);
    if (match == null) {
      return const [];
    }
    final lines = (match.group(1) ?? '').split(RegExp(r'\n+'));
    final ingredientLines = <String>[];
    for (final line in lines) {
      if (RegExp(
        r'^(?:directions?|how to use|warning|caution|made in|manufactured|mfg|mfd|exp|expiry|batch|lot|net\s*(?:wt|weight|content))',
        caseSensitive: false,
      ).hasMatch(line.trim())) {
        break;
      }
      ingredientLines.add(line);
    }
    return _cleanIngredients(
      parseIngredients(ingredientLines.join(', ')),
    ).take(40).toList();
  }

  static List<String> _cleanIngredients(Iterable<dynamic> values) {
    final seen = <String>{};
    final cleaned = <String>[];
    for (final value in values) {
      final ingredient = value
          .toString()
          .replaceAll(RegExp(r'\s+'), ' ')
          .trim();
      final normalized = ingredient.toLowerCase();
      if (ingredient.length < 2 ||
          ingredient.length > 80 ||
          normalized.contains('ingredient') ||
          normalized.contains('directions') ||
          normalized.contains('warning') ||
          !RegExp(r'[a-zA-Z]').hasMatch(ingredient) ||
          !seen.add(normalized)) {
        continue;
      }
      cleaned.add(ingredient);
    }
    return cleaned;
  }

  static DateTime? _extractDate(String text, List<String> labels) {
    final labelPattern = labels.join('|');
    final match = RegExp(
      '(?:$labelPattern)\\s*[:\\-]?\\s*(\\d{1,2}[./-]\\d{1,2}[./-]\\d{2,4}|\\d{4}[./-]\\d{1,2}[./-]\\d{1,2})',
      caseSensitive: false,
    ).firstMatch(text);
    if (match == null) {
      return null;
    }
    return _parseLooseDate(match.group(1)!);
  }

  static DateTime? _parseLooseDate(String raw) {
    final parts = raw.split(RegExp(r'[./-]')).map(int.tryParse).toList();
    if (parts.length != 3 || parts.any((item) => item == null)) {
      return null;
    }
    var first = parts[0]!;
    final second = parts[1]!;
    var third = parts[2]!;
    if (first > 1900) {
      return DateTime.tryParse(
        '${first.toString().padLeft(4, '0')}-${second.toString().padLeft(2, '0')}-${third.toString().padLeft(2, '0')}',
      );
    }
    if (third < 100) {
      third += 2000;
    }
    return DateTime.tryParse(
      '${third.toString().padLeft(4, '0')}-${second.toString().padLeft(2, '0')}-${first.toString().padLeft(2, '0')}',
    );
  }

  static String _guessCategory(String text) {
    final lower = text.toLowerCase();
    if (lower.contains('lip') ||
        lower.contains('foundation') ||
        lower.contains('mascara')) {
      return 'Makeup';
    }
    if (lower.contains('shampoo') || lower.contains('conditioner')) {
      return 'Haircare';
    }
    if (lower.contains('body') || lower.contains('lotion')) {
      return 'Bodycare';
    }
    if (lower.contains('parfum') || lower.contains('fragrance')) {
      return 'Fragrance';
    }
    return 'Skincare';
  }

  static String _previewText(String text) {
    final compact = text.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (compact.length <= 180) {
      return compact;
    }
    return '${compact.substring(0, 180)}...';
  }
}

class AssistantReply {
  AssistantReply({
    required this.message,
    required this.productNames,
    required this.safetyNote,
  });

  final String message;
  final List<String> productNames;
  final String safetyNote;

  factory AssistantReply.fromJson(Map<String, dynamic> json) {
    return AssistantReply(
      message: (json['message'] ?? '').toString(),
      productNames: ((json['productNames'] as List?) ?? [])
          .map((item) => item.toString())
          .toList(),
      safetyNote: (json['safetyNote'] ?? '').toString(),
    );
  }

  factory AssistantReply.local(String message, List<BeautyProduct> products) {
    final lower = message.toLowerCase();
    final now = DateTime.now();
    final eyeConcern = _isEyeConcern(lower);
    final active = products
        .where((item) => item.resolvedStatus(now) == 'Safe')
        .toList();
    final gentle = active.where((item) {
      final text =
          '${item.name} ${item.category} ${item.ingredients.join(' ')} ${item.notes}'
              .toLowerCase();
      if (eyeConcern && !_isEyeCompatible(item, text)) {
        return false;
      }
      return text.contains('barrier') ||
          text.contains('ceramide') ||
          text.contains('panthenol') ||
          text.contains('hyaluronic') ||
          text.contains('moistur');
    }).toList();
    final eyeSafeActive = eyeConcern
        ? active
              .where((item) => _isEyeCompatible(item, _productText(item)))
              .toList()
        : active;
    final chosen = gentle.isEmpty
        ? eyeSafeActive.take(2).toList()
        : gentle.take(3).toList();
    if (eyeConcern) {
      final names = chosen.map((item) => item.name).toList();
      final eyeDrops = chosen
          .where((item) => _isEyeDropProduct(_productText(item)))
          .toList();
      final productAdvice = eyeDrops.isNotEmpty
          ? 'You have ${eyeDrops.map((item) => item.name).join(', ')} on your shelf. Use it only as directed on its label, and do not use it if the bottle is expired or contaminated.'
          : names.isEmpty
          ? 'I cannot find a suitable lubricating eye drop or gentle eye-area product on your shelf.'
          : 'The only shelf items worth considering around the eye area are ${names.join(', ')}.';
      return AssistantReply(
        message:
            'Dry or irritated eyes need extra caution. Do not put lip balm, makeup, fragrance, acids, retinoids, vitamin C, or new products in or close to your eyes. $productAdvice Use skincare only on the surrounding skin if the label says it is suitable, and stop if it stings.',
        productNames: names,
        safetyNote:
            'Glow Assistant is not a medical diagnosis. For eye pain, light sensitivity, discharge, swelling, vision changes, or symptoms that persist, seek prompt advice from an optometrist or doctor.',
      );
    }

    final sensitiveConcern = _hasAny(lower, [
      'red',
      'itch',
      'sensitive',
      'irritat',
      'rash',
      '泛红',
      '痒',
      '敏感',
    ]);
    final dryConcern = _hasAny(lower, [
      'dry',
      'dehydrat',
      'tight',
      'flaky',
      'dryness',
      '干燥',
      '紧绷',
    ]);
    final breakoutConcern = _hasAny(lower, [
      'acne',
      'pimple',
      'breakout',
      'blemish',
      'blackhead',
      '痘',
      '粉刺',
    ]);
    final usedIds = <String>{};
    final chosenProducts = <BeautyProduct>[];

    BeautyProduct? pick(Iterable<BeautyProduct> candidates) {
      for (final item in candidates) {
        if (usedIds.add(item.id)) {
          chosenProducts.add(item);
          return item;
        }
      }
      return null;
    }

    final gentleProducts = active.where(
      (item) => !_hasStrongActives(_productText(item)),
    );
    final cleansers = gentleProducts.where(
      (item) => _hasAny(_productText(item), [
        'cleanser',
        'cleanse',
        'face wash',
        'micellar',
      ]),
    );
    final barrierProducts = gentleProducts.where(
      (item) => _hasAny(_productText(item), [
        'moistur',
        'barrier',
        'ceramide',
        'panthenol',
        'hyaluronic',
        'glycerin',
        'centella',
        'squalane',
        'cream',
      ]),
    );
    final acneProducts = active.where(
      (item) => _hasAny(_productText(item), [
        'salicylic',
        'bha',
        'benzoyl',
        'azelaic',
        'niacinamide',
      ]),
    );

    final routine = <String>[];
    if (sensitiveConcern) {
      final cleanser = pick(cleansers);
      final barrier = pick(barrierProducts);
      routine.add(
        cleanser == null
            ? 'Cleanse: use only a gentle cleanser if your skin tolerates it.'
            : 'Cleanse: use ${cleanser.name} with lukewarm water.',
      );
      routine.add(
        barrier == null
            ? 'Support: use a basic fragrance-free moisturiser if you have one.'
            : 'Support: apply ${barrier.name} in a thin layer to support the skin barrier.',
      );
    } else if (breakoutConcern && !dryConcern) {
      final cleanser = pick(cleansers);
      final treatment = pick(acneProducts);
      final barrier = pick(barrierProducts);
      routine.add(
        cleanser == null
            ? 'Cleanse: keep cleansing gentle and do not scrub.'
            : 'Cleanse: start with ${cleanser.name}.',
      );
      routine.add(
        treatment == null
            ? 'Treat: I cannot find a clearly labelled acne treatment on your shelf, so do not introduce several new actives today.'
            : 'Treat: use ${treatment.name} only as directed, and do not layer it with other strong actives.',
      );
      if (barrier != null) {
        routine.add(
          'Support: finish with ${barrier.name} if your skin feels dry.',
        );
      }
    } else {
      final cleanser = pick(cleansers);
      final hydration = pick(barrierProducts);
      routine.add(
        cleanser == null
            ? 'Cleanse: keep this step gentle and brief.'
            : 'Cleanse: start with ${cleanser.name}.',
      );
      routine.add(
        hydration == null
            ? 'Hydrate: use your simplest moisturising product in a thin layer.'
            : 'Hydrate: apply ${hydration.name} while skin is slightly damp.',
      );
    }

    final concernLabel = sensitiveConcern
        ? 'Your message sounds like irritation or sensitivity.'
        : breakoutConcern
        ? 'Your message sounds like a breakout concern.'
        : dryConcern
        ? 'Your message sounds like dehydration or dryness.'
        : 'I will keep the routine low-risk because the concern is not specific yet.';
    final avoid = sensitiveConcern
        ? 'Avoid today: exfoliating acids, retinoids, strong vitamin C, scrubs, fragrance, and trying new products.'
        : breakoutConcern
        ? 'Avoid today: picking, scrubbing, and stacking several acne actives in one routine.'
        : 'Avoid today: layering too many actives at once or using any product that stings.';
    final names = chosenProducts.map((item) => item.name).toList();
    return AssistantReply(
      message:
          'Skin signal: $concernLabel\n\nSuggested routine:\n${routine.asMap().entries.map((entry) => '${entry.key + 1}. ${entry.value}').join('\n')}\n\n$avoid',
      productNames: names,
      safetyNote:
          'Glow Assistant is not a medical diagnosis. Seek professional care if symptoms are painful, swollen, infected, or persistent.',
    );
  }

  bool isSafeFor(String userMessage, List<BeautyProduct> products) {
    final safeNames = products
        .where((item) => item.resolvedStatus(DateTime.now()) == 'Safe')
        .map((item) => item.name.toLowerCase())
        .toSet();
    if (!productNames.every((name) => safeNames.contains(name.toLowerCase()))) {
      return false;
    }
    if (!_isEyeConcern(userMessage.toLowerCase())) {
      return true;
    }
    final replyText = '$message ${productNames.join(' ')}'.toLowerCase();
    if (RegExp(
      r'\b(?:use|apply|put|try)\s+(?:a\s+|your\s+)?(?:lip|lipstick|lip balm|tint|gloss|mascara|eyeliner)\b',
    ).hasMatch(replyText)) {
      return false;
    }
    final allowedNames = products
        .where(
          (item) =>
              item.resolvedStatus(DateTime.now()) == 'Safe' &&
              _isEyeCompatible(item, _productText(item)),
        )
        .map((item) => item.name.toLowerCase())
        .toSet();
    return productNames.every(
      (name) => allowedNames.contains(name.toLowerCase()),
    );
  }

  static bool _isEyeConcern(String text) {
    return RegExp(
      r'\b(?:eye|eyes|eyelid|under-eye|under eye)\b',
    ).hasMatch(text);
  }

  static String _productText(BeautyProduct item) {
    return '${item.name} ${item.category} ${item.ingredients.join(' ')} ${item.notes}'
        .toLowerCase();
  }

  static bool _isEyeCompatible(BeautyProduct item, String text) {
    if (_isEyeDropProduct(text)) {
      return true;
    }
    if (item.category != 'Skincare') {
      return false;
    }
    return !RegExp(
      r'\b(?:lip|lipstick|lip balm|tint|gloss|mascara|eyeliner|fragrance|perfume|retinol|retinoid|aha|bha|salicylic|glycolic|lactic|vitamin c|ascorbic|scrub|exfoliat)\b',
    ).hasMatch(text);
  }

  static bool _isEyeDropProduct(String text) {
    return RegExp(
      r'\b(?:eye\s*drop|eyedrop|artificial\s*tear|lubricat(?:ing|ion)\s*(?:eye\s*)?drop|ocular\s*lubricant)\b',
    ).hasMatch(text);
  }

  static bool _hasStrongActives(String text) {
    return _hasAny(text, [
      'retinol',
      'retinoid',
      'salicylic',
      'glycolic',
      'lactic',
      'aha',
      'bha',
      'benzoyl',
      'exfoliat',
      'scrub',
      'vitamin c',
      'ascorbic',
    ]);
  }

  static bool _hasAny(String text, List<String> terms) {
    return terms.any(text.contains);
  }
}

class RecycleService {
  static const _utarLat = 4.3380;
  static const _utarLng = 101.1430;

  static Future<List<RecyclePoint>> fetchRecyclePoints() async {
    const query = '''
[out:json][timeout:20];
(
  node["amenity"="recycling"](around:18000,4.3380,101.1430);
  way["amenity"="recycling"](around:18000,4.3380,101.1430);
  relation["amenity"="recycling"](around:18000,4.3380,101.1430);
);
out center 12;
''';
    try {
      final response = await http
          .post(
            Uri.parse('https://overpass-api.de/api/interpreter'),
            headers: {'Content-Type': 'text/plain'},
            body: query,
          )
          .timeout(const Duration(seconds: 12));
      if (response.statusCode != 200) {
        return fallbackPoints;
      }
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final elements = data['elements'] as List<dynamic>? ?? [];
      final points = elements.take(8).map((element) {
        final item = element as Map<String, dynamic>;
        final tags = (item['tags'] as Map?)?.cast<String, dynamic>() ?? {};
        final lat = (item['lat'] ?? item['center']?['lat'] ?? _utarLat)
            .toDouble();
        final lon = (item['lon'] ?? item['center']?['lon'] ?? _utarLng)
            .toDouble();
        final name = (tags['name'] ?? 'Community Recycling Point').toString();
        final address = [
          tags['addr:street'],
          tags['addr:city'],
          tags['addr:postcode'],
        ].whereType<String>().where((value) => value.isNotEmpty).join(', ');
        return RecyclePoint(
          id: item['id'].toString(),
          name: name,
          address: address.isEmpty
              ? 'OpenStreetMap recycling location near Kampar'
              : address,
          acceptedItems:
              'Plastic bottles, glass jars, paper, cosmetic containers if cleaned',
          openingHours:
              (tags['opening_hours'] ?? 'Check with venue before visiting')
                  .toString(),
          latitude: lat,
          longitude: lon,
          distanceKm: _distanceKm(_utarLat, _utarLng, lat, lon),
        );
      }).toList();
      return points.isEmpty ? fallbackPoints : points;
    } catch (_) {
      return fallbackPoints;
    }
  }

  static final fallbackPoints = [
    RecyclePoint(
      id: 'rp001',
      name: 'UTAR Eco Collection Corner',
      address: 'UTAR Campus Main Lobby, Kampar',
      acceptedItems: 'Plastic bottles, glass jars, cosmetic containers',
      openingHours: 'Mon-Fri, 9:00 AM - 5:00 PM',
      latitude: 4.3380,
      longitude: 101.1430,
      distanceKm: 0,
    ),
    RecyclePoint(
      id: 'rp002',
      name: 'Kampar Recycling Centre',
      address: 'Kampar Town Area',
      acceptedItems: 'Plastic packaging, paper, glass',
      openingHours: 'Daily, 10:00 AM - 6:00 PM',
      latitude: 4.3120,
      longitude: 101.1530,
      distanceKm: _distanceKm(_utarLat, _utarLng, 4.3120, 101.1530),
    ),
    RecyclePoint(
      id: 'rp003',
      name: 'Eco Beauty Drop-Off Point',
      address: 'Beauty retail counter, Kampar',
      acceptedItems: 'Empty beauty bottles, compact cases, clean jars',
      openingHours: 'Sat-Sun, 11:00 AM - 7:00 PM',
      latitude: 4.3290,
      longitude: 101.1480,
      distanceKm: _distanceKm(_utarLat, _utarLng, 4.3290, 101.1480),
    ),
  ];

  static double _distanceKm(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const earthRadiusKm = 6371.0;
    final dLat = _degToRad(lat2 - lat1);
    final dLon = _degToRad(lon2 - lon1);
    final a =
        sin(dLat / 2) * sin(dLat / 2) +
        cos(_degToRad(lat1)) *
            cos(_degToRad(lat2)) *
            sin(dLon / 2) *
            sin(dLon / 2);
    return earthRadiusKm * 2 * atan2(sqrt(a), sqrt(1 - a));
  }

  static double _degToRad(double deg) => deg * pi / 180;
}

class InventoryStats {
  InventoryStats({
    required this.total,
    required this.useSoon,
    required this.expired,
    required this.finished,
    required this.recycled,
    required this.points,
  });

  factory InventoryStats.from(
    List<BeautyProduct> products,
    List<EcoAction> actions,
    DateTime now,
  ) {
    return InventoryStats(
      total: products.length,
      useSoon: products
          .where((item) => item.resolvedStatus(now) == 'Use Soon')
          .length,
      expired: products
          .where((item) => item.resolvedStatus(now) == 'Expired')
          .length,
      finished: products
          .where((item) => item.resolvedStatus(now) == 'Finished')
          .length,
      recycled: products
          .where((item) => item.resolvedStatus(now) == 'Recycled')
          .length,
      points: actions.fold<int>(
        0,
        (total, action) => total + action.pointsEarned,
      ),
    );
  }

  final int total;
  final int useSoon;
  final int expired;
  final int finished;
  final int recycled;
  final int points;
}

class BadgeRule {
  BadgeRule(this.label, this.icon);

  final String label;
  final IconData icon;

  static List<BadgeRule> unlocked(
    List<BeautyProduct> products,
    List<EcoAction> actions,
    DateTime now,
  ) {
    final stats = InventoryStats.from(products, actions, now);
    final badges = <BadgeRule>[];
    if (stats.total >= 1) {
      badges.add(BadgeRule('First Product Tracked', Icons.spa_outlined));
    }
    if (stats.finished >= 1) {
      badges.add(
        BadgeRule('First Product Finished', Icons.check_circle_outline),
      );
    }
    if (stats.recycled >= 1) {
      badges.add(BadgeRule('First Container Recycled', Icons.recycling));
    }
    if (stats.recycled >= 5) {
      badges.add(
        BadgeRule('5 Containers Recycled', Icons.workspace_premium_outlined),
      );
    }
    if (actions.any((item) => item.actionType == 'No-buy challenge')) {
      badges.add(
        BadgeRule('7-Day No-Buy Challenge', Icons.calendar_month_outlined),
      );
    }
    if (stats.points >= 50) {
      badges.add(
        BadgeRule('Responsible Beauty Badge', Icons.verified_outlined),
      );
    }
    if (stats.points >= 100) {
      badges.add(BadgeRule('GlowCycle Champion', Icons.emoji_events_outlined));
    }
    return badges;
  }
}

String? requiredText(String? value) {
  if (value == null || value.trim().isEmpty) {
    return 'This field is required';
  }
  return null;
}

DateTime? parseOptionalDate(dynamic value) {
  if (value == null || value.toString().trim().isEmpty) {
    return null;
  }
  return DateTime.tryParse(value.toString());
}

List<String> parseIngredients(String value) {
  return value
      .split(RegExp(r'[,;\n]'))
      .map((item) => item.trim())
      .where((item) => item.isNotEmpty)
      .toList();
}

Uint8List? decodeProductImage(String value) {
  if (!value.startsWith('data:image')) {
    return null;
  }
  final commaIndex = value.indexOf(',');
  if (commaIndex == -1 || commaIndex == value.length - 1) {
    return null;
  }
  try {
    return base64Decode(value.substring(commaIndex + 1));
  } catch (_) {
    return null;
  }
}

Color statusColor(String status) {
  switch (status) {
    case 'Safe':
    case 'Unopened':
      return sage;
    case 'Use Soon':
      return amber;
    case 'Expired':
      return danger;
    case 'Finished':
      return blue;
    case 'Recycled':
      return sage;
    default:
      return ink;
  }
}

IconData categoryIcon(String category) {
  switch (category) {
    case 'Skincare':
      return Icons.water_drop_outlined;
    case 'Makeup':
      return Icons.brush_outlined;
    case 'Haircare':
      return Icons.air_outlined;
    case 'Bodycare':
      return Icons.spa_outlined;
    case 'Fragrance':
      return Icons.local_florist_outlined;
    default:
      return Icons.auto_awesome_outlined;
  }
}

List<Color> categoryPalette(String category) {
  switch (category) {
    case 'Skincare':
      return const [Color(0xFFE3F4EA), Color(0xFF8EC9A0)];
    case 'Makeup':
      return const [Color(0xFFFFDDE4), Color(0xFFD8788D)];
    case 'Haircare':
      return const [Color(0xFFFFEBC8), Color(0xFFD8A34E)];
    case 'Bodycare':
      return const [Color(0xFFE9E0FF), Color(0xFF9D87C7)];
    case 'Fragrance':
      return const [Color(0xFFE0F4FF), Color(0xFF7EB3CF)];
    default:
      return const [Color(0xFFF2ECE7), Color(0xFFB99182)];
  }
}

class AppHeader extends StatelessWidget {
  const AppHeader({super.key, required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 30,
            fontWeight: FontWeight.w900,
            color: ink,
            letterSpacing: 0,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          subtitle,
          style: TextStyle(color: ink.withValues(alpha: 0.64), height: 1.35),
        ),
      ],
    );
  }
}

class SectionTitle extends StatelessWidget {
  const SectionTitle(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: ink,
        fontWeight: FontWeight.w900,
        fontSize: 18,
      ),
    );
  }
}

class StatTile extends StatelessWidget {
  const StatTile({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: ink.withValues(alpha: 0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, color: color),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontSize: 24,
                  color: ink,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: ink.withValues(alpha: 0.62),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class BeautyShelfView extends StatelessWidget {
  const BeautyShelfView({
    super.key,
    required this.products,
    required this.onProductTap,
  });

  final List<BeautyProduct> products;
  final ValueChanged<BeautyProduct> onProductTap;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 700
            ? 4
            : constraints.maxWidth >= 520
            ? 3
            : 2;
        final spacing = 12.0;
        final tileWidth =
            (constraints.maxWidth - (spacing * (columns - 1))) / columns;
        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            for (final product in products)
              SizedBox(
                width: tileWidth,
                child: BentoProductCard(
                  product: product,
                  onTap: () => onProductTap(product),
                ),
              ),
          ],
        );
      },
    );
  }
}

class BentoProductCard extends StatefulWidget {
  const BentoProductCard({
    super.key,
    required this.product,
    required this.onTap,
  });

  final BeautyProduct product;
  final VoidCallback onTap;

  @override
  State<BentoProductCard> createState() => _BentoProductCardState();
}

class _BentoProductCardState extends State<BentoProductCard> {
  var _pressed = false;

  @override
  Widget build(BuildContext context) {
    final product = widget.product;
    final now = DateTime.now();
    final status = product.resolvedStatus(now);
    final statusAccent = statusColor(status);
    final totalDays = max(
      1,
      product.expiryDate.difference(product.openingDate).inDays,
    );
    final usedDays = now
        .difference(product.openingDate)
        .inDays
        .clamp(0, totalDays);
    final progress = usedDays / totalDays;

    return AnimatedScale(
      scale: _pressed ? 0.97 : 1,
      duration: const Duration(milliseconds: 130),
      curve: Curves.easeOut,
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: widget.onTap,
          onTapDown: (_) => setState(() => _pressed = true),
          onTapCancel: () => setState(() => _pressed = false),
          onTapUp: (_) => setState(() => _pressed = false),
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: ink.withValues(alpha: 0.06)),
              boxShadow: [
                BoxShadow(
                  color: statusAccent.withValues(alpha: 0.08),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AspectRatio(
                  aspectRatio: 1,
                  child: ProductImageMock(product: product, status: status),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        product.brand.toUpperCase(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: ink.withValues(alpha: 0.48),
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.6,
                        ),
                      ),
                    ),
                    Icon(
                      Icons.more_vert,
                      color: ink.withValues(alpha: 0.42),
                      size: 18,
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  product.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: ink,
                    fontWeight: FontWeight.w900,
                    fontSize: 14,
                    height: 1.15,
                  ),
                ),
                const SizedBox(height: 10),
                StatusPill(
                  label: productShelfLabel(product, status, now),
                  status: status,
                ),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    minHeight: 5,
                    value: progress,
                    color: statusAccent,
                    backgroundColor: surfaceHigh,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class ProductImageMock extends StatelessWidget {
  const ProductImageMock({
    super.key,
    required this.product,
    required this.status,
  });

  final BeautyProduct product;
  final String status;

  @override
  Widget build(BuildContext context) {
    final palette = categoryPalette(product.category);
    final accent = statusColor(status);
    final imageBytes = decodeProductImage(product.imagePath);
    if (imageBytes != null) {
      return Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(8)),
        child: Image.memory(
          imageBytes,
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
        ),
      );
    }
    if (product.imagePath.startsWith('http')) {
      return Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(8)),
        child: Image.network(
          product.imagePath,
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
          errorBuilder: (_, _, _) =>
              Icon(categoryIcon(product.category), color: accent, size: 40),
        ),
      );
    }
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            palette.first.withValues(alpha: 0.72),
            palette.last.withValues(alpha: 0.9),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            top: 12,
            right: 12,
            child: Icon(
              categoryIcon(product.category),
              color: Colors.white.withValues(alpha: 0.54),
              size: 24,
            ),
          ),
          Container(
            width: 50,
            height: 92,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.82),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.75),
                width: 2,
              ),
            ),
          ),
          Positioned(
            top: 33,
            child: Container(
              width: 30,
              height: 20,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(7),
              ),
            ),
          ),
          Positioned(
            bottom: 42,
            child: Container(
              width: 38,
              height: 24,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Icon(
                categoryIcon(product.category),
                color: accent,
                size: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class StatusPill extends StatelessWidget {
  const StatusPill({super.key, required this.label, required this.status});

  final String label;
  final String status;

  @override
  Widget build(BuildContext context) {
    final color = statusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

String productShelfLabel(BeautyProduct product, String status, DateTime now) {
  if (status == 'Use Soon') {
    return 'Expiring Soon';
  }
  if (status == 'Expired') {
    return 'Expired';
  }
  if (status == 'Finished') {
    return 'Finished';
  }
  if (status == 'Recycled') {
    return 'Recycled';
  }
  final days = product.daysRemaining(now);
  final months = (days / 30).ceil();
  if (months <= 1) {
    return '$days days left';
  }
  return '$months months left';
}

class ShelfProductTile extends StatefulWidget {
  const ShelfProductTile({
    super.key,
    required this.product,
    required this.onTap,
  });

  final BeautyProduct product;
  final VoidCallback onTap;

  @override
  State<ShelfProductTile> createState() => _ShelfProductTileState();
}

class _ShelfProductTileState extends State<ShelfProductTile> {
  var _pressed = false;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final status = widget.product.resolvedStatus(now);
    final days = widget.product.daysRemaining(now);
    final progress = (1 - (days / (widget.product.expiryMonths * 30))).clamp(
      0.0,
      1.0,
    );

    return AnimatedScale(
      scale: _pressed ? 0.96 : 1,
      duration: const Duration(milliseconds: 130),
      curve: Curves.easeOut,
      child: InkWell(
        onTap: widget.onTap,
        onTapDown: (_) => setState(() => _pressed = true),
        onTapCancel: () => setState(() => _pressed = false),
        onTapUp: (_) => setState(() => _pressed = false),
        borderRadius: BorderRadius.circular(8),
        child: Column(
          children: [
            Stack(
              alignment: Alignment.bottomCenter,
              children: [
                Container(
                  height: 18,
                  margin: const EdgeInsets.only(top: 126),
                  decoration: BoxDecoration(
                    color: cocoa.withValues(alpha: 0.18),
                    borderRadius: const BorderRadius.vertical(
                      bottom: Radius.circular(8),
                    ),
                  ),
                ),
                ProductBottleIllustration(
                  category: widget.product.category,
                  status: status,
                ),
              ],
            ),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(10, 9, 10, 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(8),
                ),
                border: Border.all(color: cocoa.withValues(alpha: 0.1)),
              ),
              child: Column(
                children: [
                  Text(
                    widget.product.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: ink,
                      fontWeight: FontWeight.w900,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    widget.product.brand,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: ink.withValues(alpha: 0.58),
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: LinearProgressIndicator(
                      minHeight: 5,
                      value: progress,
                      color: statusColor(status),
                      backgroundColor: blush,
                    ),
                  ),
                  const SizedBox(height: 8),
                  StatusBadge(status: status),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ProductBottleIllustration extends StatelessWidget {
  const ProductBottleIllustration({
    super.key,
    required this.category,
    required this.status,
  });

  final String category;
  final String status;

  @override
  Widget build(BuildContext context) {
    final palette = categoryPalette(category);
    final statusAccent = statusColor(status);
    return SizedBox(
      height: 144,
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          Container(
            width: 82,
            height: 112,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: palette,
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: ink.withValues(alpha: 0.18), width: 2),
              boxShadow: [
                BoxShadow(
                  color: palette.last.withValues(alpha: 0.24),
                  blurRadius: 18,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
          ),
          Positioned(
            bottom: 96,
            child: Container(
              width: 42,
              height: 34,
              decoration: BoxDecoration(
                color: palette.first,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: ink.withValues(alpha: 0.18),
                  width: 2,
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 50,
            child: Container(
              width: 52,
              height: 32,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.72),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Icon(
                categoryIcon(category),
                color: statusAccent,
                size: 22,
              ),
            ),
          ),
          Positioned(
            right: 30,
            bottom: 20,
            child: Container(
              width: 14,
              height: 14,
              decoration: BoxDecoration(
                color: statusAccent,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ProductShelfCard extends StatelessWidget {
  const ProductShelfCard({
    super.key,
    required this.product,
    required this.onTap,
    this.compact = false,
  });

  final BeautyProduct product;
  final VoidCallback onTap;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final status = product.resolvedStatus(now);
    final days = product.daysRemaining(now);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: cocoa.withValues(alpha: 0.08)),
        boxShadow: [
          BoxShadow(
            color: brandPink.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: EdgeInsets.all(compact ? 12 : 16),
          child: Row(
            children: [
              CategoryIcon(category: product.category),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        color: ink,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${product.brand} • ${product.category}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: ink.withValues(alpha: 0.62)),
                    ),
                    if (!compact) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Expires ${dateFormat.format(product.expiryDate)} • $days days left',
                        style: TextStyle(
                          color: ink.withValues(alpha: 0.62),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 10),
              StatusBadge(status: status),
            ],
          ),
        ),
      ),
    );
  }
}

class CategoryIcon extends StatelessWidget {
  const CategoryIcon({super.key, required this.category, this.size = 48});

  final String category;
  final double size;

  @override
  Widget build(BuildContext context) {
    final palette = categoryPalette(category);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: palette,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: palette.last.withValues(alpha: 0.18),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Icon(categoryIcon(category), color: Colors.white),
    );
  }
}

class StatusBadge extends StatelessWidget {
  const StatusBadge({super.key, required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final color = statusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w800,
          fontSize: 12,
        ),
      ),
    );
  }
}

class ActionChipButton extends StatelessWidget {
  const ActionChipButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: ink.withValues(alpha: 0.08)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: sage),
            const SizedBox(width: 7),
            Text(
              label,
              style: const TextStyle(color: ink, fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }
}

class DatePickerTile extends StatelessWidget {
  const DatePickerTile({
    super.key,
    required this.label,
    required this.date,
    required this.onPick,
  });

  final String label;
  final DateTime date;
  final ValueChanged<DateTime> onPick;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: date,
          firstDate: DateTime(2020),
          lastDate: DateTime(2035),
        );
        if (picked != null) {
          onPick(picked);
        }
      },
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: const Icon(Icons.calendar_today_outlined),
        ),
        child: Text(
          dateFormat.format(date),
          style: const TextStyle(color: ink),
        ),
      ),
    );
  }
}

class OptionalDatePickerTile extends StatelessWidget {
  const OptionalDatePickerTile({
    super.key,
    required this.label,
    required this.date,
    required this.onPick,
    required this.onClear,
  });

  final String label;
  final DateTime? date;
  final ValueChanged<DateTime> onPick;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: date ?? DateTime.now(),
          firstDate: DateTime(2018),
          lastDate: DateTime(2038),
        );
        if (picked != null) {
          onPick(picked);
        }
      },
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: const Icon(Icons.event_available_outlined),
          suffixIcon: date == null
              ? null
              : IconButton(
                  tooltip: 'Clear date',
                  onPressed: onClear,
                  icon: const Icon(Icons.close),
                ),
        ),
        child: Text(
          date == null ? 'Not detected' : dateFormat.format(date!),
          style: TextStyle(
            color: date == null ? ink.withValues(alpha: 0.52) : ink,
          ),
        ),
      ),
    );
  }
}

class DetailRow extends StatelessWidget {
  const DetailRow({super.key, required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 118,
            child: Text(
              label,
              style: TextStyle(
                color: ink.withValues(alpha: 0.58),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(color: ink)),
          ),
        ],
      ),
    );
  }
}

class InfoPill extends StatelessWidget {
  const InfoPill({super.key, required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: ink.withValues(alpha: 0.62)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(color: ink.withValues(alpha: 0.7), height: 1.3),
          ),
        ),
      ],
    );
  }
}

class BadgeChip extends StatelessWidget {
  const BadgeChip({super.key, required this.label, required this.icon});

  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: blush,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: brandPink),
          const SizedBox(width: 7),
          Text(
            label,
            style: const TextStyle(color: ink, fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}

class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: ink.withValues(alpha: 0.06)),
      ),
      child: Column(
        children: [
          Icon(icon, size: 38, color: sage),
          const SizedBox(height: 10),
          Text(
            title,
            style: const TextStyle(
              color: ink,
              fontWeight: FontWeight.w900,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(color: ink.withValues(alpha: 0.62), height: 1.35),
          ),
        ],
      ),
    );
  }
}
