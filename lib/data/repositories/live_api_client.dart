import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import 'api_failure.dart';
import 'jwt_session.dart';
import 'token_store.dart';

class LiveApiClient {
  LiveApiClient({
    required http.Client client,
    required TokenStore tokenStore,
    this.baseUri = productionBaseUri,
    this.onUnauthorized,
    DateTime Function()? now,
  }) : _client = client,
       _tokenStore = tokenStore,
       _now = now ?? DateTime.now;

  static final Uri productionBaseUri = Uri.parse('https://api.enora-oah.eu/');

  final http.Client _client;
  final TokenStore _tokenStore;
  final Uri baseUri;
  final Future<void> Function()? onUnauthorized;
  final DateTime Function() _now;

  Future<http.Response> get(String path) => send('GET', path);

  Future<http.Response> putJson(
    String path,
    Map<String, Object?> body,
  ) => send('PUT', path, jsonBody: body);

  Future<http.Response> putBytes(
    String path,
    Uint8List bytes, {
    Map<String, String>? queryParameters,
    String? contentType,
  }) => send(
    'PUT',
    path,
    bytes: bytes,
    queryParameters: queryParameters,
    contentType: contentType,
  );

  Future<http.Response> send(
    String method,
    String path, {
    Map<String, Object?>? jsonBody,
    Uint8List? bytes,
    Map<String, String>? queryParameters,
    String? contentType,
  }) async {
    final token = await _tokenStore.read();
    if (token == null || token.isEmpty) {
      throw const ApiFailure(statusCode: 401);
    }
    try {
      if (isJwtExpired(token, _now())) {
        await _expireSession();
        throw const ApiFailure(statusCode: 401);
      }
    } on FormatException {
      await _expireSession();
      throw const ApiFailure(statusCode: 401);
    }

    final relative = Uri.parse(path);
    final uri = baseUri.resolveUri(relative).replace(
      queryParameters: queryParameters?.isEmpty ?? true
          ? relative.queryParameters
          : queryParameters,
    );
    final request = http.Request(method, uri)
      ..headers['Authorization'] = 'Bearer $token';
    if (jsonBody != null) {
      request.headers['Content-Type'] = 'application/json';
      request.body = jsonEncode(jsonBody);
    } else if (bytes != null) {
      if (contentType != null) request.headers['Content-Type'] = contentType;
      request.bodyBytes = bytes;
    }

    try {
      final streamed = await _client.send(request);
      final response = await http.Response.fromStream(streamed);
      if (response.statusCode == 401) {
        await _expireSession();
        throw const ApiFailure(statusCode: 401);
      }
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw ApiFailure(statusCode: response.statusCode);
      }
      return response;
    } on ApiFailure {
      rethrow;
    } catch (error) {
      throw ApiFailure(cause: error);
    }
  }

  Future<void> _expireSession() async {
    await _tokenStore.clear();
    await onUnauthorized?.call();
  }
}
