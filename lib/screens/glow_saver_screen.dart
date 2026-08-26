import 'package:flutter/material.dart';

import '../core/constants.dart';
import '../models/beauty_product.dart';
import '../models/eco_action.dart';
import '../models/inventory_stats.dart';
import '../theme/app_colors.dart';
import '../widgets/info_widgets.dart';
import '../widgets/layout_widgets.dart';
import '../widgets/no_buy_challenge_card.dart';

/// The SDG 12 action tab. It turns shelf data into the next practical action
/// in a product's lifecycle instead of presenting points as pretend money.
class GlowSaverScreen extends StatelessWidget {
  const GlowSaverScreen({
    super.key,
    required this.products,
    required this.actions,
    required this.onStartNoBuyChallenge,
    required this.onClaimNoBuyChallenge,
    required this.onOpenRecycleMap,
    required this.onOpenWishlistCheck,
    required this.onOpenShelf,
    required this.onLogContainer,
  });

  final List<BeautyProduct> products;
  final List<EcoAction> actions;
  final Future<void> Function() onStartNoBuyChallenge;
  final Future<void> Function() onClaimNoBuyChallenge;
  final VoidCallback onOpenRecycleMap;
  final VoidCallback onOpenWishlistCheck;
  final VoidCallback onOpenShelf;
  final VoidCallback onLogContainer;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final stats = InventoryStats.from(products, actions, now);
    final useSoon =
        products
            .where((item) => item.resolvedStatus(now) == 'Use Soon')
            .toList()
          ..sort((a, b) => a.expiryDate.compareTo(b.expiryDate));
    final finished =
        products
            .where((item) => item.resolvedStatus(now) == 'Finished')
            .toList()
          ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
      children: [
        const AppHeader(title: 'Cycle Plan'),
        const SizedBox(height: 16),
        _LifecycleStrip(
          useSoon: useSoon.length,
          finished: finished.length,
          recycled: stats.recycled,
        ),
        const SizedBox(height: 16),
        _NextCircularAction(
          useSoon: useSoon,
          finished: finished,
          onOpenShelf: onOpenShelf,
          onLogContainer: onLogContainer,
          onOpenWishlistCheck: onOpenWishlistCheck,
        ),
        const SizedBox(height: 18),
        Row(
          children: [
            Expanded(
              child: StatTile(
                label: 'Use soon',
                value: stats.useSoon.toString(),
                icon: Icons.hourglass_top_outlined,
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
        // When the "next action" card above is already offering the wishlist
        // check (nothing is finished or expiring soon), repeating it here as
        // a second button just duplicates the same destination.
        if (finished.isEmpty && useSoon.isEmpty)
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: onOpenRecycleMap,
              icon: const Icon(Icons.map_outlined),
              label: const Text('Recycle map'),
            ),
          )
        else
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
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
        const SizedBox(height: 16),
        NoBuyChallengeCard(
          actions: actions,
          onStart: onStartNoBuyChallenge,
          onClaim: onClaimNoBuyChallenge,
        ),
      ],
    );
  }
}

class _LifecycleStrip extends StatelessWidget {
  const _LifecycleStrip({
    required this.useSoon,
    required this.finished,
    required this.recycled,
  });

  final int useSoon;
  final int finished;
  final int recycled;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: mint,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          _CycleStep(
            icon: Icons.spa_outlined,
            label: 'Use',
            value: useSoon.toString(),
            accent: amber,
          ),
          const _CycleConnector(),
          _CycleStep(
            icon: Icons.check_circle_outline,
            label: 'Finish',
            value: finished.toString(),
            accent: primary,
          ),
          const _CycleConnector(),
          _CycleStep(
            icon: Icons.recycling,
            label: 'Recycle',
            value: recycled.toString(),
            accent: tertiary,
          ),
        ],
      ),
    );
  }
}

class _CycleStep extends StatelessWidget {
  const _CycleStep({
    required this.icon,
    required this.label,
    required this.value,
    required this.accent,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: accent),
          const SizedBox(height: 5),
          Text(
            value,
            style: const TextStyle(
              color: ink,
              fontWeight: FontWeight.w900,
              fontSize: 20,
            ),
          ),
          Text(
            label,
            style: TextStyle(color: ink.withValues(alpha: 0.62), fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _CycleConnector extends StatelessWidget {
  const _CycleConnector();

  @override
  Widget build(BuildContext context) {
    return const Icon(Icons.arrow_forward, color: tertiary, size: 18);
  }
}

class _NextCircularAction extends StatelessWidget {
  const _NextCircularAction({
    required this.useSoon,
    required this.finished,
    required this.onOpenShelf,
    required this.onLogContainer,
    required this.onOpenWishlistCheck,
  });

  final List<BeautyProduct> useSoon;
  final List<BeautyProduct> finished;
  final VoidCallback onOpenShelf;
  final VoidCallback onLogContainer;
  final VoidCallback onOpenWishlistCheck;

  @override
  Widget build(BuildContext context) {
    late final IconData icon;
    late final Color tone;
    late final String title;
    late final String body;
    late final String action;
    late final VoidCallback onTap;

    if (finished.isNotEmpty) {
      icon = Icons.recycling;
      tone = tertiary;
      title = 'Container ready to recycle';
      body =
          '${finished.first.name} is marked finished. Log the handoff when you recycle it.';
      action = 'Log container';
      onTap = onLogContainer;
    } else if (useSoon.isNotEmpty) {
      final item = useSoon.first;
      icon = Icons.hourglass_top_outlined;
      tone = amber;
      title = 'Use this next';
      body = '${item.name} expires ${dateFormat.format(item.expiryDate)}.';
      action = 'Open shelf';
      onTap = onOpenShelf;
    } else {
      icon = Icons.shopping_bag_outlined;
      tone = primary;
      title = 'Pause before purchasing';
      body = 'Check your current shelf before adding another product.';
      action = 'Check shelf';
      onTap = onOpenWishlistCheck;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: tone.withValues(alpha: 0.28)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            backgroundColor: tone.withValues(alpha: 0.16),
            child: Icon(icon, color: tone),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: ink,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  body,
                  style: TextStyle(
                    color: ink.withValues(alpha: 0.68),
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 10),
                TextButton.icon(
                  onPressed: onTap,
                  icon: const Icon(Icons.arrow_forward, size: 17),
                  label: Text(action),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
