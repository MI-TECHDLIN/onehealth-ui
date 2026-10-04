import 'dart:convert';

import '../../core/mode/app_mode.dart';
import '../../core/settings/app_preferences.dart';
import 'api_failure.dart';
import 'assessment_content_source.dart';
import 'auth_repository.dart';
import 'live_api_client.dart';
import 'repository_models.dart';

abstract interface class AssessmentRepository {
  Future<Map<String, dynamic>> contentForLocale(String languageCode);
  Future<List<AssessmentDraft>> drafts();
  Future<List<AssessmentRecord>> history();
  Future<void> saveDraft(AssessmentDraft draft);
  Future<AssessmentRecord> submit(AssessmentDraft draft);
}

class AssessmentSubmissionOutcome {
  const AssessmentSubmissionOutcome.submitted(this.record) : queued = false;
  const AssessmentSubmissionOutcome.queued() : record = null, queued = true;

  final AssessmentRecord? record;
  final bool queued;
}

class QueuedAssessment {
  const QueuedAssessment({
    required this.draft,
    this.uploadedFileIds = const <AssessmentMediaRole, String>{},
    this.attempts = 0,
    this.lastAttemptAt,
  });

  final AssessmentDraft draft;
  final Map<AssessmentMediaRole, String> uploadedFileIds;
  final int attempts;
  final DateTime? lastAttemptAt;

  Duration get retryDelay {
    final exponent = attempts.clamp(0, 6) as int;
    return Duration(seconds: 5 * (1 << exponent));
  }

  Map<String, Object?> toJson() => <String, Object?>{
    'draft': draft.toJson(),
    'uploadedFileIds': <String, String>{
      for (final entry in uploadedFileIds.entries) entry.key.name: entry.value,
    },
    'attempts': attempts,
    if (lastAttemptAt != null)
      'lastAttemptAt': lastAttemptAt!.toUtc().toIso8601String(),
  };

  factory QueuedAssessment.fromJson(Map<String, dynamic> json) {
    final uploaded = json['uploadedFileIds'];
    return QueuedAssessment(
      draft: AssessmentDraft.fromJson(
        Map<String, dynamic>.from(json['draft'] as Map),
      ),
      uploadedFileIds: uploaded is Map
          ? <AssessmentMediaRole, String>{
              for (final entry in uploaded.entries)
                AssessmentMediaRole.values.byName(entry.key.toString()):
                    entry.value.toString(),
            }
          : const <AssessmentMediaRole, String>{},
      attempts: (json['attempts'] as num?)?.toInt() ?? 0,
      lastAttemptAt: DateTime.tryParse(json['lastAttemptAt']?.toString() ?? ''),
    );
  }
}

abstract interface class QueuedAssessmentRepository {
  Future<AssessmentSubmissionOutcome> submitOrQueue(AssessmentDraft draft);
  Future<List<QueuedAssessment>> queuedSubmissions();
  Future<void> retryQueued({bool force = false});
  Future<void> discardQueued(String clientSubmissionId);
}

class DemoAssessmentRepository implements AssessmentRepository {
  DemoAssessmentRepository({
    AppPreferences? preferences,
    AssessmentContentSource? contentSource,
    DateTime Function()? now,
  }) : _store = _LocalAssessmentStore(
         preferences: preferences ?? MemoryAppPreferences(),
         namespace: AppMode.demo.storageNamespace,
       ),
       _contentSource = contentSource ?? AssessmentContentSource(),
       _now = now ?? DateTime.now;

  final _LocalAssessmentStore _store;
  final AssessmentContentSource _contentSource;
  final DateTime Function() _now;

  @override
  Future<Map<String, dynamic>> contentForLocale(String languageCode) =>
      _contentSource.localized(languageCode);

  @override
  Future<List<AssessmentDraft>> drafts() => _store.readDrafts();

  @override
  Future<List<AssessmentRecord>> history() => _store.readHistory();

  @override
  Future<void> saveDraft(AssessmentDraft draft) => _store.saveDraft(draft);

