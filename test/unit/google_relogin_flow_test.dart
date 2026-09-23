import 'dart:convert';

import 'package:b46_order_app_mobile/app/bootstrap/google_method_channel_auth.dart';
import 'package:b46_order_app_mobile/core/networking/json_http_client.dart';
import 'package:b46_order_app_mobile/core/networking/session_access.dart';
import 'package:b46_order_app_mobile/core/storage/secure_key_value_store.dart';
import 'package:b46_order_app_mobile/features/authentication/data/repositories/session_repository_impl.dart';
import 'package:b46_order_app_mobile/features/authentication/data/sources/session_sources.dart';
import 'package:b46_order_app_mobile/features/authentication/domain/entities/session.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('com.b46.orderapp/google_auth');

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test(
    'logout then Google login binds a fresh token to the fresh intent',
    () async {
      final providerNonces = <String>[];
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
            if (call.method == 'signOut') return null;
            expect(call.method, 'authenticate');
            final args = Map<String, Object?>.from(call.arguments as Map);
            final nonce = args['nonce'] as String;
            providerNonces.add(nonce);
            return 'google-token-for-$nonce';
          });

      var issuedIntents = 0;
      var completedLogins = 0;
      final client = MockClient((request) async {
        if (request.url.path == '/v1/auth/oauth/intents') {
          issuedIntents++;
          return http.Response(
            jsonEncode({
              'data': {
                'intent_id': 'intent-$issuedIntents',
                'nonce': 'nonce-$issuedIntents',
              },
            }),
            201,
          );
        }
        if (request.url.path == '/v1/auth/oauth/login') {
          completedLogins++;
          final body = jsonDecode(request.body) as Map<String, dynamic>;
          expect(body['intent_id'], 'intent-$completedLogins');
          expect(
            body['identity_token'],
            'google-token-for-nonce-$completedLogins',
          );
          return http.Response(
            jsonEncode({'data': _sessionData(completedLogins)}),
            200,
          );
        }
        if (request.url.path == '/v1/auth/logout') {
          return http.Response('{}', 200);
        }
        throw StateError('Unexpected request path');
      });
      final repository = SessionRepositoryImpl(
        remote: SessionRemoteSource(
          JsonHttpClient(
            baseUrl: Uri.parse('https://api.b46.test'),
            client: client,
          ),
        ),
        local: SessionLocalSource(_MemoryStorage()),
        access: SessionAccess(),
        providers: {
          OAuthProvider.google: GoogleCredentialSource(
            native: const GoogleMethodChannelAuth(),
            serverClientId: 'web-client-id',
          ),
        },
      );

      final first = await repository.loginWithOAuth(OAuthProvider.google);
      await repository.logout();
      final second = await repository.loginWithOAuth(OAuthProvider.google);

      expect(first.accessToken, 'b46-access-1');
      expect(second.accessToken, 'b46-access-2');
      expect(providerNonces, ['nonce-1', 'nonce-2']);
      expect(issuedIntents, 2);
      expect(completedLogins, 2);
    },
  );
}

Map<String, Object?> _sessionData(int attempt) => {
  'access_token': 'b46-access-$attempt',
  'access_token_expires_at': '2099-01-01T00:00:00Z',
  'refresh_token': 'b46-refresh-$attempt',
  'refresh_token_expires_at': '2099-02-01T00:00:00Z',
  'user': {
    'user_id': 'customer-1',
    'name': 'Customer',
    'email': 'customer@example.test',
    'role': 'CUSTOMER',
    'status': 'ACTIVE',
  },
};

final class _MemoryStorage implements SecureKeyValueStore {
  final _values = <String, String>{};

  @override
  Future<String?> read(String key) async => _values[key];

  @override
  Future<void> write(String key, String value) async {
    _values[key] = value;
  }

  @override
  Future<void> delete(String key) async {
    _values.remove(key);
  }
}
