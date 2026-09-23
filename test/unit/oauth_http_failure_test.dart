import 'package:b46_order_app_mobile/core/errors/app_failure.dart';
import 'package:b46_order_app_mobile/core/networking/json_http_client.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  test(
    'provider login transport failure is a retryable network failure',
    () async {
      final client = JsonHttpClient(
        baseUrl: Uri.parse('https://api.b46.test'),
        client: MockClient((request) async {
          throw http.ClientException('connection closed', request.url);
        }),
      );

      await expectLater(
        client.request(
          'POST',
          '/v1/auth/oauth/login',
          body: {'intent_id': 'intent-1', 'identity_token': 'provider-token'},
        ),
        throwsA(
          isA<AppFailure>().having(
            (failure) => failure.code,
            'code',
            FailureCode.network,
          ),
        ),
      );
    },
  );

  test('existing email requires explicit account linking', () async {
    final client = JsonHttpClient(
      baseUrl: Uri.parse('https://api.b46.test'),
      client: MockClient(
        (_) async => http.Response(
          '{"error":{"code":"IDENTITY_LINK_REQUIRED","message":"Sign in to the existing account before connecting this provider."}}',
          409,
        ),
      ),
    );

    await expectLater(
      client.request('POST', '/v1/auth/oauth/login'),
      throwsA(
        isA<AppFailure>().having(
          (failure) => failure.code,
          'code',
          FailureCode.identityLinkRequired,
        ),
      ),
    );
  });
}
