import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Large screen title with a supporting sentence.
class AppHeader extends StatelessWidget {
  const AppHeader({super.key, required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 30,
            fontWeight: FontWeight.w900,
            color: ink,
            letterSpacing: 0,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          subtitle,
          style: TextStyle(color: ink.withValues(alpha: 0.64), height: 1.35),
        ),
      ],
    );
  }
}

/// Plain section label.
class SectionTitle extends StatelessWidget {
  const SectionTitle(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: ink,
        fontWeight: FontWeight.w900,
        fontSize: 18,
      ),
    );
  }
}

/// Section label with an optional trailing action button.
class SectionHeading extends StatelessWidget {
  const SectionHeading({
    super.key,
    required this.title,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: ink,
            fontSize: 22,
            fontWeight: FontWeight.w900,
            letterSpacing: 0,
          ),
        ),
        if (actionLabel != null)
          TextButton(onPressed: onAction, child: Text(actionLabel!)),
      ],
    );
  }
}

/// Placeholder card shown when a list has nothing to display.
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: ink.withValues(alpha: 0.06)),
      ),
      child: Column(
        children: [
          Icon(icon, size: 38, color: sage),
          const SizedBox(height: 10),
          Text(
            title,
            style: const TextStyle(
              color: ink,
              fontWeight: FontWeight.w900,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(color: ink.withValues(alpha: 0.62), height: 1.35),
          ),
        ],
      ),
    );
  }
}
