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

class LiveAssessmentRepository implements AssessmentRepository {
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
    final uploadedIds = <AssessmentMediaRole, String>{};
    for (final entry in draft.attachments.entries) {
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
    }

    final payload = draft.toSubmissionJson(uploadedFileIds: uploadedIds);
    final path = draft.siteKind == SiteKind.research
        ? '/api/citizens/submit'
        : '/api/citizens/user-generated-sites/submit';
    final response = await _api.putJson(path, payload);
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
    await _store.removeDraft(draft.id);
    return AssessmentRecord.fromApiJson(recordJson);
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
       _historyKey = '$namespace.assessment.history';

  final AppPreferences _preferences;
  final String _draftsKey;
  final String _historyKey;

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