  @override
  Future<AssessmentRecord> submit(AssessmentDraft draft) async {
    final history = await _store.readHistory();
    final record = AssessmentRecord(
      id: 'demo-${_now().toUtc().microsecondsSinceEpoch}',
      siteCode: draft.siteCode,
      siteKind: draft.siteKind,
      submittedAt: _now().toUtc(),
      latitude: draft.latitude,
      longitude: draft.longitude,
      username: 'demo',
      overallAssessment: draft.overallAssessment,
      habitats: draft.habitats,
      // Demo never uploads files, but the evidence badges only need to know
      // *which* media roles were captured, not a real server file id.
      fileIds: <AssessmentMediaRole, String>{
        for (final role in draft.attachments.keys) role: 'demo-${role.name}',
      },
    );
    await _store.writeHistory(<AssessmentRecord>[...history, record]);
    await _store.removeDraft(draft.id);
    return record;
  }
}

class LiveAssessmentRepository
    implements AssessmentRepository, QueuedAssessmentRepository {
  LiveAssessmentRepository({
    required LiveApiClient api,
    required AuthRepository auth,
    required AppPreferences preferences,
    AssessmentContentSource? contentSource,
    DateTime Function()? now,
  }) : _api = api,
       _auth = auth,
       _store = _LocalAssessmentStore(
         preferences: preferences,
         namespace: AppMode.live.storageNamespace,
       ),
       _contentSource = contentSource ?? AssessmentContentSource(),
       _now = now ?? DateTime.now;

  final LiveApiClient _api;
  final AuthRepository _auth;
  final _LocalAssessmentStore _store;
  final AssessmentContentSource _contentSource;
  final DateTime Function() _now;
  final Map<String, Future<AssessmentRecord>> _inFlight =
      <String, Future<AssessmentRecord>>{};

  @override
  Future<Map<String, dynamic>> contentForLocale(String languageCode) =>
      _contentSource.localized(languageCode);

  @override
  Future<List<AssessmentDraft>> drafts() => _store.readDrafts();

  @override
  Future<void> saveDraft(AssessmentDraft draft) => _store.saveDraft(draft);

  @override
  Future<List<AssessmentRecord>> history() async {
    final user = await _auth.currentUser();
    if (user == null) throw const ApiFailure(statusCode: 401);

    final establishedResponse = await _api.get('/api/citizens/submissions');
    final records = _ownedEstablishedRecords(
      establishedResponse.body,
      user.username,
    );

    final personalResponse = await _api.get(
      '/api/citizens/user-generated-sites/my-submissions',
    );
    final personalJson = jsonDecode(personalResponse.body);
    if (personalJson is List) {
      for (final value in personalJson.whereType<Map>()) {
        records.add(
          AssessmentRecord.fromApiJson(Map<String, dynamic>.from(value)),
        );
      }
    }
    records.sort((left, right) => right.submittedAt.compareTo(left.submittedAt));
    return List<AssessmentRecord>.unmodifiable(records);
  }

  @override
  Future<AssessmentRecord> submit(AssessmentDraft draft) async {
    final receipt = await _store.readReceipt(draft.id);
    if (receipt != null) return receipt;
    return _coalesced(draft.id, () => _performSubmit(draft));
  }

  Future<AssessmentRecord> _coalesced(
    String clientSubmissionId,
    Future<AssessmentRecord> Function() operation,
  ) {
    final active = _inFlight[clientSubmissionId];
    if (active != null) return active;
    late final Future<AssessmentRecord> future;
    future = operation().whenComplete(() {
      if (identical(_inFlight[clientSubmissionId], future)) {
        _inFlight.remove(clientSubmissionId);
      }
    });
    _inFlight[clientSubmissionId] = future;
    return future;
  }

  Future<AssessmentRecord> _performSubmit(
    AssessmentDraft draft, {
    Map<AssessmentMediaRole, String> uploadedFileIds =
        const <AssessmentMediaRole, String>{},
    Future<void> Function(Map<AssessmentMediaRole, String> uploadedIds)?
        onUpload,
  }) async {
    final uploadedIds = Map<AssessmentMediaRole, String>.of(uploadedFileIds);
    for (final entry in draft.attachments.entries) {
      if (uploadedIds.containsKey(entry.key)) continue;
      final response = await _api.putBytes(
        '/api/files',
        entry.value.bytes,
        queryParameters: <String, String>{'filename': entry.value.filename},
        contentType: entry.value.contentType,
      );
      final decoded = jsonDecode(response.body);
      if (decoded is! Map || decoded['id'] == null) {
        throw const ApiFailure();
      }
      uploadedIds[entry.key] = decoded['id'].toString();
      await onUpload?.call(Map<AssessmentMediaRole, String>.of(uploadedIds));
    }

    final payload = draft.toSubmissionJson(uploadedFileIds: uploadedIds);
    final path = draft.siteKind == SiteKind.research
        ? '/api/citizens/submit'
        : '/api/citizens/user-generated-sites/submit';
    final response = await _api.putJson(
      path,
      payload,
      headers: <String, String>{'X-Idempotency-Key': draft.id},
    );
    final user = await _auth.currentUser();

    Map<String, dynamic>? responseJson;
    if (response.body.trim().isNotEmpty) {
      try {
        final decoded = jsonDecode(response.body);
        if (decoded is Map) responseJson = Map<String, dynamic>.from(decoded);
      } on FormatException {
        // Some deployments return a plain identifier. The local receipt below
        // still reflects the accepted payload without exposing that raw body.
      }
    }
    final recordJson = <String, dynamic>{
      ...payload,
      'id': responseJson?['id'] ?? 'live-${_now().toUtc().microsecondsSinceEpoch}',
      'createdAt': responseJson?['createdAt'] ?? _now().toUtc().toIso8601String(),
      'user': responseJson?['user'] ?? user?.username,
      if (draft.siteKind == SiteKind.research) 'researchSite': draft.siteCode,
      if (draft.siteKind == SiteKind.userGenerated)
        'userGeneratedSite': draft.siteCode,
    };
    final record = AssessmentRecord.fromApiJson(recordJson);
    await _store.writeReceipt(draft.id, record);
    await _store.removeQueued(draft.id);
    await _store.removeDraft(draft.id);
    return record;
  }

  @override
  Future<AssessmentSubmissionOutcome> submitOrQueue(AssessmentDraft draft) async {
    var queued = QueuedAssessment(draft: draft);
    try {
      final receipt = await _store.readReceipt(draft.id);
      if (receipt != null) {
        return AssessmentSubmissionOutcome.submitted(receipt);
      }
      final record = await _coalesced(
        draft.id,
        () => _performSubmit(
          draft,
          onUpload: (uploadedIds) async {
            queued = QueuedAssessment(
              draft: draft,
              uploadedFileIds: uploadedIds,
            );
            await _store.saveQueued(queued);
          },
        ),
      );
      return AssessmentSubmissionOutcome.submitted(record);
    } catch (_) {
      await _store.saveQueued(queued);
      return const AssessmentSubmissionOutcome.queued();
    }
  }

  @override
  Future<List<QueuedAssessment>> queuedSubmissions() => _store.readQueued();

  @override
  Future<void> discardQueued(String clientSubmissionId) async {
    await _store.removeQueued(clientSubmissionId);
    await _store.removeDraft(clientSubmissionId);
  }

  @override
  Future<void> retryQueued({bool force = false}) async {
    final pending = await _store.readQueued();
    for (var queued in pending) {
      final lastAttempt = queued.lastAttemptAt;
      if (!force &&
          lastAttempt != null &&
          _now().toUtc().isBefore(lastAttempt.toUtc().add(queued.retryDelay))) {
        continue;
      }
      try {
        await _coalesced(
          queued.draft.id,
          () => _performSubmit(
            queued.draft,
            uploadedFileIds: queued.uploadedFileIds,
            onUpload: (uploadedIds) async {
              queued = QueuedAssessment(
                draft: queued.draft,
                uploadedFileIds: uploadedIds,
                attempts: queued.attempts,
                lastAttemptAt: queued.lastAttemptAt,
              );
              await _store.saveQueued(queued);
            },
          ),
        );
      } catch (_) {
        await _store.saveQueued(
          QueuedAssessment(
            draft: queued.draft,
            uploadedFileIds: queued.uploadedFileIds,
            attempts: queued.attempts + 1,
            lastAttemptAt: _now().toUtc(),
          ),
        );
      }
    }
  }
}

