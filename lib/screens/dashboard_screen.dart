import 'dart:math';

import 'package:flutter/material.dart';

import '../models/beauty_product.dart';
import '../models/eco_action.dart';
import '../models/inventory_stats.dart';
import '../theme/app_colors.dart';
import '../widgets/action_buttons.dart';
import '../widgets/dashboard_widgets.dart';
import '../widgets/layout_widgets.dart';

/// Home tab: headline metrics, an expiring-soon carousel, quick actions, and
/// the most recent eco activity.
class DashboardScreen extends StatelessWidget {
  const DashboardScreen({
    super.key,
    required this.products,
    required this.actions,
    required this.onAddTap,
    required this.onWishlistTap,
    required this.onLogContainer,
    required this.onNavigate,
  });

  final List<BeautyProduct> products;
  final List<EcoAction> actions;
  final VoidCallback onAddTap;
  final VoidCallback onWishlistTap;
  final VoidCallback onLogContainer;
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
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
      children: [
        DashboardWelcomeCard(stats: stats),
        const SizedBox(height: 20),
        SectionHeading(
          title: 'Expiring Soon',
          actionLabel: 'View All',
          onAction: () => onNavigate(1),
        ),
        const SizedBox(height: 12),
        SizedBox(
          // Sized to the compact card so the quick actions below stay on
          // screen without scrolling.
          height: 168,
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
        const SizedBox(height: 20),
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
              icon: Icons.search,
              label: 'Check Before Buying',
              color: secondary,
              onTap: onWishlistTap,
            ),
            const SizedBox(height: 8),
            QuickActionButton(
              icon: Icons.eco_outlined,
              label: 'Log Empty Container',
              color: tertiary,
              onTap: onLogContainer,
            ),
          ],
        ),
        const SizedBox(height: 20),
        const SectionHeading(title: 'Recent Activity'),
        const SizedBox(height: 12),
        ActivityPanel(actions: actions, activeProducts: activeProducts),
      ],
    );
  }
}
