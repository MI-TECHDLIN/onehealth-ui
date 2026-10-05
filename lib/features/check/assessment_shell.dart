import 'dart:async';

import 'package:animations/animations.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../app/app_router.dart';
import '../../core/mascot/aqua_mascot.dart';
import '../../core/mascot/ripple_controller.dart';
import '../../core/motion/motion_preferences.dart';
import '../../core/settings/app_settings_controller.dart';
import '../../core/theme/tokens.dart';
import '../../core/widgets/aqua_components.dart';
import '../../data/assessment/assessment_protocol.dart';
import '../../data/repositories/repository_models.dart';
import '../../data/repositories/repository_scope.dart';
import '../../l10n/generated/app_localizations.dart';
import 'pages/feelings_page.dart';
import 'pages/multi_choice_question_page.dart';
import 'pages/numeric_text_question_page.dart';
import 'pages/overall_assessment_page.dart';
import 'pages/picture_choice_question_page.dart';
import 'pages/riparian_pages.dart';
import 'pages/single_choice_question_page.dart';
import 'pages/yes_no_question_page.dart';

typedef _PageBuilder = Widget Function(AssessmentDraft draft);

class _AssessmentPage {
  const _AssessmentPage({
    required this.sectionTitle,
    required this.builder,
    this.canProceed,
  });

  final String sectionTitle;
  final _PageBuilder builder;
  final bool Function(AssessmentDraft draft)? canProceed;
}

/// The round-4 question flow: one idea per screen, started from site
/// detail's "Check this stream" or the Check tab's site picker. Builds the
/// typed [AssessmentProtocol] for the current locale, resumes or creates a
/// per-site [AssessmentDraft] (saved on every answer), and hands off to
/// `/check/review` after the feelings step -- the next round's photo
/// capture and real review/submit pick up from there.
class AssessmentShell extends StatefulWidget {
  const AssessmentShell({
    super.key,
    required this.site,
    this.initialPage,
  });

  final StreamSite site;
  final int? initialPage;

  @override
  State<AssessmentShell> createState() => _AssessmentShellState();
}

class _AssessmentShellState extends State<AssessmentShell> {
  final RippleController _rippleController = RippleController();

