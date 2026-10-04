import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../app/app_router.dart';
import '../../core/drafts/draft_queue_status_source.dart';
import '../../core/errors/friendly_error.dart';
import '../../core/mascot/aqua_mascot.dart';
import '../../core/theme/tokens.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/friendly_error_banner.dart';
import '../../core/widgets/stream_health_timeline.dart';
import '../../data/repositories/repository_models.dart';
import '../../data/repositories/repository_scope.dart';
import '../../l10n/generated/app_localizations.dart';
import 'history_receipt_screen.dart';

enum _DraftStatus { draft, queued }

class _DraftEntry {
  const _DraftEntry({required this.draft, required this.status, required this.siteName});
  final AssessmentDraft draft;
  final _DraftStatus status;
  final String siteName;
}

class _HistoryEntry {
  const _HistoryEntry({required this.record, required this.siteName});
  final AssessmentRecord record;
  final String siteName;
}

enum _LoadState { loading, loaded, error }

/// "My Streams": every draft, queued, and submitted check the citizen has
/// made, newest first, with a plain receipt behind each submitted one.
class MyStreamsScreen extends StatefulWidget {
  const MyStreamsScreen({super.key, this.queueStatusSource});

  /// Reads an offline submission queue being built in parallel; defaults to
  /// a no-op so every draft reads as a plain draft until that lands.
  final DraftQueueStatusSource? queueStatusSource;

  @override
  State<MyStreamsScreen> createState() => _MyStreamsScreenState();
}

class _MyStreamsScreenState extends State<MyStreamsScreen> {
  bool _initialized = false;
  _LoadState _state = _LoadState.loading;
  String? _errorMessage;
  List<_DraftEntry> _drafts = const <_DraftEntry>[];
  List<_HistoryEntry> _history = const <_HistoryEntry>[];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _initialized = true;
      unawaited(_load());
    }
  }

  Future<void> _load() async {
    setState(() {
      _state = _LoadState.loading;
      _errorMessage = null;
    });
    final repositories = RepositoryScope.of(context).repositories;
    try {
      final drafts = await repositories.assessments.drafts();
      final history = await repositories.assessments.history();
      final sites = await repositories.sites.nearbySites();
      final queuedIds =
          await (widget.queueStatusSource ?? const NoOpDraftQueueStatusSource())
              .queuedDraftIds();

      final namesByCode = <String, String>{
        for (final site in sites) site.code: site.name,
      };

      final draftEntries = drafts
          .map(
            (draft) => _DraftEntry(
              draft: draft,
              status: queuedIds.contains(draft.id)
                  ? _DraftStatus.queued
                  : _DraftStatus.draft,
              siteName: namesByCode[draft.siteCode] ?? draft.siteCode,
            ),
          )
          .toList(growable: false);

      final historyEntries = history
          .map(
            (record) => _HistoryEntry(
              record: record,
              siteName: namesByCode[record.siteCode] ?? record.siteCode,
            ),
          )
          .toList()
        ..sort((a, b) => b.record.submittedAt.compareTo(a.record.submittedAt));

      if (!mounted) return;
      setState(() {
        _drafts = draftEntries;
        _history = historyEntries;
        _state = _LoadState.loaded;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _state = _LoadState.error;
        _errorMessage = FriendlyError.fromFailure(error: error);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    switch (_state) {
      case _LoadState.loading:
        return const Center(child: CircularProgressIndicator());
      case _LoadState.error:
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.page),
            child: FriendlyErrorBanner(
              message: _errorMessage ?? FriendlyError.generic,
              onRetry: () => unawaited(_load()),
            ),
          ),
        );
      case _LoadState.loaded:
        if (_drafts.isEmpty && _history.isEmpty) {
          return EmptyState(
            title: strings.streamsEmptyTitle,
            body: strings.streamsEmptyBody,
            actionLabel: strings.streamsEmptyAction,
            onAction: () => context.go(AppRoutes.home),
          );
        }
        return ListView(
          padding: const EdgeInsets.all(AppSpacing.page),
          children: <Widget>[
            if (_drafts.isNotEmpty) ...<Widget>[
              Text(
                strings.streamsSectionContinue,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: AppSpacing.sm),
              for (final entry in _drafts) ...<Widget>[
                _DraftCard(entry: entry, strings: strings),
                const SizedBox(height: AppSpacing.sm),
              ],
              const SizedBox(height: AppSpacing.md),
            ],
            if (_history.isNotEmpty) ...<Widget>[
              Text(
                strings.streamsSectionHistory,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: AppSpacing.sm),
              for (final entry in _history) ...<Widget>[
                _HistoryCard(entry: entry, strings: strings),
                const SizedBox(height: AppSpacing.sm),
              ],
            ],
          ],
        );
    }
  }
}

class _DraftCard extends StatelessWidget {
  const _DraftCard({required this.entry, required this.strings});

  final _DraftEntry entry;
  final AppLocalizations strings;

  @override
  Widget build(BuildContext context) {
    final statusLabel = entry.status == _DraftStatus.queued
        ? strings.streamsQueuedStatus
        : strings.streamsDraftStatus;
    return Card(
      child: ListTile(
        leading: Icon(
          entry.status == _DraftStatus.queued
              ? PhosphorIconsRegular.cloudArrowUp
              : PhosphorIconsRegular.notePencil,
        ),
        title: Text(entry.siteName),
        subtitle: Text(statusLabel),
        trailing: TextButton(
          onPressed: () => _continue(context),
          child: Text(strings.streamsContinueAction),
        ),
        onTap: () => _continue(context),
      ),
    );
  }

  void _continue(BuildContext context) {
    context.push(
      AppRoutes.checkAssess,
      extra: StreamSite(
        code: entry.draft.siteCode,
        name: entry.siteName,
        latitude: entry.draft.latitude,
        longitude: entry.draft.longitude,
        isUserGenerated: entry.draft.siteKind == SiteKind.userGenerated,
      ),
    );
  }
}

class _HistoryCard extends StatelessWidget {
  const _HistoryCard({required this.entry, required this.strings});

  final _HistoryEntry entry;
  final AppLocalizations strings;

  @override
  Widget build(BuildContext context) {
    final level = streamHealthLevelFromOverallAssessment(
      entry.record.overallAssessment,
    );
    return Card(
      child: ListTile(
        leading: AquaMascot(mood: MascotMood.idle, size: 40),
        title: Text(entry.siteName),
        subtitle: Text(_levelLabel(level)),
        trailing: const Icon(PhosphorIconsRegular.caretRight),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => HistoryReceiptScreen(
              record: entry.record,
              siteName: entry.siteName,
            ),
          ),
        ),
      ),
    );
  }

  String _levelLabel(StreamHealthLevel level) => switch (level) {
    StreamHealthLevel.good => strings.healthLevelGood,
    StreamHealthLevel.moderate => strings.healthLevelModerate,
    StreamHealthLevel.poor => strings.healthLevelPoor,
    StreamHealthLevel.unknown => strings.healthLevelUnknown,
  };
}
