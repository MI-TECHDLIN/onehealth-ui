import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onehealth_ui/core/mode/app_mode.dart';
import 'package:onehealth_ui/data/repositories/repository_bundle.dart';
import 'package:onehealth_ui/data/repositories/repository_scope.dart';

void main() {
  testWidgets('Live mode cannot resolve the Demo repository bundle', (
    tester,
  ) async {
    RepositoryScope? captured;
    await tester.pumpWidget(
      RepositoryScope(
        mode: AppMode.live,
        repositories: null,
        child: MaterialApp(
          home: Builder(
            builder: (context) {
              captured = RepositoryScope.of(context);
              return const SizedBox();
            },
          ),
        ),
      ),
    );

    expect(captured?.mode, AppMode.live);
    expect(captured?.repositories, isNull);
  });

  testWidgets('Demo mode exposes only the local bundle', (tester) async {
    final demo = RepositoryBundle.demo();
    RepositoryScope? captured;
    await tester.pumpWidget(
      RepositoryScope(
        mode: AppMode.demo,
        repositories: demo,
        child: MaterialApp(
          home: Builder(
            builder: (context) {
              captured = RepositoryScope.of(context);
              return const SizedBox();
            },
          ),
        ),
      ),
    );

    expect(captured?.repositories, same(demo));
  });
}
