import 'package:flutter_test/flutter_test.dart';
import 'package:glowcycle/models/product_scan_result.dart';

void main() {
  test('OCR fallback extracts PAO and batch number', () {
    final result = ProductScanResult.fromOcrHeuristic('''
Glow Lab
Barrier Cream
Ingredients: Water, Glycerin, Ceramide NP
12M
Batch: GC2026
''');

    expect(result.paoMonths, 12);
    expect(result.batchNumber, 'GC2026');
    expect(result.ingredients, contains('Glycerin'));
    expect(result.source, 'local-ocr');
  });
}
