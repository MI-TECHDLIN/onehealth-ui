import 'repository_models.dart';

abstract interface class AssessmentRepository {
  Future<List<AssessmentRecord>> history();
  Future<void> saveDraft(AssessmentDraft draft);
  Future<AssessmentRecord> submit(AssessmentDraft draft);
}

class DemoAssessmentRepository implements AssessmentRepository {
  final List<AssessmentDraft> _drafts = <AssessmentDraft>[];
  final List<AssessmentRecord> _history = <AssessmentRecord>[];

  @override
  Future<List<AssessmentRecord>> history() async =>
      List<AssessmentRecord>.unmodifiable(_history);

  @override
  Future<void> saveDraft(AssessmentDraft draft) async {
    _drafts.removeWhere((candidate) => candidate.id == draft.id);
    _drafts.add(draft);
  }

  @override
  Future<AssessmentRecord> submit(AssessmentDraft draft) async {
    _drafts.removeWhere((candidate) => candidate.id == draft.id);
    final record = AssessmentRecord(
      id: 'demo-${_history.length + 1}',
      siteCode: draft.siteCode,
      submittedAt: DateTime.now().toUtc(),
    );
    _history.add(record);
    return record;
  }
}
