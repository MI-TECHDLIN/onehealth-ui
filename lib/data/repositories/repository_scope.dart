import 'package:flutter/widgets.dart';

import '../../core/mode/app_mode.dart';
import 'repository_bundle.dart';

/// Exposes only repositories belonging to the active data mode.
///
/// The foundation intentionally has no Live bundle, so [repositories] is null
/// in Live mode until the later API-integration task supplies one. This makes
/// accidental production calls impossible while preserving app-wide mode UI.
class RepositoryScope extends InheritedWidget {
  const RepositoryScope({
    required this.mode,
    required this.repositories,
    required super.child,
    super.key,
  });

  final AppMode mode;
  final RepositoryBundle? repositories;

  static RepositoryScope of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<RepositoryScope>();
    assert(scope != null, 'No RepositoryScope found in context.');
    return scope!;
  }

  @override
  bool updateShouldNotify(RepositoryScope oldWidget) =>
      mode != oldWidget.mode || repositories != oldWidget.repositories;
}
