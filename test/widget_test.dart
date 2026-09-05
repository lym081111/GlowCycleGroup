import 'package:flutter_test/flutter_test.dart';
import 'package:glowcycle/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('GlowCycle splash renders', (tester) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(const GlowCycleApp());

    expect(find.text('GlowCycle'), findsOneWidget);
    expect(
      find.text('Track beauty. Reduce waste. Glow responsibly.'),
      findsOneWidget,
    );

    await tester.pump(const Duration(milliseconds: 1300));
    await tester.pump();
  });
}
