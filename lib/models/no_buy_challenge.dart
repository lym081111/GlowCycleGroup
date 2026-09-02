import '../core/eco_rewards.dart';
import 'eco_action.dart';

/// State of the user's 7-day no-buy challenge, derived from their action log.
///
/// The challenge used to pay out on every tap, which made a button labelled
/// "7-Day No-Buy Challenge" award points in no time at all. It now measures
/// real elapsed days and is broken by adding a product before the end.
class NoBuyChallenge {
  const NoBuyChallenge({
    required this.startedAt,
    required this.daysElapsed,
    required this.broken,
    required this.brokenBy,
  });

  /// When the running challenge began, or null when none is active.
  final DateTime? startedAt;

  /// Whole days completed since [startedAt].
  final int daysElapsed;

  /// True when a product was added before the challenge finished.
  final bool broken;

  /// Name of the product that broke it, for an honest explanation.
  final String? brokenBy;

  bool get isActive => startedAt != null && !broken;

  bool get readyToClaim =>
      isActive && daysElapsed >= EcoRewards.noBuyChallengeDays;

  int get daysRemaining =>
      (EcoRewards.noBuyChallengeDays - daysElapsed).clamp(0, 999);

  /// Reads the current challenge out of [actions], newest first or otherwise.
  factory NoBuyChallenge.from(List<EcoAction> actions, DateTime now) {
    DateTime? latest(String type) {
      final dates = actions
          .where((item) => item.actionType == type)
          .map((item) => item.date)
          .toList();
      if (dates.isEmpty) {
        return null;
      }
      dates.sort();
      return dates.last;
    }

    final started = latest(EcoActionTypes.noBuyStarted);
    if (started == null) {
      return const NoBuyChallenge(
        startedAt: null,
        daysElapsed: 0,
        broken: false,
        brokenBy: null,
      );
    }

    // A completed claim closes that run; the user has to start another.
    final claimed = latest(EcoActionTypes.noBuyCompleted);
    if (claimed != null && claimed.isAfter(started)) {
      return const NoBuyChallenge(
        startedAt: null,
        daysElapsed: 0,
        broken: false,
        brokenBy: null,
      );
    }

    final purchase = actions
        .where(
          (item) =>
              item.actionType == EcoActionTypes.addProduct &&
              item.date.isAfter(started),
        )
        .toList();
    purchase.sort((a, b) => a.date.compareTo(b.date));

    return NoBuyChallenge(
      startedAt: started,
      daysElapsed: now.difference(started).inDays,
      broken: purchase.isNotEmpty,
      brokenBy: purchase.isEmpty ? null : purchase.first.description,
    );
  }
}
