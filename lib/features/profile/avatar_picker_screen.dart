import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../app/app_router.dart';
import '../../core/profile/avatar_catalog.dart';
import '../../core/settings/app_settings_controller.dart';
import '../../core/theme/tokens.dart';
import '../../l10n/generated/app_localizations.dart';

class AvatarPickerScreen extends StatefulWidget {
  const AvatarPickerScreen({super.key, this.returnToProfile = false});

  final bool returnToProfile;

  @override
  State<AvatarPickerScreen> createState() => _AvatarPickerScreenState();
}

class _AvatarPickerScreenState extends State<AvatarPickerScreen> {
  String? _selectedId;
  bool _saving = false;

  static const List<Color> _backgrounds = <Color>[
    AppColors.sparkle,
    AppColors.waterLight,
    AppColors.peachLight,
    AppColors.sageLight,
    AppColors.peach,
    AppColors.waterMist,
  ];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _selectedId ??=
        AppSettingsScope.of(context).avatarId ?? AvatarCatalog.ids.first;
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: widget.returnToProfile,
      ),
      body: SafeArea(
        child: Column(
          children: <Widget>[
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.page,
                  AppSpacing.xs,
                  AppSpacing.page,
                  AppSpacing.lg,
                ),
                child: Column(
                  children: <Widget>[
                    Text(
                      strings.authAvatarTitle,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      strings.authAvatarReassurance,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            mainAxisSpacing: AppSpacing.md,
                            crossAxisSpacing: AppSpacing.md,
                          ),
                      itemCount: AvatarCatalog.ids.length,
                      itemBuilder: (context, index) {
                        final id = AvatarCatalog.ids[index];
                        return _AvatarChoice(
                          id: id,
                          index: index,
                          selected: id == _selectedId,
                          background: _backgrounds[index % _backgrounds.length],
                          onTap: _saving
                              ? null
                              : () => setState(() => _selectedId = id),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.page,
                AppSpacing.sm,
                AppSpacing.page,
                AppSpacing.page,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  FilledButton(
                    onPressed: _saving ? null : _complete,
                    child: Text(strings.authAvatarCompleteAction),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  TextButton(
                    onPressed: _saving ? null : _skip,
                    child: Text(strings.authAvatarLaterAction),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _complete() async {
    setState(() => _saving = true);
    await AppSettingsScope.of(context).setAvatar(_selectedId!);
    if (mounted) _finish();
  }

  Future<void> _skip() async {
    setState(() => _saving = true);
    final settings = AppSettingsScope.of(context);
    if (!settings.hasCompletedAvatarSetup) await settings.autoAssignAvatar();
    if (mounted) _finish();
  }

  void _finish() => context.go(
    widget.returnToProfile ? AppRoutes.profile : AppRoutes.home,
  );
}

class _AvatarChoice extends StatelessWidget {
  const _AvatarChoice({
    required this.id,
    required this.index,
    required this.selected,
    required this.background,
    required this.onTap,
  });

  final String id;
  final int index;
  final bool selected;
  final Color background;
  final VoidCallback? onTap;

  static const ColorFilter _greyscale = ColorFilter.matrix(<double>[
    0.2126, 0.7152, 0.0722, 0, 0,
    0.2126, 0.7152, 0.0722, 0, 0,
    0.2126, 0.7152, 0.0722, 0, 0,
    0, 0, 0, 1, 0,
  ]);

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final label = selected
        ? strings.authAvatarSelectedLabel(index + 1)
        : strings.authAvatarLabel(index + 1);
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Stack(
          fit: StackFit.expand,
          children: <Widget>[
            AnimatedContainer(
              duration: AppMotion.quick,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: background,
                border: Border.all(
                  color: selected ? AppColors.deepWater : AppColors.outline,
                  width: selected ? AppStrokes.focus : AppStrokes.icon,
                ),
                boxShadow: selected ? AppElevation.low : null,
              ),
              padding: const EdgeInsets.all(AppSpacing.xxs),
              child: ClipOval(
                child: ColorFiltered(
                  colorFilter: selected
                      ? const ColorFilter.mode(
                          Colors.transparent,
                          BlendMode.dst,
                        )
                      : _greyscale,
                  child: SvgPicture.asset(
                    AvatarCatalog.assetFor(id),
                    fit: BoxFit.cover,
                    excludeFromSemantics: true,
                  ),
                ),
              ),
            ),
            if (selected)
              PositionedDirectional(
                top: 0,
                end: 0,
                child: Container(
                  decoration: const BoxDecoration(
                    color: AppColors.deepWater,
                    shape: BoxShape.circle,
                  ),
                  padding: const EdgeInsets.all(AppSpacing.xxs),
                  child: const Icon(
                    PhosphorIconsFill.check,
                    size: 18,
                    color: AppColors.white,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
