import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

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
}

final class GoogleCredentialSource implements OAuthCredentialSource {
  GoogleCredentialSource({this.clientId, this.serverClientId});

  final String? clientId;
  final String? serverClientId;
  bool _initialized = false;

  @override
  Future<String> credential({required String nonce}) async {
    if (!_initialized) {
      await GoogleSignIn.instance.initialize(
        clientId: clientId,
        serverClientId: serverClientId,
        nonce: nonce,
      );
      _initialized = true;
    }
    final account = await GoogleSignIn.instance.authenticate();
    final token = account.authentication.idToken;
    if (token == null || token.isEmpty) {
      throw const FormatException('Google returned no identity token.');
    }
    return token;
  }
}

final class AppleCredentialSource implements OAuthCredentialSource {
  @override
  Future<String> credential({required String nonce}) async {
    final credential = await SignInWithApple.getAppleIDCredential(
      scopes: const [
        AppleIDAuthorizationScopes.email,
        AppleIDAuthorizationScopes.fullName,
      ],
      nonce: nonce,
    );
    final token = credential.identityToken;
    if (token == null || token.isEmpty) {
      throw const FormatException('Apple returned no identity token.');
    }
    return token;
  }
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
