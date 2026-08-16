import 'package:flutter/material.dart';

import '../core/constants.dart';
import '../models/badge_rule.dart';
import '../models/beauty_product.dart';
import '../models/eco_action.dart';
import '../models/inventory_stats.dart';
import '../theme/app_colors.dart';
import '../widgets/info_widgets.dart';
import '../widgets/layout_widgets.dart';
import '../widgets/no_buy_challenge_card.dart';

/// Eco dashboard: total points, unlocked badges, and recent sustainable
/// actions.
class EcoPointsScreen extends StatelessWidget {
  const EcoPointsScreen({
    super.key,
    required this.products,
    required this.actions,
    required this.onStartNoBuyChallenge,
    required this.onClaimNoBuyChallenge,
  });

  final List<BeautyProduct> products;
  final List<EcoAction> actions;
  final Future<void> Function() onStartNoBuyChallenge;
  final Future<void> Function() onClaimNoBuyChallenge;

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
          const SizedBox(height: 12),
          _WasteAvoidanceTile(stats: stats),
          const SizedBox(height: 18),
          NoBuyChallengeCard(
            actions: actions,
            onStart: onStartNoBuyChallenge,
            onClaim: onClaimNoBuyChallenge,
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
                        action.pointsEarned >= 0
                            ? '+${action.pointsEarned}'
                            : '${action.pointsEarned}',
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

/// Share of settled products that were used up rather than left to expire.
///
/// Points can only ever rise, so they cannot show failure. This is derived
/// from product outcomes, which means no amount of tapping can inflate it.
class _WasteAvoidanceTile extends StatelessWidget {
  const _WasteAvoidanceTile({required this.stats});

  final InventoryStats stats;

  @override
  Widget build(BuildContext context) {
    final rate = stats.wasteAvoidanceRate;
    final hasData = rate != null;
    final percent = hasData ? (rate * 100).round() : 0;
    final tone = !hasData
        ? ink.withValues(alpha: 0.5)
        : percent >= 70
        ? sage
        : percent >= 40
        ? amber
        : danger;

    return Container(
      padding: const EdgeInsets.all(16),
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
              Icon(Icons.trending_up, color: tone),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Waste avoided',
                  style: TextStyle(color: ink, fontWeight: FontWeight.w900),
                ),
              ),
              Text(
                hasData ? '$percent%' : '--',
                style: TextStyle(
                  color: tone,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              minHeight: 6,
              value: hasData ? rate : 0,
              color: tone,
              backgroundColor: surfaceHigh,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            hasData
                ? 'You used up or recycled ${stats.finished + stats.recycled} of '
                      'the ${stats.settled} products that reached the end of their '
                      'life. ${stats.expired} expired.'
                : 'Finish or recycle a product to start tracking how much waste you avoid.',
            style: TextStyle(
              color: ink.withValues(alpha: 0.64),
              fontSize: 12,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }
}
