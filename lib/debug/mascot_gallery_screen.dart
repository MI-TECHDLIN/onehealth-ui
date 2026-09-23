import 'package:flutter/material.dart';

import '../core/mascot/aqua_mascot.dart';
import '../core/mascot/mascot_identity.dart';
import '../core/theme/tokens.dart';

class MascotGalleryScreen extends StatefulWidget {
  const MascotGalleryScreen({super.key});

  static const String routeName = '/debug/mascot';

  @override
  State<MascotGalleryScreen> createState() => _MascotGalleryScreenState();
}

class _MascotGalleryScreenState extends State<MascotGalleryScreen> {
  MascotMood _selectedMood = MascotMood.idle;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mascot mood gallery')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.page),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                MascotIdentity.displayName,
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'A code-drawn water companion for guidance, feedback, and '
                'celebration.',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: AppSpacing.lg),
              _PreviewStage(mood: _selectedMood),
              const SizedBox(height: AppSpacing.md),
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
              const SizedBox(height: AppSpacing.xl),
              Text(
                'Settled poses',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: AppSpacing.md),
              Wrap(
                spacing: AppSpacing.md,
                runSpacing: AppSpacing.md,
                children: MascotMood.values
                    .map((mood) => _MoodCard(mood: mood))
                    .toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _moodLabel(MascotMood mood) => switch (mood) {
    MascotMood.idle => 'Idle',
    MascotMood.guiding => 'Guiding',
    MascotMood.thinking => 'Thinking',
    MascotMood.celebrating => 'Celebrating',
    MascotMood.concerned => 'Concerned',
  };
}

class _PreviewStage extends StatelessWidget {
  const _PreviewStage({required this.mood});

  final MascotMood mood;

  @override
  Widget build(BuildContext context) {
    return Card(
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
        child: Center(child: AquaMascot(mood: mood, size: 190)),
      ),
    );
  }
}

class _MoodCard extends StatelessWidget {
  const _MoodCard({required this.mood});

  final MascotMood mood;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
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
}
