import 'package:flutter_test/flutter_test.dart';
import 'package:glowcycle/main.dart';

void main() {
  testWidgets('leader shell opens the product scanner', (tester) async {
    await tester.pumpWidget(const GlowCycleApp());

    expect(find.text('Smart beauty inventory'), findsOneWidget);
    await tester.tap(find.text('Scan a product'));
    await tester.pumpAndSettle();
    expect(find.text('Add to Shelf'), findsOneWidget);
  });
}
