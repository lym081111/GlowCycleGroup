import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Rounded badge showing the resolved lifecycle status verbatim.
class StatusBadge extends StatelessWidget {
  const StatusBadge({super.key, required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final color = statusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w800,
          fontSize: 12,
        ),
      ),
    );
  }
}

/// Compact status chip that carries a custom label, such as "3 months left".
class StatusPill extends StatelessWidget {
  const StatusPill({super.key, required this.label, required this.status});

  final String label;
  final String status;

  @override
  Widget build(BuildContext context) {
    final color = statusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

/// Gradient tile carrying the category's icon.
class CategoryIcon extends StatelessWidget {
  const CategoryIcon({super.key, required this.category, this.size = 48});

  final String category;
  final double size;

  @override
  Widget build(BuildContext context) {
    final palette = categoryPalette(category);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: palette,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: palette.last.withValues(alpha: 0.18),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Icon(categoryIcon(category), color: Colors.white),
    );
  }
}
