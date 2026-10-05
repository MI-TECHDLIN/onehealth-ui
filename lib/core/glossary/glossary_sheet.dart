import 'package:flutter/material.dart';

import '../../l10n/generated/app_localizations.dart';
import '../audio/read_aloud_service.dart';
import '../mascot/ripple_controller.dart';
import '../theme/tokens.dart';
import '../widgets/read_aloud_control.dart';
import 'glossary_illustration.dart';
import 'glossary_terms.dart';

/// Opens the tap-to-explain bottom sheet for [term]: a plain-language
/// explanation, a small original illustration, and read-aloud -- per the
/// round-4 build brief's glossary requirement.
Future<void> showGlossarySheet(
  BuildContext context, {
  required GlossaryTerm term,
  required bool readAloudEnabled,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (context) => _GlossarySheetBody(
      term: term,
      readAloudEnabled: readAloudEnabled,
    ),
  );
}

class _GlossarySheetBody extends StatefulWidget {
  const _GlossarySheetBody({required this.term, required this.readAloudEnabled});

  final GlossaryTerm term;
  final bool readAloudEnabled;

  @override
  State<_GlossarySheetBody> createState() => _GlossarySheetBodyState();
}

class _GlossarySheetBodyState extends State<_GlossarySheetBody> {
  final RippleController _rippleController = RippleController();
  late final ReadAloudService _readAloud = ReadAloudService(
    rippleController: _rippleController,
  );
  bool _loaded = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_loaded) return;
    _loaded = true;
    final locale = Localizations.localeOf(context);
    _readAloud.load(
      narrationId: 'glossary_${widget.term.id}',
      locale: locale,
      assetBasePath: 'assets/audio/assessment',
    );
  }

  @override
  void dispose() {
    _readAloud.dispose();
    _rippleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.page,
          AppSpacing.sm,
          AppSpacing.page,
          AppSpacing.lg,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Center(
              child: GlossaryIllustration(termId: widget.term.id, size: 104),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              widget.term.title(strings),
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              widget.term.explanation(strings),
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: AppSpacing.md),
            ReadAloudControl(
              service: _readAloud,
              enabled: widget.readAloudEnabled,
            ),
          ],
        ),
      ),
    );
  }
}
