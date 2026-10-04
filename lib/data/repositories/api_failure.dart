/// A transport failure safe to classify without exposing a response body.
class ApiFailure implements Exception {
  const ApiFailure({this.statusCode, this.cause});

  final int? statusCode;
  final Object? cause;

  @override
  String toString() => 'ApiFailure';
}
