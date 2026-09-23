import 'dart:async';

import 'package:b46_order_app_mobile/core/errors/app_failure.dart';
import 'package:b46_order_app_mobile/app/bootstrap/google_method_channel_auth.dart';
import 'package:b46_order_app_mobile/features/authentication/data/sources/session_sources.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('com.b46.orderapp/google_auth');

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test('a second Google sign-in uses its own OAuth intent nonce', () async {
    final nonces = <String>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          expect(call.method, 'authenticate');
          final args = Map<String, Object?>.from(call.arguments as Map);
          final nonce = args['nonce'] as String;
          nonces.add(nonce);
          return 'token-for-$nonce';
        });

    final source = GoogleCredentialSource(
      native: const GoogleMethodChannelAuth(),
      serverClientId: 'web-client-id',
    );

    expect(
      await source.credential(nonce: 'first-intent-nonce'),
      'token-for-first-intent-nonce',
    );
    expect(
      await source.credential(nonce: 'second-intent-nonce'),
      'token-for-second-intent-nonce',
    );
    expect(nonces, ['first-intent-nonce', 'second-intent-nonce']);
  });

  test('Google cancellation is quiet and a new attempt can retry', () async {
    var attempts = 0;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          attempts++;
          if (attempts == 1) {
            throw PlatformException(code: 'cancelled');
          }
          final args = Map<String, Object?>.from(call.arguments as Map);
          return 'token-for-${args['nonce']}';
        });

    final source = GoogleCredentialSource(
      native: const GoogleMethodChannelAuth(),
      serverClientId: 'web-client-id',
    );
    await expectLater(
      source.credential(nonce: 'cancelled-intent'),
      throwsA(
        isA<AppFailure>().having(
          (failure) => failure.code,
          'code',
          FailureCode.cancelled,
        ),
      ),
    );
    expect(
      await source.credential(nonce: 'retry-intent'),
      'token-for-retry-intent',
    );
  });

  test('a provider failure leaves Google sign-in retryable', () async {
    var attempts = 0;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          attempts++;
          if (attempts == 1) {
            throw PlatformException(code: 'provider_error');
          }
          final args = Map<String, Object?>.from(call.arguments as Map);
          return 'token-for-${args['nonce']}';
        });
    final source = GoogleCredentialSource(
      native: const GoogleMethodChannelAuth(),
      serverClientId: 'web-client-id',
    );

    await expectLater(
      source.credential(nonce: 'failed-intent'),
      throwsA(
        isA<AppFailure>().having(
          (failure) => failure.code,
          'code',
          FailureCode.unavailable,
        ),
      ),
    );
    expect(
      await source.credential(nonce: 'retry-intent'),
      'token-for-retry-intent',
    );
  });

  test('an empty provider token cannot be sent to the backend', () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async => '');
    final source = GoogleCredentialSource(
      native: const GoogleMethodChannelAuth(),
      serverClientId: 'web-client-id',
    );

    await expectLater(
      source.credential(nonce: 'intent-nonce'),
      throwsA(
        isA<AppFailure>().having(
          (failure) => failure.code,
          'code',
          FailureCode.invalidOAuthCredential,
        ),
      ),
    );
  });

  test('a second tap cannot overlap an unfinished Google prompt', () async {
    final prompt = Completer<String>();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) => prompt.future);
    final source = GoogleCredentialSource(
      native: const GoogleMethodChannelAuth(),
      serverClientId: 'web-client-id',
    );

    final first = source.credential(nonce: 'first-intent');
    await expectLater(
      source.credential(nonce: 'second-intent'),
      throwsA(
        isA<AppFailure>().having(
          (failure) => failure.code,
          'code',
          FailureCode.invalidRequest,
        ),
      ),
    );
    prompt.complete('token-for-first-intent');
    expect(await first, 'token-for-first-intent');
  });
}
