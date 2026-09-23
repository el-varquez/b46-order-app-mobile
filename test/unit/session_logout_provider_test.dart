import 'dart:convert';

import 'package:b46_order_app_mobile/core/networking/json_http_client.dart';
import 'package:b46_order_app_mobile/app/bootstrap/google_method_channel_auth.dart';
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

  test('logout clears B46 and Google provider sessions', () async {
    var providerSignOuts = 0;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          expect(call.method, 'signOut');
          providerSignOuts++;
          return null;
        });
    final storage = _MemoryStorage();
    final access = SessionAccess();
    final repository = _repository(storage, access);

    await repository.loginWithPassword('customer@example.test', 'password');
    expect(access.accessToken, 'b46-access');
    await repository.logout();

    expect(providerSignOuts, 1);
    expect(repository.current, isNull);
    expect(access.accessToken, isNull);
    expect(await storage.read('b46.session.v1'), isNull);
  });

  test(
    'provider sign-out failure cannot keep the B46 session active',
    () async {
      var providerSignOuts = 0;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
            providerSignOuts++;
            throw PlatformException(code: 'provider_error');
          });
      final storage = _MemoryStorage();
      final access = SessionAccess();
      final repository = _repository(storage, access);

      await repository.loginWithPassword('customer@example.test', 'password');
      await repository.logout();

      expect(providerSignOuts, 1);
      expect(repository.current, isNull);
      expect(access.accessToken, isNull);
      expect(await storage.read('b46.session.v1'), isNull);
    },
  );
}

SessionRepositoryImpl _repository(
  _MemoryStorage storage,
  SessionAccess access,
) {
  final httpClient = MockClient((request) async {
    if (request.url.path == '/v1/auth/password/login') {
      return http.Response(
        jsonEncode({
          'data': {
            'access_token': 'b46-access',
            'access_token_expires_at': '2030-01-01T00:00:00Z',
            'refresh_token': 'b46-refresh',
            'refresh_token_expires_at': '2030-02-01T00:00:00Z',
            'user': {
              'user_id': 'customer-1',
              'name': 'Customer',
              'email': 'customer@example.test',
              'role': 'CUSTOMER',
              'status': 'ACTIVE',
            },
          },
        }),
        200,
      );
    }
    if (request.url.path == '/v1/auth/logout') {
      return http.Response('{}', 200);
    }
    throw StateError('Unexpected request path');
  });
  return SessionRepositoryImpl(
    remote: SessionRemoteSource(
      JsonHttpClient(
        baseUrl: Uri.parse('https://api.b46.test'),
        client: httpClient,
      ),
    ),
    local: SessionLocalSource(storage),
    access: access,
    providers: {
      OAuthProvider.google: GoogleCredentialSource(
        native: const GoogleMethodChannelAuth(),
        serverClientId: 'web-client-id',
      ),
    },
  );
}

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
