import 'package:flutter/material.dart';

import '../core/constants.dart';
import '../models/beauty_product.dart';
import '../models/eco_action.dart';
import '../models/inventory_stats.dart';
import '../theme/app_colors.dart';
import '../widgets/info_widgets.dart';
import '../widgets/layout_widgets.dart';
import '../widgets/no_buy_challenge_card.dart';
import '../widgets/product_cards.dart';

/// Saver tab: estimated savings, value at risk, and the products worth
/// finishing before buying anything new.
class GlowSaverScreen extends StatelessWidget {
  const GlowSaverScreen({
    super.key,
    required this.products,
    required this.actions,
    required this.onStartNoBuyChallenge,
    required this.onClaimNoBuyChallenge,
    required this.onOpenRecycleMap,
    required this.onOpenWishlistCheck,
  });

  final List<BeautyProduct> products;
  final List<EcoAction> actions;
  final Future<void> Function() onStartNoBuyChallenge;
  final Future<void> Function() onClaimNoBuyChallenge;
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
        const SizedBox(height: 12),
        NoBuyChallengeCard(
          actions: actions,
          onStart: onStartNoBuyChallenge,
          onClaim: onClaimNoBuyChallenge,
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

  /// Categories with three or more still-usable products, which is the
  /// signal used to warn against buying another one.
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
