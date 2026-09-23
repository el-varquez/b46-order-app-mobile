enum AppEnvironment { development, test, staging, production }

final class AppConfig {
  const AppConfig({
    required this.environment,
    required this.apiBaseUrl,
    required this.pollInterval,
    this.googleClientId,
    this.googleServerClientId,
  });

  factory AppConfig.fromEnvironment() {
    const environmentValue = String.fromEnvironment(
      'APP_ENV',
      defaultValue: 'development',
    );
    const apiBaseUrlValue = String.fromEnvironment(
      'API_BASE_URL',
      defaultValue: 'http://10.0.2.2:8080',
    );
    const pollSeconds = int.fromEnvironment(
      'ORDER_POLL_SECONDS',
      defaultValue: 5,
    );
    const googleClientIdValue = String.fromEnvironment('GOOGLE_CLIENT_ID');
    const googleServerClientIdValue = String.fromEnvironment(
      'GOOGLE_SERVER_CLIENT_ID',
    );

    return AppConfig.parse(
      environmentValue: environmentValue,
      apiBaseUrlValue: apiBaseUrlValue,
      pollSeconds: pollSeconds,
      googleClientId: googleClientIdValue.isEmpty ? null : googleClientIdValue,
      googleServerClientId: googleServerClientIdValue.isEmpty
          ? null
          : googleServerClientIdValue,
    );
  }

  factory AppConfig.parse({
    required String environmentValue,
    required String apiBaseUrlValue,
    required int pollSeconds,
    String? googleClientId,
    String? googleServerClientId,
  }) {
    final environment = AppEnvironment.values.firstWhere(
      (value) => value.name == environmentValue,
      orElse: () => throw StateError('APP_ENV is invalid.'),
    );
    final apiBaseUrl = Uri.tryParse(apiBaseUrlValue);
    if (apiBaseUrl == null ||
        !apiBaseUrl.hasScheme ||
        !apiBaseUrl.hasAuthority ||
        !{'http', 'https'}.contains(apiBaseUrl.scheme)) {
      throw StateError('API_BASE_URL must be an absolute HTTP(S) URL.');
    }
    if (environment == AppEnvironment.production &&
        apiBaseUrl.scheme != 'https') {
      throw StateError('Production API_BASE_URL must use HTTPS.');
    }
    if (pollSeconds < 2 || pollSeconds > 300) {
      throw StateError('ORDER_POLL_SECONDS must be from 2 to 300.');
    }
    return AppConfig(
      environment: environment,
      apiBaseUrl: apiBaseUrl,
      pollInterval: Duration(seconds: pollSeconds),
      googleClientId: googleClientId,
      googleServerClientId: googleServerClientId,
    );
  }

  final AppEnvironment environment;
  final Uri apiBaseUrl;
  final Duration pollInterval;
  final String? googleClientId;
  final String? googleServerClientId;
}