List<AssessmentRecord> _ownedEstablishedRecords(
  String responseBody,
  String username,
) {
  final decoded = jsonDecode(responseBody);
  if (decoded is! List) return <AssessmentRecord>[];
  final owned = <AssessmentRecord>[];
  for (final value in decoded) {
    if (value is! Map || value['user']?.toString() != username) continue;
    owned.add(AssessmentRecord.fromApiJson(Map<String, dynamic>.from(value)));
  }
  // The decoded global list is scoped to this function; only owned records
  // are returned, so other users' rows cannot reach a cache or caller.
  return owned;
}

class _LocalAssessmentStore {
  const _LocalAssessmentStore({
    required AppPreferences preferences,
    required String namespace,
  }) : _preferences = preferences,
       _draftsKey = '$namespace.assessment.drafts',
       _historyKey = '$namespace.assessment.history',
       _queuedKey = '$namespace.assessment.queued',
       _receiptsKey = '$namespace.assessment.receipts';

  final AppPreferences _preferences;
  final String _draftsKey;
  final String _historyKey;
  final String _queuedKey;
  final String _receiptsKey;

  Future<List<AssessmentDraft>> readDrafts() async {
    final values = await _readList(_draftsKey);
    return values
        .map(AssessmentDraft.fromJson)
        .toList(growable: false);
  }

