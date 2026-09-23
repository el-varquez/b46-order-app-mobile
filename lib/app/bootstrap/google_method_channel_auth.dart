import 'package:flutter/services.dart';

import '../../core/errors/app_failure.dart';
import '../../features/authentication/data/sources/session_sources.dart';

final class GoogleMethodChannelAuth implements GoogleNativeAuth {
  const GoogleMethodChannelAuth();

  static const _channel = MethodChannel('com.b46.orderapp/google_auth');

  @override
  Future<String?> authenticate({
    required String nonce,
    required String? clientId,
    required String serverClientId,
  }) async {
    try {
      return await _channel.invokeMethod<String>('authenticate', {
        'nonce': nonce,
        'clientId': clientId,
        'serverClientId': serverClientId,
      });
    } on PlatformException catch (error) {
      if (error.code == 'cancelled') {
        throw const AppFailure(FailureCode.cancelled, '');
      }
      if (error.code == 'not_configured') {
        throw const AppFailure(
          FailureCode.invalidOAuthCredential,
          'Google sign-in is not configured on this device.',
        );
      }
      throw const AppFailure(
        FailureCode.unavailable,
        'Google sign-in is unavailable. Please try again.',
      );
    } on MissingPluginException {
      throw const AppFailure(
        FailureCode.unavailable,
        'Google sign-in is unavailable on this device.',
      );
    }
  }

  @override
  Future<void> signOut() => _channel.invokeMethod<void>('signOut');
}
