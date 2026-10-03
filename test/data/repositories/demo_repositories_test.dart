import 'package:flutter_test/flutter_test.dart';
import 'package:onehealth_ui/data/repositories/repository_bundle.dart';
import 'package:onehealth_ui/data/repositories/repository_models.dart';

void main() {
  test(
    'Demo repositories provide local mock data and simulated submission',
    () async {
      final repositories = RepositoryBundle.demo();

      expect(await repositories.sites.nearbySites(), isNotEmpty);
      expect(
        await repositories.references.valuesFor('stream_assessments'),
        hasLength(3),
      );

      const draft = AssessmentDraft(
        id: 'draft-1',
        siteCode: 'DEMO-RIVER-01',
      );
      await repositories.assessments.saveDraft(draft);
      final result = await repositories.assessments.submit(draft);

      expect(result.id, startsWith('demo-'));
      expect(await repositories.assessments.history(), hasLength(1));
    },
  );
}
