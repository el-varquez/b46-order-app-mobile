import '../../../../core/errors/app_failure.dart';
import '../../../../core/networking/json_http_client.dart';
import '../../../../core/storage/secure_key_value_store.dart';
import '../../domain/entities/session.dart';
import '../models/session_model.dart';

final class SessionRemoteSource {
  const SessionRemoteSource(this._http);
  final JsonHttpClient _http;

  Future<Session> passwordLogin(String email, String password) async {
    final response = await _http.request(
      'POST',
      '/v1/auth/password/login',
      body: {'email': email.trim(), 'password': password},
    );
    return SessionModel.fromData(response['data'] as Map<String, dynamic>)
        .session;
  }

  Future<({String registrationId, DateTime expiresAt})> beginRegistration(
    String name,
    String email,
    String password,
  ) async {
    final response = await _http.request(
      'POST',
      '/v1/auth/password/registrations',
      body: {'name': name.trim(), 'email': email.trim(), 'password': password},
    );
    return registrationAttempt(response);
  }

  Future<({String registrationId, DateTime expiresAt})> resendRegistration(
    String id,
  ) async {
    final response = await _http.request(
      'POST',
      '/v1/auth/password/registrations/resend',
      body: {'registration_id': id},
    );
    return registrationAttempt(response);
  }

  Future<Session> verifyRegistration(String id, String code) async {
    final response = await _http.request(
      'POST',
      '/v1/auth/password/registrations/verify',
      body: {'registration_id': id, 'code': code},
    );
    return SessionModel.fromData(response['data'] as Map<String, dynamic>)
        .session;
  }

  ({String registrationId, DateTime expiresAt}) registrationAttempt(
    Map<String, dynamic> response,
  ) {
    final data = response['data'] as Map<String, dynamic>;
    return (
      registrationId: data['registration_id'] as String,
      expiresAt: DateTime.parse(data['expires_at'] as String),
    );
  }

  Future<({String intentId, String nonce})> createOAuthIntent(
    OAuthProvider provider,
  ) async {
    final response = await _http.request(
      'POST',
      '/v1/auth/oauth/intents',
      body: {'provider': provider.name.toUpperCase()},
    );
    final data = response['data'] as Map<String, dynamic>;
    return (
      intentId: data['intent_id'] as String,
      nonce: data['nonce'] as String,
    );
  }

  Future<Session> completeOAuth(String intentId, String identityToken) async {
    final response = await _http.request(
      'POST',
      '/v1/auth/oauth/login',
      body: {'intent_id': intentId, 'identity_token': identityToken},
    );
    return SessionModel.fromData(response['data'] as Map<String, dynamic>)
        .session;
  }

  Future<Session> refresh(String refreshToken) async {
    final response = await _http.request(
      'POST',
      '/v1/auth/refresh',
      body: {'refresh_token': refreshToken},
    );
    return SessionModel.fromData(response['data'] as Map<String, dynamic>)
        .session;
  }

  Future<AppUser> currentUser(String accessToken) async {
    final response = await _http.request(
      'GET',
      '/v1/me',
      bearerToken: accessToken,
    );
    return SessionModel.userFromData(response['data'] as Map<String, dynamic>);
  }

  Future<void> logout(String accessToken) =>
      _http.request('POST', '/v1/auth/logout', bearerToken: accessToken);
}

abstract interface class OAuthCredentialSource {
  Future<String> credential({required String nonce});
  Future<void> clearProviderSession();
}

abstract interface class GoogleNativeAuth {
  Future<String?> authenticate({
    required String nonce,
    required String? clientId,
    required String serverClientId,
  });
  Future<void> signOut();
}

final class GoogleCredentialSource implements OAuthCredentialSource {
  GoogleCredentialSource({
    required GoogleNativeAuth native,
    this.clientId,
    this.serverClientId,
  }) : _native = native;

  final GoogleNativeAuth _native;
  final String? clientId;
  final String? serverClientId;
  bool _inFlight = false;

  @override
  Future<String> credential({required String nonce}) async {
    if (_inFlight) {
      throw const AppFailure(
        FailureCode.invalidRequest,
        'Google sign-in is already in progress.',
      );
    }
    if (nonce.isEmpty || serverClientId == null || serverClientId!.isEmpty) {
      throw const AppFailure(
        FailureCode.invalidOAuthCredential,
        'Google sign-in is not configured.',
      );
    }
    _inFlight = true;
    try {
      final token = await _native.authenticate(
        nonce: nonce,
        clientId: clientId,
        serverClientId: serverClientId!,
      );
      if (token == null || token.isEmpty) {
        throw const AppFailure(
          FailureCode.invalidOAuthCredential,
          'Google did not return a sign-in credential.',
        );
      }
      return token;
    } finally {
      _inFlight = false;
    }
  }

  @override
  Future<void> clearProviderSession() => _native.signOut();
}

final class SessionLocalSource {
  const SessionLocalSource(this._storage);
  static const _key = 'b46.session.v1';
  final SecureKeyValueStore _storage;

  Future<Session?> read() async {
    final value = await _storage.read(_key);
    if (value == null) return null;
    try {
      return SessionModel.decode(value).session;
    } on FormatException {
      await clear();
      return null;
    } on TypeError {
      await clear();
      return null;
    }
  }

  Future<void> write(Session session) =>
      _storage.write(_key, SessionModel(session).encode());

  Future<void> clear() => _storage.delete(_key);
}
