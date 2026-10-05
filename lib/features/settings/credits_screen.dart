import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/credits/third_party_credits.dart';
import '../../core/theme/tokens.dart';
import '../../l10n/generated/app_localizations.dart';

/// Third-party notices for the design and asset sources the app credits --
/// including the Lucide-derived evidence badge icons (ISC, no attribution
/// legally required, credited anyway per the design report).
class CreditsScreen extends StatelessWidget {
  const CreditsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(strings.creditsTitle)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.page),
          children: <Widget>[
            Text(strings.creditsIntro, style: Theme.of(context).textTheme.bodyLarge),
            const SizedBox(height: AppSpacing.md),
            for (final credit in ThirdPartyCredits.entries)
              Card(
                margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: ListTile(
                  title: Text(credit.name, style: Theme.of(context).textTheme.labelLarge),
                  subtitle: Text('${credit.notice}\n${credit.license}'),
                  isThreeLine: true,
                  trailing: const Icon(PhosphorIconsRegular.arrowSquareOut),
                  onTap: () => _open(credit.website),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _open(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      // A credit link failing to open is not worth a friendly-error
      // interruption on a static reference screen.
    }
  }
}
