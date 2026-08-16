import 'package:flutter/material.dart';

import '../core/eco_rewards.dart';
import '../models/eco_action.dart';
import '../models/no_buy_challenge.dart';
import '../theme/app_colors.dart';

/// Runs the no-buy challenge: start it, watch the days accumulate, claim it
/// once it has genuinely run for [EcoRewards.noBuyChallengeDays].
class NoBuyChallengeCard extends StatelessWidget {
  const NoBuyChallengeCard({
    super.key,
    required this.actions,
    required this.onStart,
    required this.onClaim,
  });

  final List<EcoAction> actions;
  final Future<void> Function() onStart;
  final Future<void> Function() onClaim;

  @override
  Widget build(BuildContext context) {
    final challenge = NoBuyChallenge.from(actions, DateTime.now());
    final total = EcoRewards.noBuyChallengeDays;

    if (challenge.broken) {
      return _Panel(
        icon: Icons.refresh,
        tone: blush,
        accent: brandPink,
        title: 'Challenge ended early',
        body: challenge.brokenBy == null
            ? 'A new product was added before the $total days were up.'
            : 'Added before the $total days were up: ${challenge.brokenBy}',
        action: OutlinedButton.icon(
          onPressed: onStart,
          icon: const Icon(Icons.play_arrow_outlined),
          label: Text('Start another $total-day challenge'),
        ),
      );
    }

    if (!challenge.isActive) {
      return _Panel(
        icon: Icons.calendar_month_outlined,
        tone: mint,
        accent: primary,
        title: '$total-day no-buy challenge',
        body:
            'Add no new product for $total days to earn '
            '${EcoRewards.noBuyChallenge} eco points.',
        action: FilledButton.icon(
          onPressed: onStart,
          icon: const Icon(Icons.play_arrow_outlined),
          label: const Text('Start challenge'),
        ),
      );
    }

    final progress = (challenge.daysElapsed / total).clamp(0.0, 1.0);
    return _Panel(
      icon: challenge.readyToClaim
          ? Icons.emoji_events_outlined
          : Icons.hourglass_bottom,
      tone: mint,
      accent: primary,
      title: challenge.readyToClaim
          ? 'Challenge complete'
          : 'Day ${challenge.daysElapsed} of $total',
      body: challenge.readyToClaim
          ? 'You went $total days without a new product.'
          : '${challenge.daysRemaining} day(s) to go. Adding a product ends it early.',
      progress: challenge.readyToClaim ? null : progress,
      action: FilledButton.icon(
        onPressed: challenge.readyToClaim ? onClaim : null,
        icon: const Icon(Icons.eco_outlined),
        label: Text('Claim +${EcoRewards.noBuyChallenge}'),
      ),
    );
  }
}

class _Panel extends StatelessWidget {
  const _Panel({
    required this.icon,
    required this.tone,
    required this.accent,
    required this.title,
    required this.body,
    required this.action,
    this.progress,
  });

  final IconData icon;
  final Color tone;
  final Color accent;
  final String title;
  final String body;
  final Widget action;
  final double? progress;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: tone,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: accent),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: ink,
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            body,
            style: TextStyle(color: ink.withValues(alpha: 0.72), height: 1.3),
          ),
          if (progress != null) ...[
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                minHeight: 6,
                value: progress,
                color: accent,
                backgroundColor: Colors.white.withValues(alpha: 0.7),
              ),
            ),
          ],
          const SizedBox(height: 12),
          SizedBox(width: double.infinity, child: action),
        ],
      ),
    );
  }
}
