import '../../domain/entities/session.dart';
import '../../domain/repositories/session_repository.dart';

final class RestoreSession {
  const RestoreSession(this._repository);
  final SessionRepository _repository;
  Future<Session?> call() => _repository.restore();
}

final class PasswordLogin {
  const PasswordLogin(this._repository);
  final SessionRepository _repository;
  Future<Session> call(String email, String password) =>
      _repository.loginWithPassword(email, password);
}

final class OAuthLogin {
  const OAuthLogin(this._repository);
  final SessionRepository _repository;
  Future<Session> call(OAuthProvider provider) =>
      _repository.loginWithOAuth(provider);
}

final class SignOut {
  const SignOut(this._repository);
  final SessionRepository _repository;
  Future<void> call() => _repository.logout();
}

final class ChangeOwnPassword {
  const ChangeOwnPassword(this._repository);
  final SessionRepository _repository;
  Future<Session> call(String currentPassword, String newPassword) =>
      _repository.changePassword(currentPassword, newPassword);
}
