import '../../domain/entities/cashier_account.dart';
import '../../domain/repositories/admin_cashier_repository.dart';
import '../sources/admin_cashier_remote_source.dart';

final class AdminCashierRepositoryImpl implements AdminCashierRepository {
  const AdminCashierRepositoryImpl(this._source);
  final AdminCashierRemoteSource _source;

  @override
  Future<List<CashierAccount>> list({CashierAccountStatus? status}) =>
      _source.list(status: status);
  @override
  Future<CashierAccount> detail(String id) => _source.detail(id);
  @override
  Future<CashierRegistration> beginRegistration({
    required String name,
    required String email,
    required String temporaryPassword,
  }) => _source.beginRegistration(
    name: name,
    email: email,
    temporaryPassword: temporaryPassword,
  );
  @override
  Future<CashierRegistration> resendRegistration(String registrationId) =>
      _source.resendRegistration(registrationId);
  @override
  Future<CashierAccount> verifyRegistration(
    String registrationId,
    String code,
  ) => _source.verifyRegistration(registrationId, code);
  @override
  Future<CashierAccount> setStatus(String id, CashierAccountStatus status) =>
      _source.setStatus(id, status);
  @override
  Future<CashierAccount> resetPassword(String id, String temporaryPassword) =>
      _source.resetPassword(id, temporaryPassword);
}
