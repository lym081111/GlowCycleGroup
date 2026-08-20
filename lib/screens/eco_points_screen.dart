import 'package:flutter/material.dart';

import '../core/constants.dart';
import '../models/beauty_product.dart';
import '../models/eco_action.dart';
import '../models/inventory_stats.dart';
import '../theme/app_colors.dart';
import '../widgets/info_widgets.dart';
import '../widgets/layout_widgets.dart';

/// A traceable log of circular consumption. The old point total was removed:
/// without a partner reward it implied value that GlowCycle cannot deliver.
///
/// This screen is the reflect step: it reviews what already happened. The
/// no-buy challenge (starting or claiming it) lives only on the Cycle Plan
/// tab, which is the act step, so the same prompt doesn't appear twice.
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
          const AppHeader(title: 'Circular impact'),
          const SizedBox(height: 16),
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
    );
  }
}
