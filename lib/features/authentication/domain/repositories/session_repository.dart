import '../entities/session.dart';

abstract interface class SessionRepository {
  Future<Session?> restore();
  Future<Session> loginWithPassword(String email, String password);
  Future<Session> loginWithOAuth(OAuthProvider provider);
  Future<bool> refresh();
  Future<void> logout();
  Session? get current;
}
