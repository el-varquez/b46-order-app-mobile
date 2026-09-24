import '../entities/session.dart';

abstract interface class SessionRepository {
  Future<Session?> restore();
  Future<Session> loginWithPassword(String email, String password);
  Future<Session> loginWithOAuth(OAuthProvider provider);
  Future<bool> refresh();
  Future<void> logout();
  Future<Session> changePassword(String currentPassword, String newPassword);
  Session? get current;
}
