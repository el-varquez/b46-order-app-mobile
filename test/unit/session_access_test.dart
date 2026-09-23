import 'dart:async';

import 'package:b46_order_app_mobile/core/networking/session_access.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('concurrent refresh callers share one in-flight action', () async {
    final completer = Completer<bool>();
    var calls = 0;
    final access = SessionAccess()
      ..configure(
        refreshSession: () {
          calls++;
          return completer.future;
        },
        clearSession: () async {},
      );
    final first = access.refreshOnce();
    final second = access.refreshOnce();
    expect(calls, 1);
    completer.complete(true);
    expect(await Future.wait([first, second]), [true, true]);
  });

  test(
    'clearing an invalid session removes access and notifies the app',
    () async {
      var cleared = 0;
      var invalidated = 0;
      final access = SessionAccess()
        ..configure(
          refreshSession: () async => false,
          clearSession: () async => cleared++,
        )
        ..setAccessToken('temporary-access-token')
        ..onInvalidated(() => invalidated++);

      await access.clear();

      expect(access.accessToken, isNull);
      expect(cleared, 1);
      expect(invalidated, 1);
    },
  );
}
