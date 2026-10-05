import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../app/app_router.dart';
import '../../core/errors/friendly_error.dart';
import '../../core/theme/tokens.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/friendly_error_banner.dart';
import '../../core/widgets/stream_health_timeline.dart';
import '../../data/repositories/repository_models.dart';
import '../../data/repositories/repository_scope.dart';
import '../../l10n/generated/app_localizations.dart';
import '../streams/history_receipt_screen.dart';

enum _ImpactLoadState { loading, loaded, error }

class _ImpactReceipt {
  const _ImpactReceipt({required this.record, required this.siteName});

  final AssessmentRecord record;
  final String siteName;
}

/// A factual summary of the signed-in citizen's or Demo guest's own saved
/// checks. It intentionally derives every number from assessment history.
class ImpactScreen extends StatefulWidget {
  const ImpactScreen({super.key});

  @override
  State<ImpactScreen> createState() => _ImpactScreenState();
}

class _ImpactScreenState extends State<ImpactScreen> {
  static const List<AssessmentMediaRole> _photoRoles = <AssessmentMediaRole>[
    AssessmentMediaRole.upstreamPhoto,
    AssessmentMediaRole.downstreamPhoto,
    AssessmentMediaRole.surroundingPhoto,
    AssessmentMediaRole.interestingPhoto,
  ];

  _ImpactLoadState _state = _ImpactLoadState.loading;
  List<_ImpactReceipt> _receipts = const <_ImpactReceipt>[];
  String? _errorMessage;
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    _initialized = true;
    unawaited(_load());
  }

  Future<void> _load() async {
    setState(() {
      _state = _ImpactLoadState.loading;
      _errorMessage = null;
    });
    final repositories = RepositoryScope.of(context).repositories;
    try {
      final history = await repositories.assessments.history();
      List<StreamSite> sites;
      try {
        sites = await repositories.sites.nearbySites();
      } catch (_) {
        // A saved receipt remains useful when Live site lookup is offline;
        // its stable site code is the factual fallback label.
        sites = const <StreamSite>[];
      }
      final namesByCode = <String, String>{
        for (final site in sites) site.code: site.name,
      };
      final receipts = history
          .map(
            (record) => _ImpactReceipt(
              record: record,
              siteName: namesByCode[record.siteCode] ?? record.siteCode,
            ),
          )
          .toList()
        ..sort((a, b) => b.record.submittedAt.compareTo(a.record.submittedAt));
      if (!mounted) return;
      setState(() {
        _receipts = receipts;
        _state = _ImpactLoadState.loaded;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _state = _ImpactLoadState.error;
        _errorMessage = FriendlyError.fromFailure(error: error);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    switch (_state) {
      case _ImpactLoadState.loading:
        return const Center(child: CircularProgressIndicator());
      case _ImpactLoadState.error:
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.page),
            child: FriendlyErrorBanner(
              message: _errorMessage ?? FriendlyError.generic,
              onRetry: () => unawaited(_load()),
            ),
          ),
        );
      case _ImpactLoadState.loaded:
        if (_receipts.isEmpty) {
          return EmptyState(
            title: strings.streamsEmptyTitle,
            body: strings.streamsEmptyBody,
            actionLabel: strings.streamsEmptyAction,
            onAction: () => context.go(AppRoutes.check),
          );
        }
        final records = _receipts.map((entry) => entry.record).toList();
        final streams = records.map((record) => record.siteCode).toSet().length;
        final photos = records.fold<int>(
          0,
          (total, record) =>
              total + _photoRoles.where(record.fileIds.containsKey).length,
        );
        return ListView(
          padding: const EdgeInsets.all(AppSpacing.page),
          children: <Widget>[
            Row(
              children: <Widget>[
                Expanded(
                  child: _ImpactStat(
                    icon: PhosphorIconsRegular.checkCircle,
                    value: '${records.length}',
                    label: strings.impactChecksSubmitted,
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: _ImpactStat(
                    icon: PhosphorIconsRegular.drop,
                    value: '$streams',
                    label: strings.profileStatsStreamsCovered,
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: _ImpactStat(
                    icon: PhosphorIconsRegular.camera,
                    value: '$photos',
                    label: strings.streamsReceiptPhotosLabel,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              strings.streamsSectionHistory,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: AppSpacing.sm),
            for (final receipt in _receipts) ...<Widget>[
              _ImpactReceiptCard(receipt: receipt),
              const SizedBox(height: AppSpacing.sm),
            ],
          ],
        );
    }
  }
}

class _ImpactStat extends StatelessWidget {
  const _ImpactStat({
    required this.icon,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xs,
        vertical: AppSpacing.md,
      ),
      child: Column(
        children: <Widget>[
          Icon(icon, color: Theme.of(context).colorScheme.primary),
          const SizedBox(height: AppSpacing.xs),
          Text(value, style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: AppSpacing.xxs),
          Text(
            label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.labelSmall,
          ),
        ],
      ),
    ),
  );
}

class _ImpactReceiptCard extends StatelessWidget {
  const _ImpactReceiptCard({required this.receipt});

  final _ImpactReceipt receipt;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final date = DateFormat.yMMMd(
      Localizations.localeOf(context).toString(),
    ).format(receipt.record.submittedAt.toLocal());
    final health = switch (
      streamHealthLevelFromOverallAssessment(receipt.record.overallAssessment)
    ) {
      StreamHealthLevel.good => strings.healthLevelGood,
      StreamHealthLevel.moderate => strings.healthLevelModerate,
      StreamHealthLevel.poor => strings.healthLevelPoor,
      StreamHealthLevel.unknown => strings.healthLevelUnknown,
    };
    return Card(
      child: ListTile(
        leading: const Icon(PhosphorIconsRegular.receipt),
        title: Text(receipt.siteName),
        subtitle: Text('$date · $health'),
        trailing: const Icon(PhosphorIconsRegular.caretRight),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => HistoryReceiptScreen(
              record: receipt.record,
              siteName: receipt.siteName,
            ),
          ),
        ),
      ),
    );
  }
}
