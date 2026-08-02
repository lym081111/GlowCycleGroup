import 'beauty_product.dart';
import 'eco_action.dart';

/// Aggregated shelf counters shown on the dashboard, saver, and eco screens.
class InventoryStats {
  InventoryStats({
    required this.total,
    required this.useSoon,
    required this.expired,
    required this.finished,
    required this.recycled,
    required this.points,
  });

  factory InventoryStats.from(
    List<BeautyProduct> products,
    List<EcoAction> actions,
    DateTime now,
  ) {
    return InventoryStats(
      total: products.length,
      useSoon: products
          .where((item) => item.resolvedStatus(now) == 'Use Soon')
          .length,
      expired: products
          .where((item) => item.resolvedStatus(now) == 'Expired')
          .length,
      finished: products
          .where((item) => item.resolvedStatus(now) == 'Finished')
          .length,
      recycled: products
          .where((item) => item.resolvedStatus(now) == 'Recycled')
          .length,
      points: actions.fold<int>(
        0,
        (total, action) => total + action.pointsEarned,
      ),
    );
  }

  final int total;
  final int useSoon;
  final int expired;
  final int finished;
  final int recycled;
  final int points;
}
