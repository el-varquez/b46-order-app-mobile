import 'package:b46_order_app_mobile/core/config/app_config.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('development accepts emulator HTTP URL', () {
    final config = AppConfig.parse(
      environmentValue: 'development',
      apiBaseUrlValue: 'http://10.0.2.2:8080',
      pollSeconds: 5,
    );
    expect(config.apiBaseUrl.host, '10.0.2.2');
    expect(config.pollInterval, const Duration(seconds: 5));
  });

  test('production rejects non-HTTPS URL', () {
    expect(
      () => AppConfig.parse(
        environmentValue: 'production',
        apiBaseUrlValue: 'http://api.example.test',
        pollSeconds: 5,
      ),
      throwsStateError,
    );
  });

  test('polling interval is bounded', () {
    expect(
      () => AppConfig.parse(
        environmentValue: 'test',
        apiBaseUrlValue: 'http://localhost:8080',
        pollSeconds: 1,
      ),
      throwsStateError,
    );
  });
}
