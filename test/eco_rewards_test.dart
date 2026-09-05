import 'package:flutter_test/flutter_test.dart';
import 'package:glowcycle/core/eco_rewards.dart';
import 'package:glowcycle/models/eco_action.dart';
import 'package:glowcycle/models/inventory_stats.dart';

void main() {
  test('eco reward values match the assignment rules', () {
    expect(EcoRewards.addProduct, 1);
    expect(EcoRewards.finishBeforeExpiry, 10);
    expect(EcoRewards.finishAfterExpiry, 0);
    expect(EcoRewards.recycleContainer, 15);
    expect(EcoRewards.avoidDuplicate, 5);
    expect(EcoRewards.noBuyChallenge, 20);
  });

  test('inventory stats totals positive and reversed eco actions', () {
    final actions = [
      EcoAction.created(
        actionType: EcoActionTypes.addProduct,
        pointsEarned: EcoRewards.addProduct,
        description: 'Product added.',
      ),
      EcoAction.created(
        actionType: EcoActionTypes.recycleContainer,
        pointsEarned: EcoRewards.recycleContainer,
        description: 'Container recycled.',
      ),
      EcoAction.created(
        actionType: EcoActionTypes.avoidDuplicate,
        pointsEarned: EcoRewards.avoidDuplicate,
        description: 'Purchase avoided.',
      ),
      EcoAction.created(
        actionType: EcoActionTypes.duplicateReversed,
        pointsEarned: -EcoRewards.avoidDuplicate,
        description: 'Purchase later recorded.',
      ),
    ];

    final stats = InventoryStats.from(const [], actions, DateTime(2026, 9, 5));

    expect(stats.points, 16);
  });

  test('legacy actions are normalized to the current reward rules', () {
    final oldFinish = EcoAction.fromJson({
      'id': 'old-finish',
      'actionType': EcoActionTypes.finishProduct,
      'pointsEarned': 15,
      'description': 'Serum finished before expiry.',
      'date': '2026-09-05T12:00:00.000',
    });
    final oldDuplicateSkip = EcoAction.fromJson({
      'id': 'old-skip',
      'actionType': EcoActionTypes.avoidDuplicate,
      'pointsEarned': 25,
      'description': 'Skipped a duplicate Serum purchase.',
      'date': '2026-09-05T12:00:00.000',
    });

    expect(oldFinish.pointsEarned, 10);
    expect(oldDuplicateSkip.pointsEarned, 5);
    expect(oldFinish.rewardVersion, EcoRewards.rulesVersion);
  });
}
