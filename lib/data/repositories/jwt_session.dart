import 'dart:convert';

Map<String, dynamic> decodeJwtClaims(String token) {
  final parts = token.split('.');
  if (parts.length != 3) throw const FormatException('Malformed token.');
  final payload = utf8.decode(base64Url.decode(base64Url.normalize(parts[1])));
  final decoded = jsonDecode(payload);
  if (decoded is! Map) throw const FormatException('Malformed token payload.');
  return Map<String, dynamic>.from(decoded);
}

DateTime jwtExpiry(Map<String, dynamic> claims) {
  final seconds = claims['exp'];
  if (seconds is! num) throw const FormatException('Missing token expiry.');
  return DateTime.fromMillisecondsSinceEpoch(
    seconds.toInt() * Duration.millisecondsPerSecond,
    isUtc: true,
  );
}

bool isJwtExpired(String token, DateTime now) =>
    !jwtExpiry(decodeJwtClaims(token)).isAfter(now.toUtc());
