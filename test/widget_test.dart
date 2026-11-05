import 'package:flutter_test/flutter_test.dart';

import 'package:skycast/main.dart';

void main() {
  testWidgets('main navigation switches between app screens', (tester) async {
    await tester.pumpWidget(const SkyCastApp());

    expect(find.text('Today'), findsOneWidget);
    await tester.tap(find.text('Saved'));
    await tester.pump();
    expect(find.text('Saved cities'), findsOneWidget);

    await tester.tap(find.text('Settings'));
    await tester.pump();
    expect(find.text('Make SkyCast feel like yours.'), findsOneWidget);
  });
}