  Future<void> saveDraft(AssessmentDraft draft) async {
    final values = await readDrafts();
    final updated = <AssessmentDraft>[
      ...values.where((candidate) => candidate.id != draft.id),
      draft,
    ];
    await _preferences.writeString(
      _draftsKey,
      jsonEncode(updated.map((value) => value.toJson()).toList()),
    );
  }

  Future<void> removeDraft(String id) async {
    final values = await readDrafts();
    await _preferences.writeString(
      _draftsKey,
      jsonEncode(
        values
            .where((candidate) => candidate.id != id)
            .map((value) => value.toJson())
            .toList(),
      ),
    );
  }

  Future<List<AssessmentRecord>> readHistory() async {
    final values = await _readList(_historyKey);
    return values
        .map(AssessmentRecord.fromJson)
        .toList(growable: false);
  }

  Future<void> writeHistory(List<AssessmentRecord> values) =>
      _preferences.writeString(
        _historyKey,
        jsonEncode(values.map((value) => value.toJson()).toList()),
      );

  Future<List<QueuedAssessment>> readQueued() async =>
      (await _readList(_queuedKey))
          .map(QueuedAssessment.fromJson)
          .toList(growable: false);

  Future<void> saveQueued(QueuedAssessment queued) async {
    final values = await readQueued();
    final updated = <QueuedAssessment>[
      ...values.where((value) => value.draft.id != queued.draft.id),
      queued,
    ];
    await _preferences.writeString(
      _queuedKey,
      jsonEncode(updated.map((value) => value.toJson()).toList()),
    );
  }

  Future<void> removeQueued(String id) async {
    final values = await readQueued();
    await _preferences.writeString(
      _queuedKey,
      jsonEncode(
        values
            .where((value) => value.draft.id != id)
            .map((value) => value.toJson())
            .toList(),
      ),
    );
  }

  Future<AssessmentRecord?> readReceipt(String clientSubmissionId) async {
    final values = await _readList(_receiptsKey);
    for (final value in values) {
      if (value['clientSubmissionId'] == clientSubmissionId) {
        return AssessmentRecord.fromJson(
          Map<String, dynamic>.from(value['record'] as Map),
        );
      }
    }
    return null;
  }

  Future<void> writeReceipt(
    String clientSubmissionId,
    AssessmentRecord record,
  ) async {
    final values = await _readList(_receiptsKey);
    final updated = <Map<String, Object?>>[
      ...values.where(
        (value) => value['clientSubmissionId'] != clientSubmissionId,
      ),
      <String, Object?>{
        'clientSubmissionId': clientSubmissionId,
        'record': record.toJson(),
      },
    ];
    await _preferences.writeString(_receiptsKey, jsonEncode(updated));
  }

  Future<List<Map<String, dynamic>>> _readList(String key) async {
    final raw = await _preferences.readString(key);
    if (raw == null || raw.isEmpty) return <Map<String, dynamic>>[];
    final decoded = jsonDecode(raw);
    if (decoded is! List) return <Map<String, dynamic>>[];
    return decoded
        .whereType<Map>()
        .map((value) => Map<String, dynamic>.from(value))
        .toList(growable: false);
  }
}
