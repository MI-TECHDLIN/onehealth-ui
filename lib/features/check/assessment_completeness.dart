import '../../data/repositories/repository_models.dart';

enum CompletenessField {
  upstreamPhoto,
  downstreamPhoto,
  channelForm,
  streambedType,
  bankType,
  waterFlow,
  waterAppearance,
  habitatObservations,
  marginVegetation,
}

class AssessmentCompleteness {
  const AssessmentCompleteness({
    required this.completed,
    required this.total,
    required this.mostValuableMissingField,
  });

  final int completed;
  final int total;
  final CompletenessField? mostValuableMissingField;

  double get fraction => total == 0 ? 1 : completed / total;
}

abstract final class AssessmentCompletenessMeter {
  static AssessmentCompleteness evaluate(AssessmentDraft draft) {
    final fields = <({CompletenessField field, bool present})>[
      (
        field: CompletenessField.upstreamPhoto,
        present: draft.attachments.containsKey(AssessmentMediaRole.upstreamPhoto),
      ),
      (
        field: CompletenessField.downstreamPhoto,
        present: draft.attachments.containsKey(AssessmentMediaRole.downstreamPhoto),
      ),
      (field: CompletenessField.channelForm, present: draft.channelForm != null),
      (
        field: CompletenessField.streambedType,
        present: draft.bottomChannelType != null,
      ),
      (field: CompletenessField.bankType, present: draft.banksChannelType != null),
      (field: CompletenessField.waterFlow, present: draft.waterFlow != null),
      (field: CompletenessField.waterAppearance, present: draft.waterColor != null),
      (
        field: CompletenessField.habitatObservations,
        present: draft.habitats.isNotEmpty,
      ),
      (
        field: CompletenessField.marginVegetation,
        present: draft.isVegetationCoveredLeft != null &&
            draft.isVegetationCoveredRight != null,
      ),
    ];
    final completed = fields.where((field) => field.present).length;
    CompletenessField? mostValuableMissingField;
    for (final field in fields) {
      if (!field.present) {
        mostValuableMissingField = field.field;
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
