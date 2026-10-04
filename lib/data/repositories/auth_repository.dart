import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'api_failure.dart';
import 'jwt_session.dart';
import 'live_api_client.dart';
import 'repository_models.dart';
import 'token_store.dart';

abstract interface class AuthRepository {
  Future<AuthUser?> currentUser();
  Future<AuthUser> signIn({required String username, required String password});
  Future<void> signOut();
}

class DemoAuthRepository implements AuthRepository {
  AuthUser? _user = const AuthUser(
    username: 'demo',
    displayName: 'Stream explorer',
  );

  @override
  Future<AuthUser?> currentUser() async => _user;

  @override
  Future<AuthUser> signIn({
    required String username,
    required String password,
  }) async {
    _user = const AuthUser(
      username: 'demo',
      displayName: 'Stream explorer',
    );
    return _user!;
  }

  @override
  Future<void> signOut() async {
    _user = null;
  }
}

class LiveAuthRepository extends ChangeNotifier implements AuthRepository {
  LiveAuthRepository({
    required http.Client client,
    required TokenStore tokenStore,
    this.baseUri,
    DateTime Function()? now,
  }) : _client = client,
       _tokenStore = tokenStore,
       _now = now ?? DateTime.now;

  final http.Client _client;
  final TokenStore _tokenStore;
  final Uri? baseUri;
  final DateTime Function() _now;

  Uri get _apiBaseUri => baseUri ?? LiveApiClient.productionBaseUri;

  @override
  Future<AuthUser?> currentUser() async {
    final token = await _tokenStore.read();
    if (token == null || token.isEmpty) return null;
    try {
      final claims = decodeJwtClaims(token);
      final expiry = jwtExpiry(claims);
      if (!expiry.isAfter(_now().toUtc())) {
        await _tokenStore.clear();
        notifyListeners();
        return null;
      }
      return _userFromClaims(claims);
    } on FormatException {
      await _tokenStore.clear();
      notifyListeners();
      return null;
    }
  }

  @override
  Future<AuthUser> signIn({
    required String username,
    required String password,
  }) async {
    try {
      final response = await _client.post(
        _apiBaseUri.resolve('/api/auth/login'),
        headers: const <String, String>{'Content-Type': 'application/json'},
        body: jsonEncode(<String, String>{
          'username': username,
          'password': password,
        }),
      );
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw ApiFailure(statusCode: response.statusCode);
      }
      final token = response.body.trim();
      final claims = decodeJwtClaims(token);
      if (!jwtExpiry(claims).isAfter(_now().toUtc())) {
        throw const ApiFailure(statusCode: 401);
      }
      final user = _userFromClaims(claims, fallbackUsername: username);
      await _tokenStore.write(token);
      notifyListeners();
      return user;
    } on ApiFailure {
      rethrow;
    } catch (error) {
      throw ApiFailure(cause: error);
    }
  }

  @override
  Future<void> signOut() async {
    await _tokenStore.clear();
    notifyListeners();
  }

  Future<void> invalidateSession() async {
    await _tokenStore.clear();
    notifyListeners();
  }

  AuthUser _userFromClaims(
    Map<String, dynamic> claims, {
    String? fallbackUsername,
  }) {
    final username = claims['username']?.toString() ?? fallbackUsername;
    if (username == null || username.isEmpty) {
      throw const FormatException('Missing token username.');
    }
    final rawScopes = claims['scope'];
    final scopes = rawScopes is List
        ? rawScopes.map((scope) => scope.toString()).toList(growable: false)
        : rawScopes is String
        ? rawScopes.split(' ').where((scope) => scope.isNotEmpty).toList()
        : const <String>[];
    final name = claims['name']?.toString();
    return AuthUser(
      username: username,
      displayName: name == null || name.isEmpty ? username : name,
      email: claims['email']?.toString(),
      scopes: scopes,
    );
  }
}
