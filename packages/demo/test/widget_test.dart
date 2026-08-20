import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:demo/main.dart';

void main() {
  testWidgets('demo smoke', (tester) async {
    await tester.pumpWidget(const BexDemoApp());
    await tester.pump();

    expect(find.text('BEX Flutter Demo'), findsOneWidget);
    expect(find.text('Auth token'), findsOneWidget);

    // ListView only builds visible children; scroll to reveal actions + result.
    await tester.drag(find.byType(ListView), const Offset(0, -2000));
    await tester.pumpAndSettle();

    expect(find.text('Initialize'), findsOneWidget);
    expect(find.text('Result'), findsOneWidget);
  });
}
