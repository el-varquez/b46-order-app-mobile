import '../../../../core/networking/json_http_client.dart';
import '../../domain/entities/cashier_account.dart';

final class AdminCashierRemoteSource {
  const AdminCashierRemoteSource(this._api);
  final AuthenticatedApiClient _api;

  Future<List<CashierAccount>> list({CashierAccountStatus? status}) async {
    final response = await _api.request(
      'GET',
      '/v1/admin/cashiers',
      query: status == null ? null : {'status': status.name.toUpperCase()},
    );
    final data = response['data'] as Map<String, dynamic>;
    return (data['cashiers'] as List<dynamic>)
        .map((item) => _account(item as Map<String, dynamic>))
        .toList(growable: false);
  }

  Future<CashierAccount> detail(String id) async {
    final response = await _api.request('GET', '/v1/admin/cashiers/$id');
    return _account(response['data'] as Map<String, dynamic>);
  }

  Future<CashierRegistration> beginRegistration({
    required String name,
    required String email,
    required String temporaryPassword,
  }) async {
    final response = await _api.request(
      'POST',
      '/v1/admin/cashiers/registrations',
      body: {
        'name': name.trim(),
        'email': email.trim(),
        'password': temporaryPassword,
      },
    );
    return _registration(response['data'] as Map<String, dynamic>);
  }

  Future<CashierRegistration> resendRegistration(String registrationId) async {
    final response = await _api.request(
      'POST',
      '/v1/admin/cashiers/registrations/resend',
      body: {'registration_id': registrationId},
    );
    return _registration(response['data'] as Map<String, dynamic>);
  }

  Future<CashierAccount> verifyRegistration(
    String registrationId,
    String code,
  ) async {
    final response = await _api.request(
      'POST',
      '/v1/admin/cashiers/registrations/verify',
      body: {'registration_id': registrationId, 'code': code},
    );
    return _account(response['data'] as Map<String, dynamic>);
  }

  CashierRegistration _registration(Map<String, dynamic> data) =>
      CashierRegistration(
        id: data['registration_id'] as String,
        expiresAt: DateTime.parse(data['expires_at'] as String).toLocal(),
      );

  Future<CashierAccount> setStatus(
    String id,
    CashierAccountStatus status,
  ) async {
    final response = await _api.request(
      'PUT',
      '/v1/admin/cashiers/$id/status',
      body: {'status': status.name.toUpperCase()},
    );
    return _account(response['data'] as Map<String, dynamic>);
  }

  Future<CashierAccount> resetPassword(
    String id,
    String temporaryPassword,
  ) async {
    final response = await _api.request(
      'POST',
      '/v1/admin/cashiers/$id/password-reset',
      body: {'temporary_password': temporaryPassword},
    );
    return _account(response['data'] as Map<String, dynamic>);
  }

  CashierAccount _account(Map<String, dynamic> data) => CashierAccount(
    id: data['user_id'] as String,
    name: data['name'] as String,
    email: data['email'] as String,
    status: data['status'] == 'DISABLED'
        ? CashierAccountStatus.disabled
        : CashierAccountStatus.active,
    passwordChangeRequired: data['password_change_required'] == true,
    emailVerified: data['email_verified'] == true,
    connectedProviders:
        (data['connected_providers'] as List<dynamic>? ?? const [])
            .cast<String>(),
    createdNow: data['created'] == true,
    audit: (data['audit'] as List<dynamic>? ?? const [])
        .map((item) {
          final row = item as Map<String, dynamic>;
          return CashierAuditEntry(
            action: row['action'] as String,
            result: row['result'] as String? ?? 'success',
            occurredAt: DateTime.parse(row['occurred_at'] as String).toLocal(),
          );
        })
        .toList(growable: false),
  );
}
