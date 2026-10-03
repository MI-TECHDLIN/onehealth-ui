import 'package:flutter/material.dart';

import '../core/mascot/aqua_mascot.dart';
import '../core/mascot/mascot_identity.dart';
import '../core/mascot/ripple_controller.dart';
import '../core/theme/tokens.dart';
import '../core/widgets/aqua_components.dart';
import '../core/widgets/badge_crest.dart';
import '../core/widgets/friendly_error_banner.dart';

class MascotGalleryScreen extends StatefulWidget {
  const MascotGalleryScreen({super.key});

  static const String routeName = '/debug/mascot';

  @override
  State<MascotGalleryScreen> createState() => _MascotGalleryScreenState();
}

class _MascotGalleryScreenState extends State<MascotGalleryScreen> {
  final RippleController _ripple = RippleController();
  MascotMood _selectedMood = MascotMood.idle;
  RippleGesture _selectedGesture = RippleGesture.none;
  RippleViseme _viseme = RippleViseme.rest;
  int _pagerPage = 2;
  bool _chipSelected = true;
  bool _pictureSelected = true;

  @override
  void dispose() {
    _ripple.dispose();
    super.dispose();
  }

  void _playGesture(RippleGesture gesture) {
    setState(() => _selectedGesture = gesture);
    if (gesture == RippleGesture.talk) {
      _ripple.setViseme(_viseme);
    } else if (gesture == RippleGesture.none) {
      _ripple.stopGesture();
    } else {
      _ripple.playGesture(
        gesture,
        target: const Offset(0.9, -0.45),
        loop: true,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ripple + component gallery')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.page),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 920),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    '${MascotIdentity.displayName} render v2',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'Moods, gestures, visemes, reduced-motion assets, and reusable field components.',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  _PreviewStage(
                    mood: _selectedMood,
                    controller: _ripple,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text('Mood', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: AppSpacing.xs),
                  Wrap(
                    spacing: AppSpacing.xs,
                    runSpacing: AppSpacing.xs,
                    children: MascotMood.values
                        .map(
                          (mood) => ChoiceChip(
                            label: Text(_moodLabel(mood)),
                            selected: mood == _selectedMood,
                            onSelected: (_) => setState(() => _selectedMood = mood),
                          ),
                        )
                        .toList(),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text('Gesture', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: AppSpacing.xs),
                  Wrap(
                    spacing: AppSpacing.xs,
                    runSpacing: AppSpacing.xs,
                    children: RippleGesture.values
                        .map(
                          (gesture) => ChoiceChip(
                            label: Text(_gestureLabel(gesture)),
                            selected: gesture == _selectedGesture,
                            onSelected: (_) => _playGesture(gesture),
                          ),
                        )
                        .toList(),
                  ),
                  if (_selectedGesture == RippleGesture.talk) ...<Widget>[
                    const SizedBox(height: AppSpacing.sm),
                    Wrap(
                      spacing: AppSpacing.xs,
                      children: RippleViseme.values
                          .map(
                            (viseme) => ActionChip(
                              label: Text(viseme.name),
                              onPressed: () {
                                setState(() => _viseme = viseme);
                                _ripple.setViseme(viseme);
                              },
                            ),
                          )
                          .toList(),
                    ),
                  ],
                  const SizedBox(height: AppSpacing.xl),
                  _Section(
                    title: 'Settled moods',
                    child: Wrap(
                      spacing: AppSpacing.md,
                      runSpacing: AppSpacing.md,
                      children: MascotMood.values
                          .map((mood) => _MoodCard(mood: mood))
                          .toList(),
                    ),
                  ),
                  _Section(title: 'Buttons', child: _buttonGallery()),
                  _Section(
                    title: 'Progress and pager',
                    child: Column(
                      children: <Widget>[
                        const StepProgressBar(
                          sectionLabel: 'Your well-being',
                          currentStep: 5,
                          totalSteps: 9,
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        OnboardingPager(page: _pagerPage, pageCount: 5),
                        const SizedBox(height: AppSpacing.sm),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: <Widget>[
                            IconButton(
                              tooltip: 'Previous page',
                              onPressed: _pagerPage == 0
                                  ? null
                                  : () => setState(() => _pagerPage -= 1),
                              icon: const Icon(Icons.chevron_left_rounded),
                            ),
                            IconButton(
                              tooltip: 'Next page',
                              onPressed: _pagerPage == 4
                                  ? null
                                  : () => setState(() => _pagerPage += 1),
                              icon: const Icon(Icons.chevron_right_rounded),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  _Section(title: 'Filters and picture choices', child: _choicesGallery()),
                  _Section(
                    title: 'Recovery and loading',
                    child: Column(
                      children: <Widget>[
                        FriendlyErrorBanner(
                          title: 'We couldn’t sign you in',
                          message: 'That email or password didn’t match. Check it and try again.',
                          onRetry: () {},
                          onDismiss: () {},
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        const RippleLoadingState(label: 'Finding nearby streams…'),
                      ],
                    ),
                  ),
                  const _Section(
                    title: 'Celebration',
                    child: RippleCelebrationOverlay(
                      title: 'You added a new signal!',
                      message: 'Researchers can compare today’s observations with past visits.',
                    ),
                  ),
                  _Section(title: 'Badge family', child: _badgeGallery()),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buttonGallery() => Wrap(
    spacing: AppSpacing.md,
    runSpacing: AppSpacing.md,
    children: <Widget>[
      SizedBox(
        width: 260,
        child: AquaButton(label: 'Continue', onPressed: () {}),
      ),
      SizedBox(
        width: 260,
        child: AquaButton(
          label: 'Look around first',
          variant: AquaButtonVariant.secondary,
          onPressed: () {},
        ),
      ),
      SizedBox(
        width: 260,
        child: AquaButton(
          label: 'Learn more',
          variant: AquaButtonVariant.ghost,
          onPressed: () {},
        ),
      ),
      const SizedBox(
        width: 260,
        child: AquaButton(label: 'Submitting…', loading: true, onPressed: null),
      ),
      const SizedBox(
        width: 260,
        child: AquaButton(label: 'Disabled', onPressed: null),
      ),
    ],
  );

  Widget _choicesGallery() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: <Widget>[
      Wrap(
        spacing: AppSpacing.xs,
        runSpacing: AppSpacing.xs,
        children: <Widget>[
          AquaFilterChip(
            label: 'Needs data',
            selected: _chipSelected,
            onSelected: (value) => setState(() => _chipSelected = value),
          ),
          AquaFilterChip(label: 'Visited', selected: false, onSelected: (_) {}),
          const AquaFilterChip(label: 'Disabled', selected: false, onSelected: null),
        ],
      ),
      const SizedBox(height: AppSpacing.lg),
      Wrap(
        spacing: AppSpacing.md,
        runSpacing: AppSpacing.md,
        children: <Widget>[
          SizedBox(
            width: 220,
            child: PictureChoiceCard(
              image: const Icon(Icons.waves_rounded, size: 62, color: AppColors.deepWater),
              label: 'Flat channel',
              selected: _pictureSelected,
              onSelected: (value) => setState(() => _pictureSelected = value),
            ),
          ),
          SizedBox(
            width: 220,
            child: PictureChoiceCard(
              image: const Icon(Icons.landscape_rounded, size: 62, color: AppColors.sage),
              label: 'Steep banks',
              selected: false,
              onSelected: (_) {},
              multiSelect: true,
            ),
          ),
          const SizedBox(
            width: 220,
            child: PictureChoiceCard(
              image: Icon(Icons.image_not_supported_outlined, size: 62),
              label: 'Disabled choice',
              selected: false,
              enabled: false,
              onSelected: null,
            ),
          ),
        ],
      ),
      const SizedBox(height: AppSpacing.sm),
      NotSureButton(onPressed: () {}),
    ],
  );

  Widget _badgeGallery() => Wrap(
    spacing: AppSpacing.lg,
    runSpacing: AppSpacing.lg,
    crossAxisAlignment: WrapCrossAlignment.center,
    children: const <Widget>[
      BadgeCrest(
        name: 'First signal',
        criterion: 'Complete one check',
        icon: BadgeIcon.firstSignal,
        state: BadgeState.locked,
      ),
      BadgeCrest(
        name: 'Habitat eye',
        criterion: 'Revisit in another season',
        icon: BadgeIcon.habitatEye,
        discipline: BadgeDiscipline.habitat,
        state: BadgeState.unlocked,
      ),
      BadgeCrest(
        name: 'Clear view',
        criterion: 'Complete a photo set',
        icon: BadgeIcon.clearView,
        discipline: BadgeDiscipline.community,
        state: BadgeState.newBadge,
      ),
      BadgeUnlockReveal(
        badge: BadgeCrest(
          name: 'Stream explorer',
          criterion: 'Visit three streams',
          icon: BadgeIcon.streamExplorer,
          state: BadgeState.unlocked,
        ),
      ),
    ],
  );

  static String _moodLabel(MascotMood mood) => switch (mood) {
    MascotMood.idle => 'Idle',
    MascotMood.guiding => 'Guiding',
    MascotMood.thinking => 'Thinking',
    MascotMood.celebrating => 'Celebrating',
    MascotMood.concerned => 'Concerned',
  };

  static String _gestureLabel(RippleGesture gesture) => switch (gesture) {
    RippleGesture.none => 'None',
    RippleGesture.wave => 'Wave hello',
    RippleGesture.point => 'Point',
    RippleGesture.nod => 'Nod',
    RippleGesture.jump => 'Jump + splash',
    RippleGesture.swimIn => 'Swim in',
    RippleGesture.talk => 'Talk',
  };
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child});
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: AppSpacing.xl),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(title, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: AppSpacing.md),
        child,
      ],
    ),
  );
}

class _PreviewStage extends StatelessWidget {
  const _PreviewStage({required this.mood, required this.controller});
  final MascotMood mood;
  final RippleController controller;

  @override
  Widget build(BuildContext context) => Card(
    child: Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[
            Theme.of(context).colorScheme.primaryContainer,
            Theme.of(context).colorScheme.tertiaryContainer,
          ],
        ),
        borderRadius: BorderRadius.circular(AppRadii.lg),
      ),
      child: Center(
        child: AquaMascot(mood: mood, size: 210, controller: controller),
      ),
    ),
  );
}

class _MoodCard extends StatelessWidget {
  const _MoodCard({required this.mood});
  final MascotMood mood;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 164,
    child: Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          children: <Widget>[
            AquaMascot(mood: mood, size: 124),
            const SizedBox(height: AppSpacing.xs),
            Text(
              _MascotGalleryScreenState._moodLabel(mood),
              style: Theme.of(context).textTheme.labelLarge,
            ),
          ],
        ),
      ),
    ),
  );
}
