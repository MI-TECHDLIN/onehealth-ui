import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/app_router.dart';
import '../../core/theme/tokens.dart';
import '../../core/widgets/aqua_components.dart';
import '../../data/repositories/repository_models.dart';
import '../../l10n/generated/app_localizations.dart';

class AssessmentCelebrationData {
  const AssessmentCelebrationData({
    required this.record,
    required this.photoCount,
  });

  final AssessmentRecord record;
  final int photoCount;
}

class AssessmentCelebrationScreen extends StatelessWidget {
  const AssessmentCelebrationScreen({super.key, required this.data});

  final AssessmentCelebrationData data;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.page),
          child: Column(
            children: <Widget>[
              const Spacer(),
              RippleCelebrationOverlay(
                title: strings.assessCelebrationTitle,
                message: strings.assessCelebrationImpact(
                  data.photoCount,
                  data.record.siteCode,
                ),
                replayKey: data.record.id,
              ),
              const Spacer(),
              AquaButton(
                label: strings.assessCelebrationDoneAction,
                onPressed: () => context.go(AppRoutes.home),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
