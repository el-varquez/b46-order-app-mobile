import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/app_failure.dart';
import '../../application/use_cases/admin_cashier_use_cases.dart';
import '../../domain/entities/cashier_account.dart';

final class AdminCashiersState extends Equatable {
  const AdminCashiersState({
    this.cashiers = const [],
    this.selected,
    this.filter,
    this.loading = false,
    this.busy = false,
    this.message,
  });

  final List<CashierAccount> cashiers;
  final CashierAccount? selected;
  final CashierAccountStatus? filter;
  final bool loading;
  final bool busy;
  final String? message;

  @override
  List<Object?> get props => [
    cashiers,
    selected,
    filter,
    loading,
    busy,
    message,
  ];
}

final class AdminCashiersCubit extends Cubit<AdminCashiersState> {
  AdminCashiersCubit({
    required ListCashiers list,
    required LoadCashier detail,
    required BeginCashierRegistration beginRegistration,
    required ResendCashierRegistration resendRegistration,
    required VerifyCashierRegistration verifyRegistration,
    required ChangeCashierStatus changeStatus,
    required ResetCashierLogin resetLogin,
  }) : _list = list,
       _detail = detail,
       _beginRegistration = beginRegistration,
       _resendRegistration = resendRegistration,
       _verifyRegistration = verifyRegistration,
       _changeStatus = changeStatus,
       _resetLogin = resetLogin,
       super(const AdminCashiersState());

  final ListCashiers _list;
  final LoadCashier _detail;
  final BeginCashierRegistration _beginRegistration;
  final ResendCashierRegistration _resendRegistration;
  final VerifyCashierRegistration _verifyRegistration;
  final ChangeCashierStatus _changeStatus;
  final ResetCashierLogin _resetLogin;

  Future<void> load({CashierAccountStatus? filter}) async {
    emit(
      AdminCashiersState(
        cashiers: state.cashiers,
        selected: state.selected,
        filter: filter,
        loading: true,
      ),
    );
    try {
      final cashiers = await _list(status: filter);
      emit(
        AdminCashiersState(
          cashiers: cashiers,
          selected: state.selected,
          filter: filter,
        ),
      );
    } on AppFailure catch (failure) {
      emit(
        AdminCashiersState(
          cashiers: state.cashiers,
          selected: state.selected,
          filter: filter,
          message: failure.message,
        ),
      );
    } on Object {
      _failure('Could not load cashiers. Please try again.');
    }
  }

  Future<void> loadDetail(String id) async {
    emit(
      AdminCashiersState(
        cashiers: state.cashiers,
        selected: state.selected,
        filter: state.filter,
        loading: true,
      ),
    );
    try {
      final selected = await _detail(id);
      emit(
        AdminCashiersState(
          cashiers: state.cashiers,
          selected: selected,
          filter: state.filter,
        ),
      );
    } on AppFailure catch (failure) {
      emit(
        AdminCashiersState(
          cashiers: state.cashiers,
          selected: state.selected,
          filter: state.filter,
          message: failure.message,
        ),
      );
    } on Object {
      _failure('Could not load this cashier. Please try again.');
    }
  }

  Future<CashierRegistration?> beginRegistration({
    required String name,
    required String email,
    required String temporaryPassword,
  }) async {
    if (state.busy) return null;
    _busy();
    try {
      final pending = await _beginRegistration(
        name: name,
        email: email,
        temporaryPassword: temporaryPassword,
      );
      emit(
        AdminCashiersState(
          cashiers: state.cashiers,
          selected: state.selected,
          filter: state.filter,
        ),
      );
      return pending;
    } on AppFailure catch (failure) {
      _failure(failure.message);
      return null;
    } on Object {
      _failure('Could not send the verification code. Please try again.');
      return null;
    }
  }

  Future<CashierRegistration?> resendRegistration(String id) async {
    if (state.busy) return null;
    _busy();
    try {
      final pending = await _resendRegistration(id);
      emit(
        AdminCashiersState(
          cashiers: state.cashiers,
          selected: state.selected,
          filter: state.filter,
        ),
      );
      return pending;
    } on AppFailure catch (failure) {
      _failure(failure.message);
      return null;
    } on Object {
      _failure('Could not resend the code. Please try again.');
      return null;
    }
  }

  Future<CashierAccount?> verifyRegistration(String id, String code) async {
    if (state.busy) return null;
    _busy();
    try {
      final verified = await _verifyRegistration(id, code);
      emit(
        AdminCashiersState(
          cashiers: state.cashiers,
          selected: verified,
          filter: state.filter,
        ),
      );
      await load(filter: state.filter);
      return verified;
    } on AppFailure catch (failure) {
      _failure(failure.message);
      return null;
    } on Object {
      _failure('Could not verify this email. Please try again.');
      return null;
    }
  }

  Future<bool> setStatus(String id, CashierAccountStatus target) async {
    if (state.busy) return false;
    _busy();
    try {
      final updated = await _changeStatus(id, target);
      emit(
        AdminCashiersState(
          cashiers: state.cashiers,
          selected: updated,
          filter: state.filter,
        ),
      );
      await load(filter: state.filter);
      await loadDetail(id);
      return true;
    } on AppFailure catch (failure) {
      _failure(failure.message);
      return false;
    } on Object {
      _failure('Could not update the cashier. Please try again.');
      return false;
    }
  }

  Future<bool> resetPassword(String id, String temporaryPassword) async {
    if (state.busy) return false;
    _busy();
    try {
      final updated = await _resetLogin(id, temporaryPassword);
      emit(
        AdminCashiersState(
          cashiers: state.cashiers,
          selected: updated,
          filter: state.filter,
        ),
      );
      await loadDetail(id);
      return true;
    } on AppFailure catch (failure) {
      _failure(failure.message);
      return false;
    } on Object {
      _failure('Could not reset the login. Please try again.');
      return false;
    }
  }

  void clear() => emit(const AdminCashiersState());

  void _busy() => emit(
    AdminCashiersState(
      cashiers: state.cashiers,
      selected: state.selected,
      filter: state.filter,
      busy: true,
    ),
  );

  void _failure(String message) => emit(
    AdminCashiersState(
      cashiers: state.cashiers,
      selected: state.selected,
      filter: state.filter,
      message: message,
    ),
  );
}
