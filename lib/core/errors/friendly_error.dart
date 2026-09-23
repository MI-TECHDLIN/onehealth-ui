/// Maps raw failure information (HTTP status codes, exceptions, error
/// strings) to short, plain-language copy that is safe to show end users.
///
/// Nothing in the app should surface a raw exception message, stack trace,
/// or HTTP status code directly in user-facing UI. Route every API/sign-in
/// failure through [FriendlyError.fromFailure] (or extend it) instead.
library;

/// The kinds of failure this mapping understands. Extend this enum (plus the
/// detection in [FriendlyError.classify] and the message branch in
/// [FriendlyError.fromFailure]) when a new failure case needs its own copy.
enum FriendlyErrorKind {
  invalidCredentials,
  unauthorized,
  noConnection,
  payloadTooLarge,
  serverError,
  unknown,
}

/// Pure-Dart translation of failure information into user-facing copy.
abstract final class FriendlyError {
  static const String invalidCredentials =
      "That email or password didn't match. Check them and try again.";

  static const String sessionExpired =
      "Your session timed out — log back in to keep going.";

  static const String noConnection =
      "No connection right now. Check your internet and try again.";

  static const String payloadTooLarge =
      "That file is too large. Try a smaller file, or crop it down before uploading.";

  static const String serverError =
      "Something went wrong on our end — not yours. Try again in a moment.";

  static const String generic = "Something didn't go through. Please try again.";

  /// Returns the plain-language message for a failure.
  ///
  /// Pass whatever is available: an HTTP [statusCode] and/or the raw
  /// [error] (an [Exception], an error object, or a message [String]). Set
  /// [isSignIn] when the failure came from a sign-in attempt so a 401 is
  /// reported as bad credentials rather than an expired session. The kind is
  /// inferred via [classify]. Unmapped/unrecognized failures fall back to
  /// [generic] rather than leaking the original message or status code.
  static String fromFailure({int? statusCode, Object? error, bool isSignIn = false}) {
    switch (classify(statusCode: statusCode, error: error, isSignIn: isSignIn)) {
      case FriendlyErrorKind.invalidCredentials:
        return invalidCredentials;
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
  /// Checked in order: HTTP status code first, then — only when there is no
  /// status code, since one proves the server was reached — heuristics on
  /// [error] for connectivity failures (works across `dart:io` `SocketException`,
  /// `http`'s `ClientException`, `dio`'s `DioException`, and web's
  /// "Failed to fetch", without depending on those packages directly).
  static FriendlyErrorKind classify({int? statusCode, Object? error, bool isSignIn = false}) {
    if (statusCode == 401) {
      return isSignIn ? FriendlyErrorKind.invalidCredentials : FriendlyErrorKind.unauthorized;
    }
    if (statusCode == 413) return FriendlyErrorKind.payloadTooLarge;
    if (statusCode != null && statusCode >= 500 && statusCode < 600) {
      return FriendlyErrorKind.serverError;
    }
    if (statusCode == null && _looksLikeConnectivityFailure(error)) {
      return FriendlyErrorKind.noConnection;
    }
    return FriendlyErrorKind.unknown;
  }

  static bool _looksLikeConnectivityFailure(Object? error) {
    if (error == null) return false;

    // Match on toString() rather than runtimeType: release web builds minify
    // type names, but exception messages keep their original type prefix.
    final text = error.toString().toLowerCase();
    const connectivityPhrases = [
      'failed to fetch',
      'socketexception',
      'clientexception',
      'timeoutexception',
      'handshakeexception',
      'connection refused',
      'connection failed',
      'connection error',
      'connection timeout',
      'receive timeout',
      'send timeout',
      'connection timed out',
      'xmlhttprequest error',
      'connection closed',
      'network is unreachable',
      'failed host lookup',
      'no internet',
    ];
    return connectivityPhrases.any(text.contains);
  }
}
