import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../errors/app_failure.dart';
import 'session_access.dart';

final class JsonHttpClient {
  JsonHttpClient({required Uri baseUrl, http.Client? client})
    : _baseUrl = baseUrl,
      _client = client ?? http.Client();

  final Uri _baseUrl;
  final http.Client _client;

  Future<Map<String, dynamic>> request(
    String method,
    String path, {
    Map<String, String>? query,
    Map<String, dynamic>? body,
    String? bearerToken,
  }) async {
    final uri = _baseUrl.resolve(path).replace(queryParameters: query);
    final headers = <String, String>{'Accept': 'application/json'};
    if (body != null) headers['Content-Type'] = 'application/json';
    if (bearerToken != null) headers['Authorization'] = 'Bearer $bearerToken';
    try {
      final request = http.Request(method, uri)..headers.addAll(headers);
      if (body != null) request.body = jsonEncode(body);
      final streamed = await _client
          .send(request)
          .timeout(const Duration(seconds: 15));
      final response = await http.Response.fromStream(streamed);
      final decoded = response.body.isEmpty
          ? <String, dynamic>{}
          : jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw _failure(decoded, response.statusCode);
      }
      return decoded;
    } on AppFailure {
      rethrow;
    } on SocketException catch (_) {
      throw const AppFailure(
        FailureCode.network,
        'Cannot reach B46. Check your connection and try again.',
      );
    } on http.ClientException catch (_) {
      throw const AppFailure(
        FailureCode.network,
        'Cannot reach B46. Check your connection and try again.',
      );
    } on FormatException catch (_) {
      throw const AppFailure(
        FailureCode.unknown,
        'B46 returned an invalid response.',
      );
    } on TimeoutException catch (_) {
      throw const AppFailure(
        FailureCode.network,
        'B46 took too long to respond. Try again.',
      );
    }
  }

  AppFailure _failure(Map<String, dynamic> body, int status) {
    final error = body['error'] is Map<String, dynamic>
        ? body['error'] as Map<String, dynamic>
        : const <String, dynamic>{};
    final meta = body['meta'] is Map<String, dynamic>
        ? body['meta'] as Map<String, dynamic>
        : const <String, dynamic>{};
    final code = error['code'] as String? ?? '';
    final message = error['message'] as String? ?? 'The request failed.';
    final failureCode = switch (code) {
      'INVALID_REQUEST' => FailureCode.invalidRequest,
      'UNAUTHENTICATED' || 'INVALID_CREDENTIALS' => FailureCode.unauthenticated,
      'FORBIDDEN' => FailureCode.forbidden,
      'ACCOUNT_DISABLED' => FailureCode.accountDisabled,
      'IDENTITY_LINK_REQUIRED' => FailureCode.identityLinkRequired,
      'INVALID_OAUTH_CREDENTIAL' => FailureCode.invalidOAuthCredential,
      'INVALID_OAUTH_INTENT' => FailureCode.invalidOAuthIntent,
      'CART_CHANGED' => FailureCode.cartChanged,
      'CATALOG_SNAPSHOT_EXPIRED' => FailureCode.snapshotExpired,
      'INVALID_TRANSITION' => FailureCode.invalidTransition,
      'CATALOG_UNAVAILABLE' || 'SERVICE_UNAVAILABLE' => FailureCode.unavailable,
      _ when status == 401 => FailureCode.unauthenticated,
      _ => FailureCode.unknown,
    };
    return AppFailure(
      failureCode,
      message,
      requestId: meta['request_id'] as String?,
    );
  }
}

final class AuthenticatedApiClient {
  AuthenticatedApiClient(this._http, this._session);

  final JsonHttpClient _http;
  final SessionAccess _session;

  Future<Map<String, dynamic>> request(
    String method,
    String path, {
    Map<String, String>? query,
    Map<String, dynamic>? body,
  }) async {
    try {
      return await _http.request(
        method,
        path,
        query: query,
        body: body,
        bearerToken: _session.accessToken,
      );
    } on AppFailure catch (failure) {
      if (failure.code == FailureCode.accountDisabled) {
        await _session.clear();
        rethrow;
      }
      if (failure.code != FailureCode.unauthenticated) rethrow;
      if (!await _session.refreshOnce()) {
        await _session.clear();
        rethrow;
      }
      try {
        return await _http.request(
          method,
          path,
          query: query,
          body: body,
          bearerToken: _session.accessToken,
        );
      } on AppFailure catch (retryFailure) {
        if (retryFailure.code == FailureCode.unauthenticated ||
            retryFailure.code == FailureCode.accountDisabled) {
          await _session.clear();
        }
        rethrow;
      }
    }
  }
}
