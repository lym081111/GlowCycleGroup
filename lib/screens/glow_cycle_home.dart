import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/eco_rewards.dart';
import '../models/app_user.dart';
import '../models/beauty_product.dart';
import '../models/eco_action.dart';
import '../models/no_buy_challenge.dart';
import '../services/glow_store.dart';
import '../theme/app_colors.dart';
import '../widgets/glow_bottom_nav.dart';
import '../widgets/glow_top_bar.dart';
import 'dashboard_screen.dart';
import 'eco_points_screen.dart';
import 'glow_assistant_screen.dart';
import 'glow_saver_screen.dart';
import 'inventory_screen.dart';
import 'log_container_screen.dart';
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

  /// True when [productId] has already been paid for [actionType].
  ///
  /// Status is editable, so without this a product could be set back to
  /// Opened and finished again for another award, indefinitely.
  bool _alreadyAwarded(String actionType, String productId) {
    return _actions.any(
      (item) =>
          item.actionType == actionType && item.relatedProductId == productId,
    );
  }

  void _showEcoMessage(String message) {
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  Future<void> _addProduct(BeautyProduct product) async {
    final now = DateTime.now();
    // Claiming a skipped purchase and then buying into that same category the
    // same day was not a skip, so the award is taken back.
    final claimedToday = _actions.any(
      (item) =>
          item.actionType == EcoActionTypes.avoidDuplicate &&
          item.category == product.category &&
          item.isSameDayAs(now),
    );
    final alreadyReversed = _actions.any(
      (item) =>
          item.actionType == EcoActionTypes.duplicateReversed &&
          item.category == product.category &&
          item.isSameDayAs(now),
    );
    final reverseSkip = claimedToday && !alreadyReversed;

    setState(() {
      _products = [..._products, product];
      _actions = [
        if (reverseSkip)
          EcoAction.created(
            actionType: EcoActionTypes.duplicateReversed,
            pointsEarned: -EcoRewards.avoidDuplicate,
            description:
                'Bought ${product.category} after skipping it today, so those points were returned.',
            category: product.category,
          ),
        EcoAction.created(
          actionType: EcoActionTypes.addProduct,
          pointsEarned: EcoRewards.addProduct,
          description: '${product.name} added to your beauty shelf.',
          relatedProductId: product.id,
          category: product.category,
        ),
        ..._actions,
      ];
    });
    if (reverseSkip) {
      _showEcoMessage(
        'Skipped-purchase points for ${product.category} were returned.',
      );
    }
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
    final paid = _alreadyAwarded(EcoActionTypes.finishProduct, product.id);
    final beforeExpiry = product.daysRemaining(now) >= 0;
    final updated = product.copyWith(status: 'Finished', updatedAt: now);
    setState(() {
      _products = _products
          .map((item) => item.id == product.id ? updated : item)
          .toList();
      if (!paid) {
        _actions = [
          EcoAction.created(
            actionType: EcoActionTypes.finishProduct,
            pointsEarned: beforeExpiry
                ? EcoRewards.finishBeforeExpiry
                : EcoRewards.finishAfterExpiry,
            description: beforeExpiry
                ? '${product.name} finished before expiry.'
                : '${product.name} finished and removed from waste risk.',
            relatedProductId: product.id,
            category: product.category,
          ),
          ..._actions,
        ];
      }
    });
    if (paid) {
      _showEcoMessage('${product.name} already earned its finishing points.');
    }
    await _persist();
  }

  Future<void> _markRecycled(BeautyProduct product) async {
    final now = DateTime.now();
    final paid = _alreadyAwarded(EcoActionTypes.recycleContainer, product.id);
    final updated = product.copyWith(status: 'Recycled', updatedAt: now);
    setState(() {
      _products = _products
          .map((item) => item.id == product.id ? updated : item)
          .toList();
      if (!paid) {
        _actions = [
          EcoAction.created(
            actionType: EcoActionTypes.recycleContainer,
            pointsEarned: EcoRewards.recycleContainer,
            description: '${product.name} container recycled responsibly.',
            relatedProductId: product.id,
            category: product.category,
          ),
          ..._actions,
        ];
      }
    });
    if (paid) {
      _showEcoMessage('${product.name} already earned its recycling points.');
    }
    await _persist();
  }

  /// One skipped purchase per category per day.
  ///
  /// The wishlist screen only disabled its own button, so leaving and
  /// returning let the same skip be claimed without limit.
  Future<void> _avoidDuplicate(String category) async {
    final now = DateTime.now();
    final claimedToday = _actions.any(
      (item) =>
          item.actionType == EcoActionTypes.avoidDuplicate &&
          item.category == category &&
          item.isSameDayAs(now),
    );
    if (claimedToday) {
      _showEcoMessage('You already logged a skipped $category purchase today.');
      return;
    }
    setState(() {
      _actions = [
        EcoAction.created(
          actionType: EcoActionTypes.avoidDuplicate,
          pointsEarned: EcoRewards.avoidDuplicate,
          description: 'Skipped a duplicate $category purchase.',
          category: category,
        ),
        ..._actions,
      ];
    });
    await _persist();
  }

  Future<void> _startNoBuyChallenge() async {
    setState(() {
      _actions = [
        EcoAction.created(
          actionType: EcoActionTypes.noBuyStarted,
          pointsEarned: 0,
          description:
              'Started a ${EcoRewards.noBuyChallengeDays}-day no-buy challenge.',
        ),
        ..._actions,
      ];
    });
    await _persist();
  }

  /// Pays out only once the challenge has actually run its course.
  Future<void> _claimNoBuyChallenge() async {
    final challenge = NoBuyChallenge.from(_actions, DateTime.now());
    if (!challenge.readyToClaim) {
      _showEcoMessage('This challenge is not finished yet.');
      return;
    }
    setState(() {
      _actions = [
        EcoAction.created(
          actionType: EcoActionTypes.noBuyCompleted,
          pointsEarned: EcoRewards.noBuyChallenge,
          description:
              'Completed a ${EcoRewards.noBuyChallengeDays}-day no-buy challenge.',
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
        onLogContainer: _openLogContainer,
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
        onStartNoBuyChallenge: _startNoBuyChallenge,
        onClaimNoBuyChallenge: _claimNoBuyChallenge,
        onOpenRecycleMap: _openRecycleMap,
        onOpenWishlistCheck: _openWishlistCheck,
      ),
    ];

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) {
          return;
        }
        // Back from an inner tab returns to Home first, so leaving the app is
        // always a deliberate second press rather than a surprise.
        if (_selectedIndex != 0) {
          setState(() => _selectedIndex = 0);
          return;
        }
        if (await _confirmExit()) {
          await SystemNavigator.pop();
        }
      },
      child: Scaffold(
        body: Container(
          color: surface,
          child: SafeArea(
            child: Column(
              children: [
                if (_selectedIndex != 2)
                  GlowTopBar(
                    user: widget.user,
                    onSearch: () => setState(() => _selectedIndex = 1),
                    onNotifications: _openEcoPoints,
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
      ),
    );
  }

  /// Confirms leaving the app, so a stray back press does not drop the user
  /// out mid-task.
  Future<bool> _confirmExit() async {
    final leave = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Leave GlowCycle?'),
        content: const Text(
          'Your shelf and eco actions are already saved. You can pick up '
          'where you left off next time.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Stay'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Leave'),
          ),
        ],
      ),
    );
    return leave ?? false;
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

  /// Step six of the proposal's user journey: reflect on points, badges, and
  /// recent sustainable actions. Reached from the top bar's eco impact icon.
  Future<void> _openEcoPoints() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => EcoPointsScreen(
          products: _products,
          actions: _actions,
          onStartNoBuyChallenge: _startNoBuyChallenge,
          onClaimNoBuyChallenge: _claimNoBuyChallenge,
        ),
      ),
    );
  }

  /// Steps four and five of the proposal's journey, finishing a product and
  /// recycling its container, without digging through the shelf.
  Future<void> _openLogContainer() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => LogContainerScreen(
          products: _products,
          actions: _actions,
          onFinished: _markFinished,
          onRecycled: _markRecycled,
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
