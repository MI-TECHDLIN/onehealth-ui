import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'core/mascot/aqua_mascot.dart';
import 'core/mascot/mascot_identity.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/tokens.dart';
import 'debug/mascot_gallery_screen.dart';

void main() {
  runApp(const OneHealthApp());
}

class OneHealthApp extends StatelessWidget {
  const OneHealthApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'OneAquaHealth',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.system,
      home: const _FoundationHomeScreen(),
      onGenerateRoute: (settings) {
        if (kDebugMode && settings.name == MascotGalleryScreen.routeName) {
          return MaterialPageRoute<void>(
            settings: settings,
            builder: (_) => const MascotGalleryScreen(),
          );
        }
        return null;
      },
    );
  }
}

class _FoundationHomeScreen extends StatelessWidget {
  const _FoundationHomeScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('OneAquaHealth')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.page),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  const AquaMascot(mood: MascotMood.idle, size: 184),
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    'Meet ${MascotIdentity.displayName}',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'The design-system foundation is ready for the onboarding '
                    'journey.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  if (kDebugMode) ...<Widget>[
                    const SizedBox(height: AppSpacing.lg),
                    FilledButton.icon(
                      onPressed: () => Navigator.of(
                        context,
                      ).pushNamed(MascotGalleryScreen.routeName),
                      icon: const Icon(Icons.water_drop_outlined),
                      label: const Text('Review all moods'),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
