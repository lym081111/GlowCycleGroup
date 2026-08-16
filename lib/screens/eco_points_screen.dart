import 'package:flutter/material.dart';

import '../core/constants.dart';
import '../models/badge_rule.dart';
import '../models/beauty_product.dart';
import '../models/eco_action.dart';
import '../models/inventory_stats.dart';
import '../theme/app_colors.dart';
import '../widgets/info_widgets.dart';
import '../widgets/layout_widgets.dart';

/// Eco dashboard: total points, unlocked badges, and recent sustainable
/// actions.
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
    return Scaffold(
      appBar: AppBar(title: const Text('Eco impact')),
      body: ListView(
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
            // The handler awards 60; the old "+20" label contradicted both it
            // and the Glow Saver button that calls the same code.
            label: const Text('Complete no-buy challenge +60'),
          ),
          const SizedBox(height: 18),
          const SectionTitle('Badges unlocked'),
          const SizedBox(height: 10),
          if (badges.isEmpty)
            const EmptyState(
              icon: Icons.emoji_events_outlined,
              title: 'No badges yet',
              message:
                  'Add, finish, or recycle products to unlock achievements.',
            )
          else
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: badges
                  .map(
                    (badge) => BadgeChip(label: badge.label, icon: badge.icon),
                  )
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
      ),
    );
  }
}
