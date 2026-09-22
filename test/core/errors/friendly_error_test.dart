import 'package:flutter_test/flutter_test.dart';
import 'package:onehealth_ui/core/errors/friendly_error.dart';

void main() {
  group('FriendlyError.fromFailure', () {
    test('maps 401 to session-expired copy', () {
      expect(
        FriendlyError.fromFailure(statusCode: 401),
        FriendlyError.sessionExpired,
      );
    });

    test('maps 413 to payload-too-large copy', () {
      expect(
        FriendlyError.fromFailure(statusCode: 413),
        FriendlyError.payloadTooLarge,
      );
    });

    test('maps 5xx to server-error copy', () {
      expect(
        FriendlyError.fromFailure(statusCode: 500),
        FriendlyError.serverError,
      );
      expect(
        FriendlyError.fromFailure(statusCode: 503),
        FriendlyError.serverError,
      );
    });

    test('maps connectivity failures to no-connection copy', () {
      expect(
        FriendlyError.fromFailure(error: const _FakeSocketException()),
        FriendlyError.noConnection,
      );
      expect(
        FriendlyError.fromFailure(error: 'Failed to fetch'),
        FriendlyError.noConnection,
      );
    });

    test('falls back to a generic message for unmapped failures', () {
      expect(
        FriendlyError.fromFailure(statusCode: 418, error: 'teapot'),
        FriendlyError.generic,
      );
      expect(FriendlyError.fromFailure(), FriendlyError.generic);
    });

    test('never leaks the raw error text or status code in the fallback', () {
      final message = FriendlyError.fromFailure(
        statusCode: 999,
        error: 'super secret stack trace details',
      );
      expect(message, FriendlyError.generic);
      expect(message.contains('999'), isFalse);
      expect(message.toLowerCase().contains('secret'), isFalse);
    });

    test('an explicit kind overrides inference from statusCode/error', () {
      expect(
        FriendlyError.fromFailure(
          statusCode: 200,
          kind: FriendlyErrorKind.serverError,
        ),
        FriendlyError.serverError,
      );
    });
  });
}

class _FakeSocketException implements Exception {
  const _FakeSocketException();

  @override
  String toString() => 'SocketException: Failed host lookup';
}
