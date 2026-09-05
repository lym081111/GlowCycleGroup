import 'dart:math';

import 'package:flutter/material.dart';

import '../core/constants.dart';
import '../models/beauty_product.dart';
import '../models/eco_action.dart';
import '../models/inventory_stats.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import 'product_cards.dart';

/// Gradient greeting card carrying the two headline shelf metrics.
class DashboardWelcomeCard extends StatelessWidget {
  const DashboardWelcomeCard({
    super.key,
    required this.stats,
    required this.userName,
  });

  final InventoryStats stats;
  final String userName;

  @override
  Widget build(BuildContext context) {
    final greetingName = userName.isEmpty
        ? 'there'
        : userName[0].toUpperCase() + userName.substring(1);
    return Container(
      // Kept tight so the three quick actions clear the fold.
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const RadialGradient(
          center: Alignment.topLeft,
          radius: 1.35,
          colors: [primaryContainer, Color(0xFFFFF5F0), Color(0xFFD0E7E1)],
          stops: [0, 0.58, 1],
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: outlineVariant.withValues(alpha: 0.34)),
        boxShadow: [
          BoxShadow(
            color: primary.withValues(alpha: 0.08),
            blurRadius: 22,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Hello, $greetingName!',
            style: const TextStyle(
              color: Color(0xFF153B1C),
              fontSize: 22,
              fontWeight: FontWeight.w900,
              letterSpacing: 0,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            'Your mindful routine is flourishing.',
            style: TextStyle(color: ink.withValues(alpha: 0.66), fontSize: 13),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: DashboardMetricTile(
                  label: 'Expiring Soon',
                  value: stats.useSoon.toString(),
                  suffix: 'items',
                  color: primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DashboardMetricTile(
                  label: 'Recycled',
                  value: stats.recycled.toString(),
                  icon: Icons.recycling,
                  color: tertiary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Single translucent metric inside [DashboardWelcomeCard].
class DashboardMetricTile extends StatelessWidget {
  const DashboardMetricTile({
    super.key,
    required this.label,
    required this.value,
    required this.color,
    this.suffix,
    this.icon,
  });

  final String label;
  final String value;
  final String? suffix;
  final IconData? icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.62),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.48)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Flexible(
                child: Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: ink,
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0,
                    height: 1,
                  ),
                ),
              ),
              if (suffix != null) ...[
                const SizedBox(width: 4),
                Padding(
                  padding: const EdgeInsets.only(bottom: 2),
                  child: Text(
                    suffix!,
                    style: TextStyle(color: ink.withValues(alpha: 0.58)),
                  ),
                ),
              ],
              if (icon != null) ...[
                const SizedBox(width: 4),
                Padding(
                  padding: const EdgeInsets.only(bottom: 3),
                  child: Icon(icon, color: color, size: 20),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

/// Horizontal card in the "Expiring Soon" carousel.
class DashboardExpiryCard extends StatelessWidget {
  const DashboardExpiryCard({super.key, required this.product});

  final BeautyProduct product;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final status = product.resolvedStatus(now);
    final days = product.daysRemaining(now);
    final totalDays = max(
      1,
      product.expiryDate.difference(product.openingDate).inDays,
    );
    final usedDays = now
        .difference(product.openingDate)
        .inDays
        .clamp(0, totalDays);
    final progress = usedDays / totalDays;
    final color = days <= 7 || status == 'Expired'
        ? danger
        : statusColor(status);

    return Container(
      width: 158,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: outlineVariant.withValues(alpha: 0.24)),
        boxShadow: [
          BoxShadow(
            color: primary.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 88,
            width: double.infinity,
            child: Stack(
              fit: StackFit.expand,
              children: [
                ProductImageMock(product: product, status: status),
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      status == 'Expired' ? 'Expired' : '$days Days',
                      style: TextStyle(
                        color: color,
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: ink,
                    fontWeight: FontWeight.w900,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  product.brand,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: ink.withValues(alpha: 0.58),
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    minHeight: 5,
                    value: progress,
                    color: color,
                    backgroundColor: surfaceHighest,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Shown in place of the carousel when nothing needs attention.
class CalmShelfCard extends StatelessWidget {
  const CalmShelfCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: outlineVariant.withValues(alpha: 0.22)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.self_improvement, color: primary, size: 28),
          const SizedBox(height: 8),
          const Text(
            'No urgent products',
            style: TextStyle(color: ink, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 4),
          Text(
            'Your shelf is calm today.',
            textAlign: TextAlign.center,
            style: TextStyle(color: ink.withValues(alpha: 0.62)),
          ),
        ],
      ),
    );
  }
}

/// Recent eco actions, or a prompt to add a first product.
class ActivityPanel extends StatelessWidget {
  const ActivityPanel({
    super.key,
    required this.actions,
    required this.activeProducts,
  });

  final List<EcoAction> actions;
  final List<BeautyProduct> activeProducts;

  @override
  Widget build(BuildContext context) {
    final displayActions = actions.take(3).toList();
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: outlineVariant.withValues(alpha: 0.2)),
      ),
      clipBehavior: Clip.antiAlias,
      child: displayActions.isEmpty
          ? Padding(
              padding: const EdgeInsets.all(18),
              child: Text(
                activeProducts.isEmpty
                    ? 'Add your first product to begin tracking your beauty cycle.'
                    : 'Your activity timeline will appear here.',
                style: TextStyle(color: ink.withValues(alpha: 0.62)),
              ),
            )
          : Column(
              children: [
                for (var i = 0; i < displayActions.length; i++) ...[
                  ActivityRow(action: displayActions[i]),
                  if (i != displayActions.length - 1)
                    Divider(
                      height: 1,
                      color: outlineVariant.withValues(alpha: 0.2),
                    ),
                ],
              ],
            ),
    );
  }
}

/// One row inside [ActivityPanel].
class ActivityRow extends StatelessWidget {
  const ActivityRow({super.key, required this.action});

  final EcoAction action;

  @override
  Widget build(BuildContext context) {
    final icon = action.actionType.contains('Recycle')
        ? Icons.eco
        : action.actionType.contains('Add')
        ? Icons.add
        : Icons.check_circle;
    final color = action.actionType.contains('Recycle')
        ? tertiary
        : action.actionType.contains('Add')
        ? secondary
        : primary;
    return Padding(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.18),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  action.description,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: ink,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  dateFormat.format(action.date),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: ink.withValues(alpha: 0.58),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
