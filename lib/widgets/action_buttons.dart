import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Full-width dashboard action row with a leading icon and chevron.
class QuickActionButton extends StatelessWidget {
  const QuickActionButton({
    super.key,
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
    this.filled = false,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: filled ? color : surfaceLow,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: filled
                ? null
                : Border.all(color: outlineVariant.withValues(alpha: 0.36)),
          ),
          child: Row(
            children: [
              Icon(icon, color: filled ? Colors.white : color),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    color: filled ? Colors.white : ink,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: filled ? Colors.white : ink.withValues(alpha: 0.58),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Pill-shaped secondary action.
///
/// Currently unreferenced; kept for the planned inventory quick actions.
class ActionChipButton extends StatelessWidget {
  const ActionChipButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: ink.withValues(alpha: 0.08)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: sage),
            const SizedBox(width: 7),
            Text(
              label,
              style: const TextStyle(color: ink, fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }
}
