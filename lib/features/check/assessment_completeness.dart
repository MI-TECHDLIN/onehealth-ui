import '../../data/repositories/repository_models.dart';

class AssessmentCompleteness {
  const AssessmentCompleteness({
    required this.completed,
    required this.total,
    required this.mostValuableMissingField,
  });

  final int completed;
  final int total;
  final String? mostValuableMissingField;

  double get fraction => total == 0 ? 1 : completed / total;
}

abstract final class AssessmentCompletenessMeter {
  static AssessmentCompleteness evaluate(AssessmentDraft draft) {
    final fields = <({String name, bool present})>[
      (name: 'upstream photo', present: draft.attachments.containsKey(AssessmentMediaRole.upstreamPhoto)),
      (name: 'downstream photo', present: draft.attachments.containsKey(AssessmentMediaRole.downstreamPhoto)),
      (name: 'channel form', present: draft.channelForm != null),
      (name: 'streambed type', present: draft.bottomChannelType != null),
      (name: 'bank type', present: draft.banksChannelType != null),
      (name: 'water flow', present: draft.waterFlow != null),
      (name: 'water appearance', present: draft.waterColor != null),
      (name: 'habitat observations', present: draft.habitats.isNotEmpty),
      (
        name: 'margin vegetation',
        present: draft.isVegetationCoveredLeft != null &&
            draft.isVegetationCoveredRight != null,
      ),
    ];
    final completed = fields.where((field) => field.present).length;
    String? mostValuableMissingField;
    for (final field in fields) {
      if (!field.present) {
        mostValuableMissingField = field.name;
        break;
      }
    }
    return AssessmentCompleteness(
      completed: completed,
      total: fields.length,
      mostValuableMissingField: mostValuableMissingField,
    );
  }
}
