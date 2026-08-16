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

/// Eco dashboard: total points, waste avoided, the no-buy challenge, and a
/// shared slot holding either badges or recent actions.
///
/// The two used to stack, making the screen long and burying the history.
/// They now occupy one place, chosen by the selector or by swiping.
class EcoPointsScreen extends StatefulWidget {
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
  State<EcoPointsScreen> createState() => _EcoPointsScreenState();
}

class _EcoPointsScreenState extends State<EcoPointsScreen> {
  /// 0 = recent eco actions, 1 = badges. History leads because it changes
  /// every time the user does something, while badges rarely move.
  var _panel = 0;

  void _select(int index) {
    if (index != _panel) {
      setState(() => _panel = index);
    }
  }

  /// Swiping the panel moves between the two, matching the selector.
  void _onSwipe(DragEndDetails details) {
    final velocity = details.primaryVelocity;
    if (velocity == null) {
      return;
    }
    if (velocity < -250) {
      _select(1);
    } else if (velocity > 250) {
      _select(0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final stats = InventoryStats.from(widget.products, widget.actions, now);
    final badges = BadgeRule.unlocked(widget.products, widget.actions, now);

    return Scaffold(
      appBar: AppBar(title: const Text('Eco impact')),
      body: ListView(
        padding: EdgeInsets.fromLTRB(
          20,
          12,
          20,
          24 + MediaQuery.viewPaddingOf(context).bottom,
        ),
        children: [
          const AppHeader(
            title: 'Eco points',
            subtitle: 'Small sustainable actions, visible progress.',
          ),
          const SizedBox(height: 16),
          _PointsBanner(points: stats.points),
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
            actions: widget.actions,
            onStart: widget.onStartNoBuyChallenge,
            onClaim: widget.onClaimNoBuyChallenge,
          ),
          const SizedBox(height: 18),
          _PanelSelector(selected: _panel, onSelected: _select),
          const SizedBox(height: 14),
          GestureDetector(
            onHorizontalDragEnd: _onSwipe,
            child: AnimatedSize(
              duration: const Duration(milliseconds: 240),
              curve: Curves.easeOut,
              alignment: Alignment.topCenter,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 240),
                switchInCurve: Curves.easeOut,
                switchOutCurve: Curves.easeIn,
                transitionBuilder: (child, animation) {
                  // Slide in from the side the selection moved towards.
                  final entering = child.key == ValueKey(_panel);
                  final direction = _panel == 1 ? 1.0 : -1.0;
                  final offset = entering ? direction : -direction;
                  return FadeTransition(
                    opacity: animation,
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: Offset(offset * 0.12, 0),
                        end: Offset.zero,
                      ).animate(animation),
                      child: child,
                    ),
                  );
                },
                child: _panel == 0
                    ? _ActionsPanel(
                        key: const ValueKey(0),
                        actions: widget.actions,
                      )
                    : _BadgesPanel(key: const ValueKey(1), badges: badges),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Two-way chooser for the shared panel slot.
class _PanelSelector extends StatelessWidget {
  const _PanelSelector({required this.selected, required this.onSelected});

  final int selected;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: surfaceHigh,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        children: [
          _SegmentButton(
            label: 'Recent eco actions',
            active: selected == 0,
            onTap: () => onSelected(0),
          ),
          _SegmentButton(
            label: 'Badges unlocked',
            active: selected == 1,
            onTap: () => onSelected(1),
          ),
        ],
      ),
    );
  }
}

class _SegmentButton extends StatelessWidget {
  const _SegmentButton({
    required this.label,
    required this.active,
    required this.onTap,
  });

  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: active ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: active ? primary : ink.withValues(alpha: 0.6),
              fontWeight: active ? FontWeight.w900 : FontWeight.w700,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }
}

class _BadgesPanel extends StatelessWidget {
  const _BadgesPanel({super.key, required this.badges});

  final List<BadgeRule> badges;

  @override
  Widget build(BuildContext context) {
    if (badges.isEmpty) {
      return const EmptyState(
        icon: Icons.emoji_events_outlined,
        title: 'No badges yet',
        message: 'Add, finish, or recycle products to unlock achievements.',
      );
    }
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: badges
          .map((badge) => BadgeChip(label: badge.label, icon: badge.icon))
          .toList(),
    );
  }
}

class _ActionsPanel extends StatelessWidget {
  const _ActionsPanel({super.key, required this.actions});

  final List<EcoAction> actions;

  @override
  Widget build(BuildContext context) {
    if (actions.isEmpty) {
      return const EmptyState(
        icon: Icons.eco_outlined,
        title: 'No actions yet',
        message: 'Your responsible beauty actions will appear here.',
      );
    }
    return Column(
      children: actions
          .take(12)
          .map(
            (action) => ListTile(
              contentPadding: EdgeInsets.zero,
              leading: CircleAvatar(
                backgroundColor: action.pointsEarned < 0 ? blush : mint,
                child: Text(
                  action.pointsEarned >= 0
                      ? '+${action.pointsEarned}'
                      : '${action.pointsEarned}',
                  style: TextStyle(
                    color: action.pointsEarned < 0 ? brandPink : ink,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              title: Text(
                action.actionType,
                style: const TextStyle(fontWeight: FontWeight.w800, color: ink),
              ),
              subtitle: Text(
                '${action.description}\n${dateFormat.format(action.date)}',
              ),
              isThreeLine: true,
            ),
          )
          .toList(),
    );
  }
}

class _PointsBanner extends StatelessWidget {
  const _PointsBanner({required this.points});

  final int points;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: ink,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Icon(Icons.auto_awesome, color: Color(0xFFFFD977), size: 42),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$points',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 38,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  'total eco points',
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.72)),
                ),
              ],
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
