import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

import '../../core/mode/app_mode.dart';
import '../../core/settings/app_preferences.dart';
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

/// Temporary offline authentication against bundled fictional accounts.
///
/// [useRemoteAuthentication] is the single switch back to the preserved API
/// sign-in path. Production currently leaves it false so judging does not
/// depend on the remote community server.
class LocalAccountsAuthRepository extends ChangeNotifier
    implements AuthRepository {
  LocalAccountsAuthRepository({
    required AppPreferences preferences,
    AssetBundle? assetBundle,
    this.remoteRepository,
    this.useRemoteAuthentication = false,
  }) : _preferences = preferences,
       _assetBundle = assetBundle ?? rootBundle;

  static const String accountsAsset = 'assets/data/local_accounts.json';
  static final String _signedInUsernameKey =
      '${AppMode.live.storageNamespace}.auth.localUsername';

  final AppPreferences _preferences;
  final AssetBundle _assetBundle;
  final AuthRepository? remoteRepository;
  final bool useRemoteAuthentication;
  List<_LocalAccount>? _accounts;

  @override
  Future<AuthUser?> currentUser() async {
    if (useRemoteAuthentication) return remoteRepository?.currentUser();
    final username = await _preferences.readString(_signedInUsernameKey);
    if (username == null) return null;
    final account = (await _loadAccounts()).where(
      (candidate) => candidate.username == username,
    );
    if (account.isEmpty) {
      await _preferences.remove(_signedInUsernameKey);
      return null;
    }
    return account.first.toUser();
  }

  @override
  Future<AuthUser> signIn({
    required String username,
    required String password,
  }) async {
    if (useRemoteAuthentication) {
      final remote = remoteRepository;
      if (remote == null) throw const ApiFailure(statusCode: 401);
      final user = await remote.signIn(username: username, password: password);
      notifyListeners();
      return user;
    }
    final identifier = username.trim().toLowerCase();
    final matches = (await _loadAccounts()).where(
      (account) =>
          (account.username.toLowerCase() == identifier ||
              account.email.toLowerCase() == identifier) &&
          account.password == password,
    );
    if (matches.isEmpty) throw const ApiFailure(statusCode: 401);
    final account = matches.first;
    await _preferences.writeString(_signedInUsernameKey, account.username);
    notifyListeners();
    return account.toUser();
  }

  @override
  Future<void> signOut() async {
    if (useRemoteAuthentication) {
      await remoteRepository?.signOut();
    } else {
      await _preferences.remove(_signedInUsernameKey);
    }
    notifyListeners();
  }

  Future<List<_LocalAccount>> _loadAccounts() async {
    final cached = _accounts;
    if (cached != null) return cached;
    final decoded = jsonDecode(await _assetBundle.loadString(accountsAsset));
    final values = decoded is Map<String, dynamic> ? decoded['accounts'] : null;
    if (values is! List) throw const FormatException('Invalid accounts asset.');
    return _accounts = values
        .whereType<Map>()
        .map((value) => _LocalAccount.fromJson(Map<String, dynamic>.from(value)))
        .toList(growable: false);
  }
}

class _LocalAccount {
  const _LocalAccount({
    required this.displayName,
    required this.username,
    required this.email,
    required this.password,
    required this.region,
    required this.memberSince,
    required this.preferredLanguage,
  });

  factory _LocalAccount.fromJson(Map<String, dynamic> json) => _LocalAccount(
    displayName: json['displayName'] as String,
    username: json['username'] as String,
    email: json['email'] as String,
    password: json['password'] as String,
    region: json['region'] as String,
    memberSince: DateTime.parse(json['memberSince'] as String).toUtc(),
    preferredLanguage: json['preferredLanguage'] as String,
  );

  final String displayName;
  final String username;
  final String email;
  final String password;
  final String region;
  final DateTime memberSince;
  final String preferredLanguage;

  AuthUser toUser() => AuthUser(
    username: username,
    displayName: displayName,
    email: email,
    region: region,
    memberSince: memberSince,
    preferredLanguage: preferredLanguage,
  );
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
