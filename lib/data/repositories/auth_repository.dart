import 'repository_models.dart';

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
