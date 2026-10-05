import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onehealth_ui/data/repositories/repository_models.dart';
import 'package:onehealth_ui/features/home/site_preview_card.dart';
import 'package:onehealth_ui/l10n/generated/app_localizations.dart';

const _site = StreamSite(
  code: 'DEMO-RIVER-01',
  name: 'Willow Bend Stream',
  latitude: 41.444,
  longitude: -8.296,
  distanceKm: 1.0,
);

void main() {
  testWidgets('shows the name, walk time and needs-data status', (
    tester,
  ) async {
    await _pumpCard(tester, visited: false, onViewDetails: () {}, onClose: () {});

    expect(find.text('Willow Bend Stream'), findsOneWidget);
    // 1 km at an average walking pace of 5 km/h rounds to 12 minutes.
    expect(find.textContaining('12 min walk'), findsOneWidget);
    expect(find.textContaining('Needs data'), findsOneWidget);
  });

  testWidgets('shows Visited instead once the site has history', (
    tester,
  ) async {
    await _pumpCard(tester, visited: true, onViewDetails: () {}, onClose: () {});

    expect(find.textContaining('Visited'), findsOneWidget);
  });

  testWidgets('tapping the card opens the site detail', (tester) async {
    var opened = false;
    await _pumpCard(
      tester,
      visited: false,
      onViewDetails: () => opened = true,
      onClose: () {},
    );

    await tester.tap(find.byKey(const Key('sitePreviewCard')));
    expect(opened, isTrue);
  });

  testWidgets('tapping close dismisses the preview', (tester) async {
    var closed = false;
    await _pumpCard(
      tester,
      visited: false,
      onViewDetails: () {},
      onClose: () => closed = true,
    );

    await tester.tap(find.byKey(const Key('sitePreviewCardClose')));
    expect(closed, isTrue);
  });
}

Future<void> _pumpCard(
  WidgetTester tester, {
  required bool visited,
  required VoidCallback onViewDetails,
  required VoidCallback onClose,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      locale: const Locale('en'),
      localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: SitePreviewCard(
          site: _site,
          visited: visited,
          onViewDetails: onViewDetails,
          onClose: onClose,
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}
