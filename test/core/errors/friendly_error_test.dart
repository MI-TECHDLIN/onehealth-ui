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

    test('maps a sign-in 401 to invalid-credentials copy', () {
      final message = FriendlyError.fromFailure(statusCode: 401, isSignIn: true);
      expect(message, FriendlyError.invalidCredentials);
      expect(message, isNot(FriendlyError.sessionExpired));
    });

    test('maps dio and web client connectivity messages to no-connection copy', () {
      for (final error in [
        'DioException [connection error]: The connection errored: Connection failed',
        'DioException [connection timeout]: The request connection took longer than 0:00:10.000000',
        'DioException [receive timeout]: The request took longer than 0:00:30.000000',
        'DioException [send timeout]: The request took longer than 0:00:30.000000',
        'ClientException: XMLHttpRequest error., uri=https://example.com',
      ]) {
        expect(FriendlyError.fromFailure(error: error), FriendlyError.noConnection);
      }
    });

    test('maps connectivity exceptions by message when type names are minified', () {
      for (final error in const [
        _MinifiedException('TimeoutException: Future not completed'),
        _MinifiedException('HandshakeException: Connection terminated during handshake'),
        _MinifiedException('ClientException: Connection reset by peer'),
      ]) {
        expect(FriendlyError.fromFailure(error: error), FriendlyError.noConnection);
      }
    });

    test('does not report no-connection when the server returned a status', () {
      expect(
        FriendlyError.fromFailure(
          statusCode: 400,
          error: 'upstream SMTP connection timeout',
        ),
        FriendlyError.generic,
      );
      expect(
        FriendlyError.fromFailure(statusCode: 404, error: 'connection closed'),
        FriendlyError.generic,
      );
    });
  });
}

class _FakeSocketException implements Exception {
  const _FakeSocketException();

  @override
  String toString() => 'SocketException: Failed host lookup';
}

/// Mimics a release web build, where `runtimeType` is renamed (e.g.
/// 'minified:a7') but `toString()` still carries the original type name.
class _MinifiedException implements Exception {
  const _MinifiedException(this.message);

  final String message;

  @override
  String toString() => message;
}
