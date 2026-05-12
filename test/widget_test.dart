import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:itransit_2/main.dart';

void main() {
  testWidgets('shows route search inputs on Search tab', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MyApp());

    await tester.tap(find.byIcon(Icons.search));
    await tester.pump();

    expect(find.text('Search connection'), findsOneWidget);
    expect(find.text('From'), findsOneWidget);
    expect(find.text('To'), findsOneWidget);
    expect(find.text('Search route'), findsOneWidget);
  });
}
