import 'package:flutter/material.dart';

import 'beauty_product.dart';
import 'eco_action.dart';
import 'inventory_stats.dart';

/// An achievement badge and the milestone that unlocks it.
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
