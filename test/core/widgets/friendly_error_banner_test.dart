import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onehealth_ui/core/widgets/friendly_error_banner.dart';

void main() {
  testWidgets('snackbar Retry is readable on errorContainer and retries',
      (tester) async {
    var retries = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => showFriendlyErrorSnackBar(
                context,
                'No connection right now.',
                onRetry: () => retries++,
              ),
              child: const Text('fail'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('fail'));
    await tester.pumpAndSettle();

    final context = tester.element(find.byType(SnackBar));
    final colorScheme = Theme.of(context).colorScheme;
    final action =
        tester.widget<SnackBarAction>(find.byType(SnackBarAction));
    expect(action.textColor, colorScheme.onErrorContainer);

    await tester.tap(find.text('Retry'));
    expect(retries, 1);
  });
}
