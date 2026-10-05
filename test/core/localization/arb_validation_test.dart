import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Runs `tool/l10n/validate_arb.py` (key parity, placeholder parity and
/// `@key` metadata hygiene across every `lib/l10n/app_*.arb` file) as part
/// of the normal test suite, since this repo has no CI workflow yet to run
/// it separately. Requires `python3` on PATH -- skips with a clear reason
/// if it is not available rather than failing the whole suite.
void main() {
  test('every locale ARB file matches the English template', () async {
    ProcessResult result;
    try {
      result = await Process.run('python3', <String>[
        'tool/l10n/validate_arb.py',
      ], workingDirectory: Directory.current.path);
    } on ProcessException {
      markTestSkipped('python3 is not available on PATH');
      return;
    }

    expect(
      result.exitCode,
      0,
      reason: 'stdout:\n${result.stdout}\nstderr:\n${result.stderr}',
    );
  });
}
