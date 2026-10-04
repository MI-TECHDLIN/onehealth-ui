import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/app_router.dart';
import '../../core/audio/read_aloud_service.dart';
import '../../core/mascot/aqua_mascot.dart';
import '../../core/mascot/ripple_controller.dart';
import '../../core/mode/app_mode.dart';
import '../../core/motion/motion_preferences.dart';
import '../../core/settings/app_settings_controller.dart';
import '../../core/theme/tokens.dart';
import '../../core/widgets/component_kit.dart';
import '../../l10n/generated/app_localizations.dart';
import 'onboarding_content.dart';

/// The five-screen story that explains OneAquaHealth before a citizen
/// commits to signing in or exploring. See `onboarding_content.dart` for the
/// locked copy/gesture arc and `scripts/narration/README.md` for how the
/// read-aloud narration is produced.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key, this.isReplay = false});

  /// True when opened from Settings to review the story again. Both final
  /// actions then just return to Settings instead of re-routing a citizen
  /// who has already signed in or chosen Demo mode.
  final bool isReplay;

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  static const List<OnboardingPageData> _pages = OnboardingContent.pages;

  final PageController _pageController = PageController();
  final RippleController _rippleController = RippleController();
  late final ReadAloudService _readAloud = ReadAloudService(
    rippleController: _rippleController,
  );

  int _page = 0;
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    _initialized = true;
    _rippleController.playGesture(_pages.first.gesture);
    unawaited(_loadNarration(0));
  }

  @override
  void dispose() {
    _pageController.dispose();
    _readAloud.dispose();
    _rippleController.dispose();
    super.dispose();
  }

  Future<void> _loadNarration(int index) async {
    final locale = Localizations.localeOf(context);
    await _readAloud.load(narrationId: _pages[index].id, locale: locale);
  }

  void _onPageChanged(int index) {
    setState(() => _page = index);
    unawaited(_readAloud.stop());
    unawaited(_loadNarration(index));
    _rippleController.playGesture(_pages[index].gesture);
  }

  void _goToPage(int index) {
    if (MotionPreferences.reduceMotionOf(context)) {
      _pageController.jumpToPage(index);
    } else {
      _pageController.animateToPage(
        index,
        duration: AppMotion.page,
        curve: AppMotion.pageCurve,
      );
    }
  }

  Future<void> _handleGetStarted() async {
    if (widget.isReplay) {
      context.pop();
      return;
    }
    await AppSettingsScope.of(context).completeOnboarding();
    if (!mounted) return;
    context.go(AppRoutes.signIn);
  }

  Future<void> _handleLookAround() async {
    if (widget.isReplay) {
      context.pop();
      return;
    }
    final settings = AppSettingsScope.of(context);
    await settings.completeOnboarding();
    await settings.setMode(AppMode.demo);
    if (!mounted) return;
    context.go(AppRoutes.home);
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final readAloudEnabled = AppSettingsScope.of(context).readAloudEnabled;
    final isLast = _page == _pages.length - 1;
    final mood = isLast ? MascotMood.celebrating : MascotMood.guiding;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.lg),
              child: AquaMascot(
                mood: mood,
                controller: _rippleController,
                size: 128,
              ),
            ),
            Expanded(
              child: Semantics(
                hint: strings.onboardingPageSemanticHint,
                child: PageView(
                  controller: _pageController,
                  onPageChanged: _onPageChanged,
                  children: <Widget>[
                    for (final page in _pages)
                      _OnboardingPageBody(
                        data: page,
                        service: _readAloud,
                        readAloudEnabled: readAloudEnabled,
                        strings: strings,
                      ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.page,
                AppSpacing.md,
                AppSpacing.page,
                AppSpacing.page,
              ),
              child: Column(
                children: <Widget>[
                  OnboardingPager(page: _page, pageCount: _pages.length),
                  const SizedBox(height: AppSpacing.lg),
                  if (isLast)
                    _FinalActions(
                      strings: strings,
                      onGetStarted: _handleGetStarted,
                      onLookAround: _handleLookAround,
                    )
                  else
                    _StoryActions(
                      strings: strings,
                      isFirst: _page == 0,
                      onContinue: () => _goToPage(_page + 1),
                      onSkip: () => _goToPage(_pages.length - 1),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OnboardingPageBody extends StatelessWidget {
  const _OnboardingPageBody({
    required this.data,
    required this.service,
    required this.readAloudEnabled,
    required this.strings,
  });

  final OnboardingPageData data;
  final ReadAloudService service;
  final bool readAloudEnabled;
  final AppLocalizations strings;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.page),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          const SizedBox(height: AppSpacing.lg),
          ReadAloudHighlightedText(
            text: data.headline(strings),
            service: service,
            segmentId: 'headline',
            textAlign: TextAlign.center,
            style: textTheme.headlineMedium,
          ),
          const SizedBox(height: AppSpacing.md),
          ReadAloudHighlightedText(
            text: data.body(strings),
            service: service,
            segmentId: 'body',
            textAlign: TextAlign.center,
            style: textTheme.bodyLarge,
          ),
          if (data.safetyTitle != null && data.safetyPoints != null) ...<Widget>[
            const SizedBox(height: AppSpacing.md),
            FieldSafetyNotice(
              title: data.safetyTitle!(strings),
              points: <String>[
                for (final point in data.safetyPoints!) point(strings),
              ],
            ),
          ],
          const SizedBox(height: AppSpacing.lg),
          Center(
            child: ReadAloudControl(
              service: service,
              enabled: readAloudEnabled,
            ),
          ),
        ],
      ),
    );
  }
}

class _StoryActions extends StatelessWidget {
  const _StoryActions({
    required this.strings,
    required this.isFirst,
    required this.onContinue,
    required this.onSkip,
  });

  final AppLocalizations strings;
  final bool isFirst;
  final VoidCallback onContinue;
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        AquaButton(
          label: isFirst
              ? strings.onboardingShowMeHowAction
              : strings.onboardingContinueAction,
          onPressed: onContinue,
        ),
        if (isFirst) ...<Widget>[
          const SizedBox(height: AppSpacing.xs),
          AquaButton(
            label: strings.onboardingSkipAction,
            variant: AquaButtonVariant.ghost,
            expand: false,
            onPressed: onSkip,
          ),
        ],
      ],
    );
  }
}

class _FinalActions extends StatelessWidget {
  const _FinalActions({
    required this.strings,
    required this.onGetStarted,
    required this.onLookAround,
  });

  final AppLocalizations strings;
  final VoidCallback onGetStarted;
  final VoidCallback onLookAround;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        AquaButton(
          label: strings.onboardingGetStartedAction,
          onPressed: onGetStarted,
        ),
        const SizedBox(height: AppSpacing.xs),
        AquaButton(
          label: strings.onboardingLookAroundAction,
          variant: AquaButtonVariant.secondary,
          onPressed: onLookAround,
        ),
      ],
    );
  }
}
