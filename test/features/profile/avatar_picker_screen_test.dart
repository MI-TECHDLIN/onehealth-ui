import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:onehealth_ui/app/app_router.dart';
import 'package:onehealth_ui/core/profile/avatar_catalog.dart';
import 'package:onehealth_ui/core/settings/app_preferences.dart';
import 'package:onehealth_ui/core/settings/app_settings_controller.dart';
import 'package:onehealth_ui/features/profile/avatar_picker_screen.dart';
import 'package:onehealth_ui/l10n/generated/app_localizations.dart';

GoRouter _router({String initialLocation = AppRoutes.avatar}) => GoRouter(
  initialLocation: initialLocation,
  routes: <RouteBase>[
    GoRoute(
      path: AppRoutes.avatar,
      builder: (context, state) => AvatarPickerScreen(
        returnToProfile: state.uri.queryParameters['change'] == 'true',
      ),
    ),
    GoRoute(
      path: AppRoutes.home,
      builder: (context, state) => const Scaffold(body: Text('Home stub')),
    ),
    GoRoute(
      path: AppRoutes.profile,
      builder: (context, state) => const Scaffold(body: Text('Profile stub')),
    ),
  ],
);

Widget _app(GoRouter router, AppSettingsController settings) =>
    AppSettingsScope(
      controller: settings,
      child: MaterialApp.router(
        routerConfig: router,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
      ),
    );

void main() {
  testWidgets('shows all presets and saves the selected avatar', (tester) async {
    await tester.binding.setSurfaceSize(const Size(430, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final preferences = MemoryAppPreferences();
    final settings = AppSettingsController(preferences: preferences);
    final router = _router();
    addTearDown(settings.dispose);
    addTearDown(router.dispose);

    await tester.pumpWidget(_app(router, settings));
    await tester.pumpAndSettle();

    expect(find.byType(SvgPicture), findsNWidgets(AvatarCatalog.ids.length));
    expect(find.bySemanticsLabel('Avatar 1, selected'), findsOneWidget);

    await tester.tap(find.bySemanticsLabel('Avatar 2'));
    await tester.pump();
    expect(find.bySemanticsLabel('Avatar 2, selected'), findsOneWidget);

    await tester.tap(find.text('Complete set-up'));
    await tester.pumpAndSettle();

    expect(settings.avatarId, 'avatar-02');
    expect(
      await preferences.readString(
        AppSettingsController.avatarPreferenceKey,
      ),
      'avatar-02',
    );
    expect(find.text('Home stub'), findsOneWidget);
  });

  testWidgets('Do this later assigns and persists the fallback preset', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(430, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final preferences = MemoryAppPreferences();
    final settings = AppSettingsController(preferences: preferences);
    final router = _router();
    addTearDown(settings.dispose);
    addTearDown(router.dispose);

    await tester.pumpWidget(_app(router, settings));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Do this later'));
    await tester.pumpAndSettle();

    expect(settings.avatarId, AvatarCatalog.autoAssignedId);
    expect(find.text('Home stub'), findsOneWidget);

    final restored = AppSettingsController(preferences: preferences);
    addTearDown(restored.dispose);
    await restored.load();
    expect(restored.avatarId, AvatarCatalog.autoAssignedId);
  });
}
