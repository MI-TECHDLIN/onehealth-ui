import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/haptics/app_haptics.dart';
import '../../core/localization/app_locale.dart';
import '../../core/mode/app_mode.dart';
import '../../core/settings/app_settings_controller.dart';
import '../../core/theme/tokens.dart';
import '../../core/widgets/mode_badge.dart';
import '../../debug/mascot_gallery_screen.dart';
import '../../l10n/generated/app_localizations.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key, this.haptics});

  final AppHaptics? haptics;

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
                leading: const Icon(Icons.language_rounded),
                title: Text(strings.settingsLanguage),
                subtitle: Text(selectedLocale.endonym),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => _chooseLanguage(context, settings),
              ),
            ),
            if (kDebugMode) ...<Widget>[
              const SizedBox(height: AppSpacing.md),
              Card(
                child: ListTile(
                  leading: const Icon(Icons.water_drop_outlined),
                  title: Text(strings.debugMascotGallery),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => context.push(MascotGalleryScreen.routeName),
                ),
              ),
            ],
          ],
        ),
      ),
    );
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
