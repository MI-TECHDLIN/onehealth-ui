import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:onehealth_ui/data/repositories/repository_models.dart';
import 'package:onehealth_ui/features/check/assessment_completeness.dart';

void main() {
  test('ranks the upstream photo as the most valuable missing optional field', () {
    const draft = AssessmentDraft(
      id: 'draft-1',
      siteCode: 'SITE-1',
      channelForm: 'U',
      waterFlow: 'NOR',
    );

    final completeness = AssessmentCompletenessMeter.evaluate(draft);

    expect(
      completeness.mostValuableMissingField,
      CompletenessField.upstreamPhoto,
    );
    expect(completeness.completed, 2);
    expect(completeness.total, 9);
  });

  test('moves to the next most valuable field once upstream is present', () {
    final draft = AssessmentDraft(
      id: 'draft-1',
      siteCode: 'SITE-1',
      attachments: <AssessmentMediaRole, AssessmentAttachment>{
        AssessmentMediaRole.upstreamPhoto: AssessmentAttachment(
          filename: 'upstream.jpg',
          bytes: Uint8List.fromList(<int>[1]),
        ),
      },
    );

    expect(
      AssessmentCompletenessMeter.evaluate(draft).mostValuableMissingField,
      CompletenessField.downstreamPhoto,
    );
  });
}