  bool _initialized = false;
  bool _loading = true;
  AssessmentProtocol? _protocol;
  AssessmentDraft? _draft;
  List<_AssessmentPage> _pages = const <_AssessmentPage>[];
  int _pageIndex = 0;
  bool _reverse = false;
  MascotMood _mood = MascotMood.guiding;
  Timer? _moodResetTimer;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    _initialized = true;
    unawaited(_load());
  }

  @override
  void dispose() {
    _moodResetTimer?.cancel();
    _rippleController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final repositories = RepositoryScope.of(context).repositories;
    final locale = Localizations.localeOf(context);
    final content = await repositories.assessments.contentForLocale(
      locale.languageCode,
    );
    final protocol = AssessmentProtocol.fromContent(content);
    final drafts = await repositories.assessments.drafts();
    AssessmentDraft? existing;
    for (final candidate in drafts) {
      if (candidate.siteCode == widget.site.code) {
        existing = candidate;
        break;
      }
    }
    final draft = existing ?? _freshDraft();
    final pages = _buildPages(protocol);
    if (!mounted) return;
    setState(() {
      _protocol = protocol;
      _draft = draft;
      _pages = pages;
      _pageIndex = (widget.initialPage ?? 0).clamp(
        0,
        pages.length - 1,
      ).toInt();
      _loading = false;
    });
    if (widget.initialPage == null &&
        existing != null &&
        existing.answeredQuestionIds.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) unawaited(_offerResume(existing!));
      });
    }
  }

  AssessmentDraft _freshDraft() => AssessmentDraft(
    id: 'assess-${widget.site.code}-${DateTime.now().toUtc().microsecondsSinceEpoch}',
    siteCode: widget.site.code,
    siteKind: widget.site.isUserGenerated ? SiteKind.userGenerated : SiteKind.research,
    latitude: widget.site.latitude,
    longitude: widget.site.longitude,
    siteLatitude: widget.site.latitude,
    siteLongitude: widget.site.longitude,
  );

  Future<void> _offerResume(AssessmentDraft existing) async {
    final strings = AppLocalizations.of(context);
    final startOver = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(strings.assessResumeDraftTitle),
        content: Text(strings.assessResumeDraftBody(widget.site.name)),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(strings.assessResumeDraftStartOverAction),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(strings.assessResumeDraftContinueAction),
          ),
        ],
      ),
    );
    if (startOver == true && mounted) {
      final reset = _freshDraft().copyWith(id: existing.id);
      setState(() => _draft = reset);
      final repositories = RepositoryScope.of(context).repositories;
      unawaited(repositories.assessments.saveDraft(reset));
    }
  }

  List<_AssessmentPage> _buildPages(AssessmentProtocol protocol) {
    AssessmentQuestion q(String id) => protocol.questionById(id)!;
    final channelForm = q('channelForm');
    final bottomChannelType = q('bottomChannelType');
    final banksChannelType = q('banksChannelType');
    final habitats = q('habitats');
    final fallenBiomassTypes = q('fallenBiomassTypes');
    final waterFlow = q('waterFlow');
    final waterColor = q('waterColor');
    final waterAbstraction = q('waterAbstraction');
    final hasDams = q('hasDams');
    final pipes = q('pipes');
    final waterDischarge = q('waterDischarge');
    final construction = q('construction');
    final waterHeight = q('waterHeight');
    final imperviousLeft = q('imperviousAreasLeft');
    final imperviousRight = q('imperviousAreasRight');
    final vegLeftCover = q('isVegetationCoveredLeft');
    final vegRightCover = q('isVegetationCoveredRight');
    final vegLeftType = q('vegetationTypeLeft');
    final vegRightType = q('vegetationTypeRight');
    final invasiveGate = q('hasInvasivePlantSpecies');
    final invasiveText = q('invasivePlantSpecies');
    final vegCuts = q('recentVegetationCuts');
    final overallAssessment = q('overallAssessment');
    final feelingQuestions = <AssessmentQuestion>[
      q('joy'),
      q('serenity'),
      q('anger'),
      q('fear'),
    ];

    final step4 = protocol.steps.firstWhere((step) => step.step == 4).title;
    final step5 = protocol.steps.firstWhere((step) => step.step == 5).title;
    final step6 = protocol.steps.firstWhere((step) => step.step == 6).title;
    final step7 = protocol.steps.firstWhere((step) => step.step == 7).title;
    final step8 = protocol.steps.firstWhere((step) => step.step == 8).title;

    return <_AssessmentPage>[
      _AssessmentPage(
        sectionTitle: step4,
        builder: (draft) => PictureChoiceQuestionPage(
          question: channelForm,
          draft: draft,
          onSelected: (o) => _applyChoice(channelForm, o),
          rippleController: _rippleController,
          readAloudEnabled: _readAloudEnabled,
        ),
      ),
      _AssessmentPage(
        sectionTitle: step4,
        builder: (draft) => PictureChoiceQuestionPage(
          question: bottomChannelType,
          draft: draft,
          onSelected: (o) => _applyChoice(bottomChannelType, o),
          rippleController: _rippleController,
          readAloudEnabled: _readAloudEnabled,
        ),
      ),
      _AssessmentPage(
        sectionTitle: step4,
        builder: (draft) => PictureChoiceQuestionPage(
          question: banksChannelType,
          draft: draft,
          onSelected: (o) => _applyChoice(banksChannelType, o),
          rippleController: _rippleController,
          readAloudEnabled: _readAloudEnabled,
        ),
      ),
      _AssessmentPage(
        sectionTitle: step4,
        builder: (draft) => MultiChoiceQuestionPage(
          key: const ValueKey('habitats'),
          question: habitats,
          draft: draft,
          onChanged: (codes) => _applyMultiChoice(habitats, codes),
          rippleController: _rippleController,
          readAloudEnabled: _readAloudEnabled,
        ),
      ),
      _AssessmentPage(
        sectionTitle: step4,
        builder: (draft) => MultiChoiceQuestionPage(
          key: const ValueKey('fallenBiomassTypes'),
          question: fallenBiomassTypes,
          draft: draft,
          onChanged: (codes) => _applyMultiChoice(fallenBiomassTypes, codes),
          rippleController: _rippleController,
          readAloudEnabled: _readAloudEnabled,
        ),
      ),
      _AssessmentPage(
        sectionTitle: step4,
        builder: (draft) => SingleChoiceQuestionPage(
          question: waterFlow,
          draft: draft,
          onSelected: (o) => _applyChoice(waterFlow, o),
          rippleController: _rippleController,
          readAloudEnabled: _readAloudEnabled,
        ),
      ),
      _AssessmentPage(
        sectionTitle: step5,
        builder: (draft) => SingleChoiceQuestionPage(
          question: waterColor,
          draft: draft,
          onSelected: (o) => _applyChoice(waterColor, o),
          rippleController: _rippleController,
          readAloudEnabled: _readAloudEnabled,
        ),
      ),
      _AssessmentPage(
        sectionTitle: step5,
        builder: (draft) => YesNoQuestionPage(
          question: waterAbstraction,
          draft: draft,
          onChanged: (v, n) => _applyYesNo(waterAbstraction, v, n),
          rippleController: _rippleController,
          readAloudEnabled: _readAloudEnabled,
        ),
      ),
      _AssessmentPage(
        sectionTitle: step5,
        builder: (draft) => YesNoQuestionPage(
          question: hasDams,
          draft: draft,
          onChanged: (v, n) => _applyYesNo(hasDams, v, n),
          rippleController: _rippleController,
          readAloudEnabled: _readAloudEnabled,
        ),
      ),
      _AssessmentPage(
        sectionTitle: step5,
        builder: (draft) => YesNoQuestionPage(
          question: pipes,
          draft: draft,
          onChanged: (v, n) => _applyYesNo(pipes, v, n),
          rippleController: _rippleController,
          readAloudEnabled: _readAloudEnabled,
        ),
      ),
      _AssessmentPage(
        sectionTitle: step5,
        builder: (draft) => YesNoQuestionPage(
          question: waterDischarge,
          draft: draft,
          onChanged: (v, n) => _applyYesNo(waterDischarge, v, n),
          rippleController: _rippleController,
          readAloudEnabled: _readAloudEnabled,
        ),
      ),
      _AssessmentPage(
        sectionTitle: step5,
        builder: (draft) => YesNoQuestionPage(
          question: construction,
          draft: draft,
          onChanged: (v, n) => _applyYesNo(construction, v, n),
          rippleController: _rippleController,
          readAloudEnabled: _readAloudEnabled,
        ),
      ),
      _AssessmentPage(
        sectionTitle: step5,
        builder: (draft) => NumericTextQuestionPage(
          question: waterHeight,
          draft: draft,
          onChanged: (text) => _applyText(waterHeight, text),
          rippleController: _rippleController,
          readAloudEnabled: _readAloudEnabled,
        ),
      ),
      _AssessmentPage(
        sectionTitle: step6,
        builder: (draft) => DownstreamPrimerPage(rippleController: _rippleController),
      ),
      _AssessmentPage(
        sectionTitle: step6,
        builder: (draft) => ImperviousAreasPage(
          leftQuestion: imperviousLeft,
          rightQuestion: imperviousRight,
          draft: draft,
          onChanged: (question, v, n) => _applyYesNo(question, v, n),
          rippleController: _rippleController,
          readAloudEnabled: _readAloudEnabled,
        ),
      ),
      _AssessmentPage(
        sectionTitle: step6,
        builder: (draft) => VegetationCoveragePage(
          leftCoverQuestion: vegLeftCover,
          rightCoverQuestion: vegRightCover,
          leftTypeQuestion: vegLeftType,
          rightTypeQuestion: vegRightType,
          draft: draft,
          onCoverChanged: (question, v, n) => _applyYesNo(question, v, n),
          onTypeChanged: (question, o) => _applyChoice(question, o),
          rippleController: _rippleController,
          readAloudEnabled: _readAloudEnabled,
        ),
      ),
      _AssessmentPage(
        sectionTitle: step6,
        builder: (draft) => InvasiveSpeciesPage(
          question: invasiveGate,
          textQuestion: invasiveText,
          draft: draft,
          onChanged: (v, n) => _applyYesNo(invasiveGate, v, n),
          onTextChanged: (text) => _applyText(invasiveText, text),
          rippleController: _rippleController,
          readAloudEnabled: _readAloudEnabled,
        ),
      ),
      _AssessmentPage(
        sectionTitle: step6,
        builder: (draft) => YesNoQuestionPage(
          question: vegCuts,
          draft: draft,
          onChanged: (v, n) => _applyYesNo(vegCuts, v, n),
          rippleController: _rippleController,
          readAloudEnabled: _readAloudEnabled,
        ),
      ),
      _AssessmentPage(
        sectionTitle: step7,
        canProceed: (draft) => draft.satisfiesRequired(overallAssessment),
        builder: (draft) => OverallAssessmentPage(
          question: overallAssessment,
          draft: draft,
          onSelected: (o) => _applyChoice(overallAssessment, o),
          rippleController: _rippleController,
          readAloudEnabled: _readAloudEnabled,
        ),
      ),
      _AssessmentPage(
        sectionTitle: step8,
        builder: (draft) => FeelingsPage(
          questions: feelingQuestions,
          draft: draft,
          onChanged: (question, value) => _applyFeeling(question, value),
          rippleController: _rippleController,
          readAloudEnabled: _readAloudEnabled,
        ),
      ),
    ];
  }

  bool get _readAloudEnabled => AppSettingsScope.of(context).readAloudEnabled;

  void _mutateDraft(AssessmentDraft Function(AssessmentDraft draft) update) {
    final next = update(_draft!);
    setState(() => _draft = next);
    final repositories = RepositoryScope.of(context).repositories;
    unawaited(repositories.assessments.saveDraft(next));
  }

  void _applyChoice(AssessmentQuestion question, AssessmentOption? option) {
    _mutateDraft((draft) => draft.withChoice(question, option));
    _reactTo(notSure: option?.isNotSure ?? false);
  }

  void _applyMultiChoice(AssessmentQuestion question, List<String> codes) {
    _mutateDraft((draft) => draft.withMultiChoice(question, codes));
    _reactTo(notSure: false);
  }

  void _applyYesNo(AssessmentQuestion question, bool? value, bool notSure) {
    _mutateDraft((draft) => draft.withYesNo(question, value: value, notSure: notSure));
    _reactTo(notSure: notSure);
  }

  void _applyText(AssessmentQuestion question, String? text) {
    _mutateDraft((draft) => draft.withText(question, text));
  }

  void _applyFeeling(AssessmentQuestion question, int value) {
    _mutateDraft((draft) => draft.withFeeling(question, value));
  }

  void _reactTo({required bool notSure}) {
    _rippleController.playGesture(RippleGesture.nod);
    _moodResetTimer?.cancel();
    if (!notSure) {
      if (_mood != MascotMood.guiding) setState(() => _mood = MascotMood.guiding);
      return;
    }
    setState(() => _mood = MascotMood.thinking);
    _moodResetTimer = Timer(const Duration(milliseconds: 1400), () {
      if (mounted) setState(() => _mood = MascotMood.guiding);
    });
  }

  void _goNext() {
    final page = _pages[_pageIndex];
    if (page.canProceed != null && !page.canProceed!(_draft!)) return;
    if (_pageIndex == _pages.length - 1) {
      _handOff();
      return;
    }
    setState(() {
      _reverse = false;
      _pageIndex += 1;
    });
  }

  void _goBack() {
    if (_pageIndex == 0) {
      unawaited(_confirmExit());
      return;
    }
    setState(() {
      _reverse = true;
      _pageIndex -= 1;
    });
  }

  void _handOff() {
    context.go(AppRoutes.checkPhotos, extra: _draft);
  }

  Future<void> _confirmExit() async {
    final strings = AppLocalizations.of(context);
    final exit = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(strings.assessExitConfirmTitle),
        content: Text(strings.assessExitConfirmBody),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(strings.assessExitConfirmKeepGoingAction),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(strings.assessExitConfirmSaveAction),
          ),
        ],
      ),
    );
    if (exit == true && mounted) context.go(AppRoutes.home);
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    if (_loading || _draft == null) {
      return Scaffold(
        body: SafeArea(
          child: Center(
            child: RippleLoadingState(label: strings.assessLoadingLabel),
          ),
        ),
      );
    }

    final reduceMotion = MotionPreferences.reduceMotionOf(context);
    final page = _pages[_pageIndex];
    final canProceed = page.canProceed?.call(_draft!) ?? true;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.page,
                AppSpacing.sm,
                AppSpacing.page,
                0,
              ),
              child: Row(
                children: <Widget>[
                  AquaMascot(
                    mood: _mood,
                    controller: _rippleController,
                    size: 56,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: StepProgressBar(
                      sectionLabel: page.sectionTitle,
                      currentStep: _pageIndex + 1,
                      totalSteps: _pages.length,
                    ),
                  ),
                  IconButton(
                    tooltip: strings.assessSaveAndExitAction,
                    onPressed: () => unawaited(_confirmExit()),
                    icon: const Icon(PhosphorIconsRegular.signOut),
                  ),
                ],
              ),
            ),
            Expanded(
              child: PageTransitionSwitcher(
                reverse: _reverse,
                duration: reduceMotion ? AppMotion.reduced : AppMotion.page,
                transitionBuilder: (child, primary, secondary) => reduceMotion
                    ? FadeTransition(opacity: primary, child: child)
                    : SharedAxisTransition(
                        animation: primary,
                        secondaryAnimation: secondary,
                        transitionType: SharedAxisTransitionType.horizontal,
                        child: child,
                      ),
                child: KeyedSubtree(
                  key: ValueKey<int>(_pageIndex),
                  child: page.builder(_draft!),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.page),
              child: Row(
                children: <Widget>[
                  if (_pageIndex > 0)
                    Expanded(
                      child: AquaButton(
                        label: strings.assessBackAction,
                        variant: AquaButtonVariant.secondary,
                        onPressed: _goBack,
                      ),
                    ),
                  if (_pageIndex > 0) const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: AquaButton(
                      label: strings.assessNextAction,
                      onPressed: canProceed ? _goNext : null,
                    ),
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
