import '../../../../core/errors/app_failure.dart';
import '../../../../core/networking/session_access.dart';
import '../../domain/entities/session.dart';
import '../../domain/repositories/session_repository.dart';
import '../../domain/repositories/registration_repository.dart';
import '../sources/session_sources.dart';

final class SessionRepositoryImpl
    implements SessionRepository, RegistrationRepository {
  SessionRepositoryImpl({
    required SessionRemoteSource remote,
    required SessionLocalSource local,
    required SessionAccess access,
    required Map<OAuthProvider, OAuthCredentialSource> providers,
  }) : _remote = remote,
       _local = local,
       _access = access,
       _providers = providers {
    _access.configure(refreshSession: refresh, clearSession: _clearLocal);
  }

  final SessionRemoteSource _remote;
  final SessionLocalSource _local;
  final SessionAccess _access;
  final Map<OAuthProvider, OAuthCredentialSource> _providers;
  Session? _current;

  @override
  Session? get current => _current;

  @override
  Future<Session?> restore() async {
    final stored = await _local.read();
    if (stored == null) return null;
    _set(stored);
    if (stored.refreshTokenExpiresAt.isBefore(DateTime.now().toUtc())) {
      await _clearLocal();
      return null;
    }
    var refreshed = false;
    if (stored.accessTokenExpiresAt.isBefore(DateTime.now().toUtc())) {
      try {
        if (!await refresh()) return null;
      } on AppFailure catch (failure) {
        if (failure.code == FailureCode.network) return _current;
        rethrow;
      }
      refreshed = true;
    }
    try {
      return await _verifyCurrentUser();
    } on AppFailure catch (failure) {
      if (failure.code == FailureCode.unauthenticated && !refreshed) {
        if (await refresh()) {
          try {
            return await _verifyCurrentUser();
          } on AppFailure catch (retryFailure) {
            if (retryFailure.code == FailureCode.network) return _current;
            await _access.clear();
            return null;
          }
        }
        return null;
      }
      if (failure.code == FailureCode.accountDisabled ||
          failure.code == FailureCode.unauthenticated) {
        await _access.clear();
        return null;
      }
      if (failure.code == FailureCode.network) return _current;
      rethrow;
    }
  }

  @override
  Future<Session> loginWithPassword(String email, String password) async {
    final session = await _remote.passwordLogin(email, password);
    await _save(session);
    return session;
  }

  @override
  Future<RegistrationAttempt> beginRegistration(
    String name,
    String email,
    String password,
  ) async {
    final result = await _remote.beginRegistration(name, email, password);
    return RegistrationAttempt(
      id: result.registrationId,
      expiresAt: result.expiresAt,
    );
  }

  @override
  Future<RegistrationAttempt> resendRegistration(String id) async {
    final result = await _remote.resendRegistration(id);
    return RegistrationAttempt(
      id: result.registrationId,
      expiresAt: result.expiresAt,
    );
  }

  @override
  Future<Session> verifyRegistration(String id, String code) async {
    final session = await _remote.verifyRegistration(id, code);
    await _save(session);
    return session;
  }

  @override
  Future<Session> loginWithOAuth(OAuthProvider provider) async {
    final source = _providers[provider];
    if (source == null) throw StateError('OAuth provider is not configured.');
    final intent = await _remote.createOAuthIntent(provider);
    final credential = await source.credential(nonce: intent.nonce);
    final session = await _remote.completeOAuth(intent.intentId, credential);
    await _save(session);
    return session;
  }

  @override
  Future<bool> refresh() async {
    final refreshToken = _current?.refreshToken;
    if (refreshToken == null) return false;
    try {
      final session = await _remote.refresh(refreshToken);
      await _save(session);
      return true;
    } on AppFailure catch (failure) {
      if (failure.code == FailureCode.network) rethrow;
      await _access.clear();
      return false;
    } on Object {
      await _access.clear();
      return false;
    }
  }

  @override
  Future<void> logout() async {
    final token = _current?.accessToken;
    try {
      if (token != null) await _remote.logout(token);
    } on Object {
      // Local secrets are cleared even when the remote logout is unreachable.
    }
    try {
      for (final source in _providers.values) {
        try {
          await source.clearProviderSession();
        } on Object {
          // Provider cleanup cannot keep a B46 session active.
        }
      }
    } finally {
      await _clearLocal();
    }
  }

  Future<void> _save(Session session) async {
    await _local.write(session);
    _set(session);
  }

  Future<Session?> _verifyCurrentUser() async {
    final session = _current;
    if (session == null) return null;
    final user = await _remote.currentUser(session.accessToken);
    if (!user.active) {
      await _access.clear();
      return null;
    }
    final verified = Session(
      accessToken: session.accessToken,
      accessTokenExpiresAt: session.accessTokenExpiresAt,
      refreshToken: session.refreshToken,
      refreshTokenExpiresAt: session.refreshTokenExpiresAt,
      user: user,
    );
    await _save(verified);
    return verified;
  }

  void _set(Session session) {
    _current = session;
    _access.setAccessToken(session.accessToken);
  }

  Future<void> _clearLocal() async {
    _current = null;
    _access.setAccessToken(null);
    await _local.clear();
  }
}
