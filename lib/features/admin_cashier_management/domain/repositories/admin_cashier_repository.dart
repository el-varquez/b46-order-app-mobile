import '../entities/cashier_account.dart';

abstract interface class AdminCashierRepository {
  Future<List<CashierAccount>> list({CashierAccountStatus? status});
  Future<CashierAccount> detail(String id);
  Future<CashierRegistration> beginRegistration({
    required String name,
    required String email,
    required String temporaryPassword,
  });
  Future<CashierRegistration> resendRegistration(String registrationId);
  Future<CashierAccount> verifyRegistration(String registrationId, String code);
  Future<CashierAccount> setStatus(String id, CashierAccountStatus status);
  Future<CashierAccount> resetPassword(String id, String temporaryPassword);
}
