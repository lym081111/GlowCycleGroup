import 'package:flutter/material.dart';

import '../core/constants.dart';
import '../core/eco_rewards.dart';
import '../models/badge_rule.dart';
import '../models/beauty_product.dart';
import '../models/eco_action.dart';
import '../models/inventory_stats.dart';
import '../theme/app_colors.dart';
import '../widgets/info_widgets.dart';
import '../widgets/layout_widgets.dart';

/// Eco points, achievements, and a traceable log of circular consumption.
class EcoPointsScreen extends StatelessWidget {
  const EcoPointsScreen({
    super.key,
    required this.products,
    required this.actions,
  });

  final List<BeautyProduct> products;
  final List<EcoAction> actions;

  @override
  Widget build(BuildContext context) {
    final stats = InventoryStats.from(products, actions, DateTime.now());
    final badges = BadgeRule.unlocked(products, actions, DateTime.now());
    final rate = stats.wasteAvoidanceRate;
    final percent = rate == null ? null : (rate * 100).round();

    return Scaffold(
      appBar: AppBar(title: const Text('Impact records')),
      body: ListView(
        padding: EdgeInsets.fromLTRB(
          20,
          12,
          20,
          24 + MediaQuery.viewPaddingOf(context).bottom,
        ),
        children: [
          const AppHeader(title: 'Eco points'),
          const SizedBox(height: 16),
          _PointsSummary(points: stats.points),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: StatTile(
                  label: 'Finished',
                  value: stats.finished.toString(),
                  icon: Icons.check_circle_outline,
                  color: primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: StatTile(
                  label: 'Recycled',
                  value: stats.recycled.toString(),
                  icon: Icons.recycling,
                  color: tertiary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
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
                    const Icon(Icons.autorenew, color: primary),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text(
                        'Lifecycle completion',
                        style: TextStyle(
                          color: ink,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    Text(
                      percent == null ? '--' : '$percent%',
                      style: const TextStyle(
                        color: primary,
                        fontWeight: FontWeight.w900,
                        fontSize: 22,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: rate ?? 0,
                    minHeight: 7,
                    color: primary,
                    backgroundColor: surfaceHigh,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  percent == null
                      ? 'Complete a product lifecycle to begin tracking.'
                      : '${stats.finished + stats.recycled} products were finished or recycled; ${stats.expired} expired.',
                  style: TextStyle(
                    color: ink.withValues(alpha: 0.64),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const SectionTitle('How points are earned'),
          const SizedBox(height: 8),
          const _PointRulesCard(),
          const SizedBox(height: 20),
          const SectionTitle('Badges unlocked'),
          const SizedBox(height: 8),
          if (badges.isEmpty)
            const EmptyState(
              icon: Icons.workspace_premium_outlined,
              title: 'No badges yet',
              message: 'Complete sustainable actions to unlock badges.',
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final badge in badges)
                  Chip(
                    avatar: Icon(badge.icon, color: primary, size: 18),
                    label: Text(badge.label),
                    backgroundColor: primaryContainer,
                    side: BorderSide.none,
                  ),
              ],
            ),
          const SizedBox(height: 20),
          const SectionTitle('Recent actions'),
          const SizedBox(height: 8),
          if (actions.isEmpty)
            const EmptyState(
              icon: Icons.history_outlined,
              title: 'No actions yet',
              message: 'Your product and recycling actions will appear here.',
            )
          else
            ...actions.map((action) => _ActionRow(action: action)),
        ],
      ),
    );
  }
}

class _PointsSummary extends StatelessWidget {
  const _PointsSummary({required this.points});

  final int points;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: primary,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.16),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.eco_outlined, color: Colors.white),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Text(
              'Total eco points',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          Text(
            points.toString(),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 34,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _PointRulesCard extends StatelessWidget {
  const _PointRulesCard();

  @override
  Widget build(BuildContext context) {
    const rules = [
      ('Add a product', EcoRewards.addProduct),
      ('Finish before expiry', EcoRewards.finishBeforeExpiry),
      ('Recycle a container', EcoRewards.recycleContainer),
      ('Avoid a duplicate purchase', EcoRewards.avoidDuplicate),
      ('Complete the 7-day no-buy challenge', EcoRewards.noBuyChallenge),
    ];
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: ink.withValues(alpha: 0.06)),
      ),
      child: Column(
        children: [
          for (var index = 0; index < rules.length; index++) ...[
            ListTile(
              dense: true,
              leading: const Icon(Icons.eco_outlined, color: primary),
              title: Text(
                rules[index].$1,
                style: const TextStyle(color: ink, fontWeight: FontWeight.w700),
              ),
              trailing: Text(
                '+${rules[index].$2}',
                style: const TextStyle(
                  color: primary,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            if (index != rules.length - 1) const Divider(height: 1, indent: 56),
          ],
        ],
      ),
    );
  }
}

class _ActionRow extends StatelessWidget {
  const _ActionRow({required this.action});

  final EcoAction action;

  @override
  Widget build(BuildContext context) {
    final type = action.actionType.toLowerCase();
    final isRecycle = type.contains('recycle');
    final isFinish = type.contains('finish');
    final color = isRecycle
        ? tertiary
        : isFinish
        ? primary
        : secondary;
    final icon = isRecycle
        ? Icons.recycling
        : isFinish
        ? Icons.check_circle_outline
        : Icons.eco_outlined;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        backgroundColor: color.withValues(alpha: 0.14),
        child: Icon(icon, color: color),
      ),
      title: Text(
        action.description,
        style: const TextStyle(color: ink, fontWeight: FontWeight.w800),
      ),
      subtitle: Text(dateFormat.format(action.date)),
      trailing: Text(
        action.pointsEarned > 0
            ? '+${action.pointsEarned} pts'
            : '${action.pointsEarned} pts',
        style: TextStyle(
          color: action.pointsEarned > 0 ? primary : secondary,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}
