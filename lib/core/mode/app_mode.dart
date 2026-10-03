enum AppMode {
  demo,
  live;

  bool get isLive => this == AppMode.live;

  /// Prefix for any persisted mode-owned data, preventing cross-mode drafts.
  String get storageNamespace => 'oneaquahealth.$name';

  static AppMode fromStorage(String? value) =>
      value == AppMode.live.name ? AppMode.live : AppMode.demo;
}
