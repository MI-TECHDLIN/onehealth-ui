import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

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
  final preferences = SharedPreferencesAppPreferences();
  final settings = AppSettingsController(preferences: preferences);
  await settings.load();
  runApp(
    OneHealthApp(
      settings: settings,
      repositoryPreferences: preferences,
    ),
  );
}

class OneHealthApp extends StatefulWidget {
  const OneHealthApp({
    super.key,
    this.settings,
    this.demoRepositories,
    this.liveRepositories,
    this.repositoryPreferences,
    this.applyGoogleFonts = true,
  });

  final AppSettingsController? settings;
  final RepositoryBundle? demoRepositories;
  final RepositoryBundle? liveRepositories;
  final AppPreferences? repositoryPreferences;
  final bool applyGoogleFonts;

  @override
  State<OneHealthApp> createState() => _OneHealthAppState();
}

class _OneHealthAppState extends State<OneHealthApp> {
  late final AppSettingsController _settings =
      widget.settings ?? AppSettingsController.memory();
  late final RepositoryBundle _demoRepositories;
  late final RepositoryBundle _liveRepositories;
  late final GoRouter _router;

  bool get _ownsSettings => widget.settings == null;

  @override
  void initState() {
    super.initState();
    final repositoryPreferences =
        widget.repositoryPreferences ?? MemoryAppPreferences();
    _demoRepositories =
        widget.demoRepositories ??
        RepositoryBundle.demo(preferences: repositoryPreferences);
    _liveRepositories =
        widget.liveRepositories ??
        RepositoryBundle.live(preferences: repositoryPreferences);
    _router = createAppRouter(
      initialLocation: _settings.onboardingComplete
          ? AppRoutes.home
          : AppRoutes.onboarding,
      settings: _settings,
      liveAuth: _liveRepositories.auth,
    );
  }

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
          repositories: _settings.mode.isLive
              ? _liveRepositories
              : _demoRepositories,
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
