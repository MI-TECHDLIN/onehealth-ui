/// Static app metadata that does not need a plugin to read. Keep [version]
/// in sync with `pubspec.yaml`'s `version:` field by hand -- adding
/// `package_info_plus` just for a Settings footer was not worth a new
/// dependency to check against the Flutter/Dart pin in AGENTS.md.
abstract final class AppInfo {
  static const String version = '1.0.0';
}
