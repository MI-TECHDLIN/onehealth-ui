import 'package:flutter/material.dart';

import 'app/app_router.dart';
import 'core/localization/app_locale.dart';
import 'core/settings/app_preferences.dart';
import 'core/settings/app_settings_controller.dart';
import 'core/theme/app_theme.dart';
import 'data/repositories/repository_bundle.dart';
import 'data/repositories/repository_scope.dart';
import 'l10n/generated/app_localizations.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final settings = AppSettingsController(
    preferences: SharedPreferencesAppPreferences(),
  );
  await settings.load();
  runApp(OneHealthApp(settings: settings));
}

class OneHealthApp extends StatefulWidget {
  const OneHealthApp({
    super.key,
    this.settings,
    this.applyGoogleFonts = true,
  });

  final AppSettingsController? settings;
  final bool applyGoogleFonts;

  @override
  State<OneHealthApp> createState() => _OneHealthAppState();
}

class _OneHealthAppState extends State<OneHealthApp> {
  late final AppSettingsController _settings =
      widget.settings ?? AppSettingsController.memory();
  late final _router = createAppRouter();
  late final RepositoryBundle _demoRepositories = RepositoryBundle.demo();

  bool get _ownsSettings => widget.settings == null;

  @override
  void dispose() {
    _router.dispose();
    if (_ownsSettings) _settings.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppSettingsScope(
      controller: _settings,
      child: AnimatedBuilder(
        animation: _settings,
        builder: (context, _) => RepositoryScope(
          mode: _settings.mode,
          repositories: _settings.mode.isLive ? null : _demoRepositories,
          child: MaterialApp.router(
            onGenerateTitle: (context) => AppLocalizations.of(context).appName,
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightFor(
              _settings.locale,
              applyGoogleFonts: widget.applyGoogleFonts,
            ),
            darkTheme: AppTheme.darkFor(
              _settings.locale,
              applyGoogleFonts: widget.applyGoogleFonts,
            ),
            themeMode: ThemeMode.system,
            locale: _settings.locale,
            supportedLocales: AppLocaleRegistry.supportedLocales,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            routerConfig: _router,
          ),
        ),
      ),
    );
  }
}
