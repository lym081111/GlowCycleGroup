import 'beauty_product.dart';
import 'eco_action.dart';

/// Everything [GlowStore] loads for one user in a single round trip.
class AppData {
  AppData({required this.products, required this.actions});

  final List<BeautyProduct> products;
  final List<EcoAction> actions;
}
