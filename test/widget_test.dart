import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:zero_waste_food/main.dart';

void main() {
  testWidgets('ZeroWaste Food app starts in demo mode', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const ProviderScope(child: ZeroWasteFoodApp()));

    await tester.pump(const Duration(seconds: 1));
    await tester.pump();

    expect(find.text('ZeroWaste Food'), findsAtLeastNWidgets(1));
    expect(find.text('Sign in to manage food donations.'), findsOneWidget);
  });
}
