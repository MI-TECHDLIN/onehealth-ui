import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onehealth_ui/core/widgets/field_safety_notice.dart';

void main() {
  testWidgets('renders the title and every safety point as plain text', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: FieldSafetyNotice(
            title: 'A quick safety reminder',
            points: <String>[
              'Stay on the bank. Never enter the water.',
              'Watch for slippery or steep banks.',
            ],
          ),
        ),
      ),
    );

    expect(find.text('A quick safety reminder'), findsOneWidget);
    expect(
      find.text('Stay on the bank. Never enter the water.'),
      findsOneWidget,
    );
    expect(find.text('Watch for slippery or steep banks.'), findsOneWidget);
  });

  testWidgets('exposes its title as an accessible container label', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: FieldSafetyNotice(
            title: 'A quick safety reminder',
            points: <String>['Skip the check in bad weather or high water.'],
          ),
        ),
      ),
    );

    expect(find.bySemanticsLabel('A quick safety reminder'), findsOneWidget);
  });
}
