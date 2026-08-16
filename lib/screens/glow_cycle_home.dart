import 'package:flutter/material.dart';

import '../models/app_user.dart';
import '../models/beauty_product.dart';
import '../models/eco_action.dart';
import '../services/glow_store.dart';
import '../theme/app_colors.dart';
import '../widgets/glow_bottom_nav.dart';
import '../widgets/glow_top_bar.dart';
import 'dashboard_screen.dart';
import 'glow_assistant_screen.dart';
import 'glow_saver_screen.dart';
import 'inventory_screen.dart';
import 'product_detail_screen.dart';
import 'product_form_screen.dart';
import 'recycle_screen.dart';
import 'wishlist_screen.dart';

/// The signed-in shell.
///
/// Owns the product and eco-action lists for the whole session, persists
/// every mutation through [GlowStore], and swaps the five bottom-nav tabs.
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
    try {
      final data = await _store.load();
      if (!mounted) {
        return;
      }
      setState(() {
        _products = data.products;
        _actions = data.actions;
        _loading = false;
      });
    } catch (error) {
      // Whatever went wrong, clear the spinner: a stuck loading indicator
      // leaves the user with no way forward and no idea why.
      if (!mounted) {
        return;
      }
      setState(() => _loading = false);
      _reportLoadIssue('Could not load your shelf: $error');
      return;
    }
    final warning = _store.lastLoadError;
    if (warning != null) {
      _reportLoadIssue(warning);
    }
  }

  void _reportLoadIssue(String message) {
    if (!mounted) {
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 6),
        ),
      );
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
