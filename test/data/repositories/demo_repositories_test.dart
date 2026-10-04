import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:onehealth_ui/core/settings/app_preferences.dart';
import 'package:onehealth_ui/data/repositories/repository_bundle.dart';
import 'package:onehealth_ui/data/repositories/repository_models.dart';

void main() {
  test(
    'Demo repositories provide local mock data and simulated submission',
    () async {
      final preferences = MemoryAppPreferences();
      final repositories = RepositoryBundle.demo(preferences: preferences);

      expect(await repositories.sites.nearbySites(), isNotEmpty);
      expect(
        await repositories.references.valuesFor('stream_assessments'),
        hasLength(3),
      );
      expect(
        await repositories.references.valuesFor('channel_forms'),
        hasLength(3),
      );
      expect(
        await repositories.assessments.contentForLocale('el'),
        contains('questions_1_3'),
      );

      const draft = AssessmentDraft(
        id: 'draft-1',
        siteCode: 'DEMO-RIVER-01',
      );
      await repositories.assessments.saveDraft(draft);
      final result = await repositories.assessments.submit(draft);

      expect(result.id, startsWith('demo-'));
      expect(await repositories.assessments.history(), hasLength(1));
      expect(
        await RepositoryBundle.demo(
          preferences: preferences,
        ).assessments.history(),
        hasLength(1),
      );
    },
  );

  test(
    'Demo submissions record which media roles were captured, for evidence badges',
    () async {
      final preferences = MemoryAppPreferences();
      final repositories = RepositoryBundle.demo(preferences: preferences);

      final draft = AssessmentDraft(
        id: 'draft-2',
        siteCode: 'DEMO-RIVER-01',
        attachments: <AssessmentMediaRole, AssessmentAttachment>{
          AssessmentMediaRole.upstreamPhoto: AssessmentAttachment(
            filename: 'upstream.jpg',
            bytes: Uint8List(0),
          ),
          AssessmentMediaRole.interestingPhoto: AssessmentAttachment(
            filename: 'bug.jpg',
            bytes: Uint8List(0),
          ),
        },
      );
      await repositories.assessments.submit(draft);

      final history = await repositories.assessments.history();
      expect(history.single.fileIds.keys, <AssessmentMediaRole>{
        AssessmentMediaRole.upstreamPhoto,
        AssessmentMediaRole.interestingPhoto,
      });

      // And it survives a reload from local storage, not just the in-memory
      // return value from `submit`.
      final reloaded = await RepositoryBundle.demo(
        preferences: preferences,
      ).assessments.history();
      expect(reloaded.single.fileIds.keys, history.single.fileIds.keys);
    },
  );
}
