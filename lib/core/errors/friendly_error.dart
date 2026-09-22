/// Maps raw failure information (HTTP status codes, exceptions, error
/// strings) to short, plain-language copy that is safe to show end users.
///
/// Nothing in the app should surface a raw exception message, stack trace,
/// or HTTP status code directly in user-facing UI. Route every API/sign-in
/// failure through [FriendlyError.fromFailure] (or extend it) instead.
library;

/// The kinds of failure this mapping understands. Extend this enum (and the
/// corresponding branch in [FriendlyError.fromFailure]) when a new failure
/// case needs its own copy.
enum FriendlyErrorKind {
  unauthorized,
  noConnection,
  payloadTooLarge,
  serverError,
  unknown,
}

/// Pure-Dart translation of failure information into user-facing copy.
abstract final class FriendlyError {
  static const String sessionExpired =
      "Your session timed out — log back in to keep going, your answers are saved.";

  static const String noConnection =
      "No connection right now. We'll try again once you're back online.";

  static const String payloadTooLarge =
      "That photo's a bit large. Try a smaller photo, or crop it down before uploading.";

  static const String serverError =
      "Something went wrong on our end — not yours. Try again in a moment.";

  static const String generic = "Something didn't go through. Please try again.";

  /// Returns the plain-language message for a failure.
  ///
  /// Pass whatever is available: an HTTP [statusCode], the raw [error]
  /// (an [Exception], an error object, or a message [String]), and/or an
  /// already-known [kind]. When [kind] is omitted it is inferred via
  /// [classify]. Unmapped/unrecognized failures fall back to [generic]
  /// rather than leaking the original message or status code.
  static String fromFailure({int? statusCode, Object? error, FriendlyErrorKind? kind}) {
    switch (kind ?? classify(statusCode: statusCode, error: error)) {
      case FriendlyErrorKind.unauthorized:
        return sessionExpired;
      case FriendlyErrorKind.noConnection:
        return noConnection;
      case FriendlyErrorKind.payloadTooLarge:
        return payloadTooLarge;
      case FriendlyErrorKind.serverError:
        return serverError;
      case FriendlyErrorKind.unknown:
        return generic;
    }
  }

  /// Classifies a failure from whatever information is available.
  ///
  /// Checked in order: HTTP status code first, then heuristics on [error]
  /// for connectivity failures (works across `dart:io` `SocketException`,
  /// `http`'s `ClientException`, `dio`'s `DioException`, and web's
  /// "Failed to fetch", without depending on those packages directly).
  static FriendlyErrorKind classify({int? statusCode, Object? error}) {
    if (statusCode == 401) return FriendlyErrorKind.unauthorized;
    if (statusCode == 413) return FriendlyErrorKind.payloadTooLarge;
    if (statusCode != null && statusCode >= 500 && statusCode < 600) {
      return FriendlyErrorKind.serverError;
    }
    if (_looksLikeConnectivityFailure(error)) return FriendlyErrorKind.noConnection;
    return FriendlyErrorKind.unknown;
  }

  static bool _looksLikeConnectivityFailure(Object? error) {
    if (error == null) return false;

    final typeName = error.runtimeType.toString();
    const connectivityTypeNames = [
      'SocketException',
      'ClientException',
      'TimeoutException',
      'HandshakeException',
      'ConnectionException',
    ];
    if (connectivityTypeNames.any(typeName.contains)) return true;

    final text = error.toString().toLowerCase();
    const connectivityPhrases = [
      'failed to fetch',
      'socketexception',
      'connection refused',
      'connection failed',
      'connection closed',
      'network is unreachable',
      'failed host lookup',
      'no internet',
    ];
    return connectivityPhrases.any(text.contains);
  }
}
