/// A seam for an offline submission queue that is being built in parallel.
///
/// My Streams needs to tell a plain saved draft apart from one that is
/// queued for upload and waiting to go out, but no queue implementation
/// exists in this tree yet. Consumers take this interface instead of a
/// concrete queue so they degrade gracefully (every draft reads as a plain
/// draft) until a real implementation is wired in -- at that point, pass it
/// in wherever this is constructed today and no call site needs to change.
abstract interface class DraftQueueStatusSource {
  /// Draft ids (matching `AssessmentDraft.id`) currently queued for upload.
  Future<Set<String>> queuedDraftIds();
}

class NoOpDraftQueueStatusSource implements DraftQueueStatusSource {
  const NoOpDraftQueueStatusSource();

  @override
  Future<Set<String>> queuedDraftIds() async => const <String>{};
}
