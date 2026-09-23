import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/app_failure.dart';
import '../../application/use_cases/cashier_use_cases.dart';
import '../../domain/entities/cashier_order.dart';

final class CashierOrdersState extends Equatable {
  const CashierOrdersState({
    this.loading = false,
    this.orders = const [],
    this.message,
  });
  final bool loading;
  final List<CashierOrder> orders;
  final String? message;
  @override
  List<Object?> get props => [loading, orders, message];
}

final class CashierOrdersCubit extends Cubit<CashierOrdersState> {
  CashierOrdersCubit(this._load, this._pollInterval)
    : super(const CashierOrdersState());
  final LoadCashierOrders _load;
  final Duration _pollInterval;
  Timer? _timer;

  Future<void> load({bool quiet = false}) async {
    if (!quiet) emit(CashierOrdersState(loading: true, orders: state.orders));
    try {
      final orders = await _load();
      emit(CashierOrdersState(orders: orders));
    } on AppFailure catch (failure) {
      emit(CashierOrdersState(orders: state.orders, message: failure.message));
    }
  }

  void startPolling() {
    _timer?.cancel();
    _timer = Timer.periodic(_pollInterval, (_) => load(quiet: true));
  }

  void stopPolling() {
    _timer?.cancel();
    _timer = null;
  }

  @override
  Future<void> close() {
    stopPolling();
    return super.close();
  }
}

final class CashierOrderDetailState extends Equatable {
  const CashierOrderDetailState({
    this.loading = false,
    this.advancing = false,
    this.order,
    this.message,
  });
  final bool loading;
  final bool advancing;
  final CashierOrder? order;
  final String? message;
  @override
  List<Object?> get props => [loading, advancing, order, message];
}

final class CashierOrderDetailCubit extends Cubit<CashierOrderDetailState> {
  CashierOrderDetailCubit({
    required LoadCashierOrder load,
    required MarkCashierOrderRead markRead,
    required AdvanceCashierOrder advance,
  }) : _load = load,
       _markRead = markRead,
       _advance = advance,
       super(const CashierOrderDetailState());
  final LoadCashierOrder _load;
  final MarkCashierOrderRead _markRead;
  final AdvanceCashierOrder _advance;

  Future<void> load(String id) async {
    emit(CashierOrderDetailState(loading: true, order: state.order));
    try {
      var order = await _load(id);
      if (order.unread) order = await _markRead(id);
      emit(CashierOrderDetailState(order: order));
    } on AppFailure catch (failure) {
      emit(
        CashierOrderDetailState(order: state.order, message: failure.message),
      );
    }
  }

  Future<void> advance() async {
    final order = state.order;
    final target = order?.nextAction;
    if (order == null || target == null || state.advancing) return;
    emit(CashierOrderDetailState(order: order, advancing: true));
    try {
      final updated = await _advance(order.id, target);
      emit(CashierOrderDetailState(order: updated));
    } on AppFailure catch (failure) {
      if (failure.code == FailureCode.invalidTransition) {
        await load(order.id);
      } else {
        emit(CashierOrderDetailState(order: order, message: failure.message));
      }
    }
  }
}
