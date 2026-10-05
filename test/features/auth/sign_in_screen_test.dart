import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onehealth_ui/core/mascot/aqua_mascot.dart';
import 'package:onehealth_ui/core/settings/app_preferences.dart';
import 'package:onehealth_ui/core/settings/app_settings_controller.dart';
import 'package:onehealth_ui/data/repositories/api_failure.dart';
import 'package:onehealth_ui/data/repositories/auth_repository.dart';
import 'package:onehealth_ui/data/repositories/repository_models.dart';
import 'package:onehealth_ui/features/auth/sign_in_screen.dart';
import 'package:onehealth_ui/l10n/generated/app_localizations.dart';

void main() {
  testWidgets('password visibility can be toggled', (tester) async {
    final auth = _ControlledAuthRepository();
    await _pumpSignIn(tester, auth);

    TextField passwordField() => tester.widget<TextField>(
      find.descendant(
        of: find.byKey(const Key('authPasswordField')),
        matching: find.byType(TextField),
      ),
    );

    expect(passwordField().obscureText, isTrue);
    await tester.tap(find.byKey(const Key('authPasswordVisibility')));
    await tester.pump();
    expect(passwordField().obscureText, isFalse);
  });

  testWidgets('thinking Ripple and clear copy appear while sign-in is pending', (
    tester,
  ) async {
    final pending = Completer<AuthUser>();
    final auth = _ControlledAuthRepository(result: pending.future);
    var completed = false;
    await _pumpSignIn(
      tester,
      auth,
      onSignedIn: () => completed = true,
    );
    await tester.enterText(
      find.byKey(const Key('authUsernameField')),
      'river-user',
    );
    await tester.enterText(
      find.byKey(const Key('authPasswordField')),
      'test-password',
    );
    await tester.tap(find.byKey(const Key('authSubmitButton')));
    await tester.pump();

    expect(find.byKey(const Key('authLoading')), findsOneWidget);
    expect(find.text('Signing you in…'), findsOneWidget);
    expect(
      tester.widget<AquaMascot>(find.byType(AquaMascot)).mood,
      MascotMood.thinking,
    );
    expect(completed, isFalse);

    pending.complete(
      const AuthUser(username: 'river-user', displayName: 'River User'),
    );
    await tester.pumpAndSettle();
    expect(completed, isTrue);
  });

  testWidgets('401 sign-in failure uses bad-credentials copy', (tester) async {
    final auth = _ControlledAuthRepository(
      error: const ApiFailure(statusCode: 401),
    );
    await _pumpSignIn(tester, auth);
    await tester.enterText(
      find.byKey(const Key('authUsernameField')),
      'river-user',
    );
    await tester.enterText(
      find.byKey(const Key('authPasswordField')),
      'wrong-password',
    );
    await tester.tap(find.byKey(const Key('authSubmitButton')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('authErrorBanner')), findsOneWidget);
    expect(
      tester.widgetList<AquaMascot>(find.byType(AquaMascot)).every(
        (mascot) => mascot.mood == MascotMood.concerned,
      ),
      isTrue,
    );
    expect(
      find.text("That email or password didn't match. Check them and try again."),
      findsOneWidget,
    );
    expect(find.textContaining('session timed out'), findsNothing);
    expect(find.textContaining('401'), findsNothing);
  });

  testWidgets('a bundled local account signs in by email and persists', (
    tester,
  ) async {
    final preferences = MemoryAppPreferences();
    final auth = LocalAccountsAuthRepository(
      preferences: preferences,
      assetBundle: _StringAssetBundle(_localAccountsJson),
    );
    addTearDown(auth.dispose);
    var completed = false;
    await _pumpSignIn(tester, auth, onSignedIn: () => completed = true);

    await tester.enterText(
      find.byKey(const Key('authUsernameField')),
      'avery.current@example.test',
    );
    await tester.enterText(
      find.byKey(const Key('authPasswordField')),
      'Ripple2026!',
    );
    await tester.tap(find.byKey(const Key('authSubmitButton')));
    await tester.pumpAndSettle();

    expect(completed, isTrue);
    final user = await auth.currentUser();
    expect(user?.displayName, 'Avery Current');
    expect(user?.region, 'Porto District');
  });
}

const String _localAccountsJson = '''
{
  "accounts": [
    {
      "displayName": "Avery Current",
      "username": "avery.current",
      "email": "avery.current@example.test",
      "password": "Ripple2026!",
      "region": "Porto District",
      "memberSince": "2025-04-12",
      "preferredLanguage": "English"
    }
  ]
}
''';

class _StringAssetBundle extends CachingAssetBundle {
  _StringAssetBundle(this.value);

  final String value;

  @override
  Future<ByteData> load(String key) async {
    expect(key, LocalAccountsAuthRepository.accountsAsset);
    final bytes = Uint8List.fromList(utf8.encode(value));
    return ByteData.view(bytes.buffer);
  }
}

Future<void> _pumpSignIn(
  WidgetTester tester,
  AuthRepository auth, {
  VoidCallback? onSignedIn,
}) async {
  final settings = AppSettingsController(preferences: MemoryAppPreferences());
  addTearDown(settings.dispose);
  await tester.pumpWidget(
    AppSettingsScope(
      controller: settings,
      child: MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: SignInScreen(
          authRepository: auth,
          onSignedIn: onSignedIn ?? () {},
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

class _ControlledAuthRepository implements AuthRepository {
  _ControlledAuthRepository({Future<AuthUser>? result, this.error})
    : _result =
          result ??
          Future<AuthUser>.value(
            const AuthUser(
              username: 'river-user',
              displayName: 'River User',
            ),
          );

  final Future<AuthUser> _result;
  final Object? error;

  @override
  Future<AuthUser?> currentUser() async => null;

  @override
  Future<AuthUser> signIn({
    required String username,
    required String password,
  }) => error == null ? _result : Future<AuthUser>.error(error!);

  @override
  Future<void> signOut() async {}
}
