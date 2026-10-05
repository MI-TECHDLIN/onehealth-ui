import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../app/app_router.dart';
import '../../core/app_info.dart';
import '../../core/gamification/badge_acknowledgement_store.dart';
import '../../core/gamification/demo_story_seed.dart';
import '../../core/haptics/app_haptics.dart';
import '../../core/localization/app_locale.dart';
import '../../core/mode/app_mode.dart';
import '../../core/notifications/reminder_notifier.dart';
import '../../core/settings/app_preferences.dart';
import '../../core/settings/app_settings_controller.dart';
import '../../core/theme/tokens.dart';
import '../../core/widgets/mode_badge.dart';
import '../../data/repositories/assessment_repository.dart';
import '../../data/repositories/repository_scope.dart';
import '../../debug/mascot_gallery_screen.dart';
import '../../l10n/generated/app_localizations.dart';
import 'credits_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({
    super.key,
    this.haptics,
    this.reminderNotifier,
    this.preferences,
  });

  final AppHaptics? haptics;

  /// Overridable so tests can verify the permission flow without the real
  /// plugin; production constructs a [LocalReminderNotifier] lazily.
  final ReminderNotifier? reminderNotifier;

  /// Overridable so tests can verify Reset demo without the real on-device
  /// store; production uses the shared on-device store.
  final AppPreferences? preferences;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final settings = AppSettingsScope.of(context);
    final selectedLocale = AppLocaleRegistry.resolve(settings.locale);

    return Scaffold(
      appBar: AppBar(title: Text(strings.settingsTitle)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.page),
          children: <Widget>[
            Card(
              child: SwitchListTile.adaptive(
                title: Text(strings.settingsDataMode),
                subtitle: Text(
                  settings.mode.isLive
                      ? strings.liveModeDescription
                      : strings.demoModeDescription,
                ),
                secondary: ModeBadge(mode: settings.mode),
                value: settings.mode.isLive,
                onChanged: (_) => _confirmModeChange(context, settings),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Card(
              child: ListTile(
                minVerticalPadding: AppSpacing.md,
                leading: const Icon(PhosphorIconsRegular.globe),
                title: Text(strings.settingsLanguage),
                subtitle: Text(selectedLocale.endonym),
                trailing: const Icon(PhosphorIconsRegular.caretRight),
                onTap: () => _chooseLanguage(context, settings),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Card(
              child: SwitchListTile.adaptive(
                title: Text(strings.onboardingSettingsReadAloudToggle),
                subtitle: Text(
                  strings.onboardingSettingsReadAloudToggleDescription,
                ),
                value: settings.readAloudEnabled,
                onChanged: (value) => settings.setReadAloudEnabled(value),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Card(
              child: SwitchListTile.adaptive(
                title: Text(strings.settingsRemindersToggle),
                subtitle: Text(strings.settingsRemindersToggleDescription),
                value: settings.remindersEnabled,
                onChanged: (value) => _setRemindersEnabled(context, settings, value),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Card(
              child: ListTile(
                leading: const Icon(PhosphorIconsRegular.clockCounterClockwise),
                title: Text(strings.onboardingSettingsReplay),
                trailing: const Icon(PhosphorIconsRegular.caretRight),
                onTap: () =>
                    context.push('${AppRoutes.onboarding}?replay=true'),
              ),
            ),
            if (!settings.mode.isLive) ...<Widget>[
              const SizedBox(height: AppSpacing.lg),
              Text(
                strings.settingsDemoDataSection,
                style: Theme.of(context).textTheme.labelLarge,
              ),
              const SizedBox(height: AppSpacing.sm),
              Card(
                child: ListTile(
                  key: const Key('settingsResetDemoTile'),
                  leading: const Icon(PhosphorIconsRegular.arrowsClockwise),
                  title: Text(strings.settingsResetDemoTitle),
                  subtitle: Text(strings.settingsResetDemoDescription),
                  onTap: () => _confirmResetDemo(context),
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.md),
            Card(
              child: ListTile(
                leading: const Icon(PhosphorIconsRegular.info),
                title: Text(strings.settingsCredits),
                trailing: const Icon(PhosphorIconsRegular.caretRight),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const CreditsScreen(),
                  ),
                ),
              ),
            ),
            if (kDebugMode) ...<Widget>[
              const SizedBox(height: AppSpacing.md),
              Card(
                child: ListTile(
                  leading: const Icon(PhosphorIconsRegular.drop),
                  title: Text(strings.debugMascotGallery),
                  trailing: const Icon(PhosphorIconsRegular.caretRight),
                  onTap: () => context.push(MascotGalleryScreen.routeName),
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.lg),
            Center(
              // A deliberate, undocumented-in-copy shortcut for recording
              // demo footage -- see AGENTS.md and docs/manual-qa.md. It
              // restarts onboarding without touching any data, exactly like
              // "Replay onboarding" above. Held a full ~2s (not the default
              // ~500ms long-press) so it is never triggered by an ordinary
              // press on this label.
              child: _LongPressVersionLabel(
                label: strings.settingsVersionLabel(AppInfo.version),
                onActivate: () => _restartOnboarding(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _restartOnboarding(BuildContext context) async {
    await (haptics ?? AppHaptics()).selection();
    if (!context.mounted) return;
    context.push('${AppRoutes.onboarding}?replay=true');
  }

  Future<void> _confirmResetDemo(BuildContext context) async {
    final strings = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(strings.settingsResetDemoConfirmTitle),
        content: Text(strings.settingsResetDemoConfirmBody),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(strings.cancelAction),
          ),
          FilledButton(
            key: const Key('settingsResetDemoConfirmButton'),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(strings.settingsResetDemoConfirmAction),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    final assessments = context
        .dependOnInheritedWidgetOfExactType<RepositoryScope>()
        ?.repositories
        .assessments;
    if (assessments is DemoSeedableAssessmentRepository) {
      final prefs = preferences ?? SharedPreferencesAppPreferences();
      await DemoStorySeeder(preferences: prefs).reset(
        assessments: assessments,
        badges: BadgeAcknowledgementStore(preferences: prefs, mode: AppMode.demo),
      );
    }
    await (haptics ?? AppHaptics()).success();
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(strings.settingsResetDemoDoneMessage)),
    );
  }

  Future<void> _setRemindersEnabled(
    BuildContext context,
    AppSettingsController settings,
    bool enabled,
  ) async {
    if (enabled) {
      // Asked only here -- the user just explicitly turned the feature on --
      // never on first launch. See AGENTS.md and `ReminderCoordinator`.
      await (reminderNotifier ?? LocalReminderNotifier()).ensurePermission();
    }
    await settings.setRemindersEnabled(enabled);
  }

  Future<void> _confirmModeChange(
    BuildContext context,
    AppSettingsController settings,
  ) async {
    final strings = AppLocalizations.of(context);
    final target = settings.mode.isLive ? AppMode.demo : AppMode.live;
    final targetLabel = target.isLive ? strings.modeLive : strings.modeDemo;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(strings.switchModeTitle(targetLabel)),
        content: Text(strings.switchModeBody),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(strings.cancelAction),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(strings.switchAction),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    await (haptics ?? AppHaptics()).selection();
    await settings.setMode(target);
  }

  Future<void> _chooseLanguage(
    BuildContext context,
    AppSettingsController settings,
  ) async {
    final strings = AppLocalizations.of(context);
    final selected = await showModalBottomSheet<AppLocaleDefinition>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (sheetContext) => SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(sheetContext).height * 0.8,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Text(
                  strings.chooseLanguage,
                  style: Theme.of(sheetContext).textTheme.titleLarge,
                ),
              ),
              Flexible(
                child: RadioGroup<String>(
                  groupValue: settings.locale.languageCode,
                  onChanged: (value) {
                    if (value == null) return;
                    final definition = AppLocaleRegistry.all.firstWhere(
                      (definition) =>
                          definition.locale.languageCode == value,
                    );
                    Navigator.pop(sheetContext, definition);
                  },
                  child: ListView(
                    children: AppLocaleRegistry.all
                        .map(
                          (definition) => RadioListTile<String>(
                            value: definition.locale.languageCode,
                            title: Text(definition.endonym),
                            subtitle: definition.translationStatus ==
                                    TranslationStatus.needsTranslation
                                ? Text(
                                    '${definition.englishName} · '
                                    '${strings.translationReviewPending}',
                                  )
                                : null,
                          ),
                        )
                        .toList(growable: false),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    if (selected == null || !context.mounted) return;
    await (haptics ?? AppHaptics()).selection();
    await settings.setLocale(selected.locale);
  }
}

/// A plain label that activates after being held down for a full ~2s,
/// rather than the shorter default `GestureDetector.onLongPress` -- see the
/// hidden onboarding-restart shortcut above.
class _LongPressVersionLabel extends StatefulWidget {
  const _LongPressVersionLabel({required this.label, required this.onActivate});

  final String label;
  final VoidCallback onActivate;

  @override
  State<_LongPressVersionLabel> createState() => _LongPressVersionLabelState();
}

class _LongPressVersionLabelState extends State<_LongPressVersionLabel> {
  static const Duration _holdDuration = Duration(seconds: 2);
  Timer? _timer;

  void _armTimer() {
    _timer?.cancel();
    _timer = Timer(_holdDuration, widget.onActivate);
  }

  void _disarmTimer() {
    _timer?.cancel();
    _timer = null;
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _armTimer(),
      onTapUp: (_) => _disarmTimer(),
      onTapCancel: _disarmTimer,
      child: Text(widget.label, style: Theme.of(context).textTheme.bodySmall),
    );
  }
}
