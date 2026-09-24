import '../../domain/entities/cashier_account.dart';
import '../../domain/repositories/admin_cashier_repository.dart';

final class ListCashiers {
  const ListCashiers(this._repository);
  final AdminCashierRepository _repository;
  Future<List<CashierAccount>> call({CashierAccountStatus? status}) =>
      _repository.list(status: status);
}

final class LoadCashier {
  const LoadCashier(this._repository);
  final AdminCashierRepository _repository;
  Future<CashierAccount> call(String id) => _repository.detail(id);
}

final class BeginCashierRegistration {
  const BeginCashierRegistration(this._repository);
  final AdminCashierRepository _repository;
  Future<CashierRegistration> call({
    required String name,
    required String email,
    required String temporaryPassword,
  }) => _repository.beginRegistration(
    name: name,
    email: email,
    temporaryPassword: temporaryPassword,
  );
}

final class ResendCashierRegistration {
  const ResendCashierRegistration(this._repository);
  final AdminCashierRepository _repository;
  Future<CashierRegistration> call(String id) =>
      _repository.resendRegistration(id);
}

final class VerifyCashierRegistration {
  const VerifyCashierRegistration(this._repository);
  final AdminCashierRepository _repository;
  Future<CashierAccount> call(String id, String code) =>
      _repository.verifyRegistration(id, code);
}

final class ChangeCashierStatus {
  const ChangeCashierStatus(this._repository);
  final AdminCashierRepository _repository;
  Future<CashierAccount> call(String id, CashierAccountStatus status) =>
      _repository.setStatus(id, status);
}

final class ResetCashierLogin {
  const ResetCashierLogin(this._repository);
  final AdminCashierRepository _repository;
  Future<CashierAccount> call(String id, String temporaryPassword) =>
      _repository.resetPassword(id, temporaryPassword);
}
