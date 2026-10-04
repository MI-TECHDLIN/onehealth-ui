import 'package:flutter/material.dart';

import '../../core/mascot/aqua_mascot.dart';
import '../../core/theme/tokens.dart';
import '../../l10n/generated/app_localizations.dart';

/// Stands in for `/sign-in` until the parallel `oah-auth-data` task lands its
/// real screen on `staging`. Keep this file disposable: it exists only so
/// the route resolves, and should be deleted (not merged alongside) once
/// that task's screen replaces it.
class SignInPlaceholderScreen extends StatelessWidget {
  const SignInPlaceholderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(strings.onboardingSignInPlaceholderTitle)),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.page),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              const AquaMascot(mood: MascotMood.guiding, size: 140),
              const SizedBox(height: AppSpacing.lg),
              Text(
                strings.onboardingSignInPlaceholderBody,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
