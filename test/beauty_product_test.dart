import 'package:flutter_test/flutter_test.dart';
import 'package:glowcycle/models/beauty_product.dart';

BeautyProduct _product({
  String status = 'Opened',
  int expiryMonths = 12,
  DateTime? directExpiryDate,
}) {
  return BeautyProduct(
    id: 'test-product',
    name: 'Test Moisturizer',
    brand: 'GlowCycle Test',
    category: 'Skincare',
    purchaseDate: DateTime(2026, 1, 1),
    openingDate: DateTime(2026, 1, 1),
    expiryMonths: expiryMonths,
    status: status,
    imagePath: '',
    notes: '',
    ingredients: const [],
    directExpiryDate: directExpiryDate,
    createdAt: DateTime(2026, 1, 1),
    updatedAt: DateTime(2026, 1, 1),
  );
}

void main() {
  group('BeautyProduct lifecycle', () {
    test('derives expiry from opening date and PAO months', () {
      final product = _product();

      expect(product.expiryDate, DateTime(2027, 1, 1));
      expect(product.resolvedStatus(DateTime(2026, 6, 1)), 'Safe');
    });

    test('marks a product Use Soon through the 60-day boundary', () {
      final product = _product(directExpiryDate: DateTime(2026, 8, 1));

      expect(product.resolvedStatus(DateTime(2026, 6, 2)), 'Use Soon');
      expect(product.resolvedStatus(DateTime(2026, 8, 2)), 'Expired');
    });

    test('does not allow ended products into Assistant recommendations', () {
      final now = DateTime(2026, 6, 1);

      expect(_product(status: 'Finished').isRecommendable(now), isFalse);
      expect(_product(status: 'Recycled').isRecommendable(now), isFalse);
      expect(
        _product(directExpiryDate: DateTime(2026, 5, 31)).isRecommendable(now),
        isFalse,
      );
    });
  });
}
