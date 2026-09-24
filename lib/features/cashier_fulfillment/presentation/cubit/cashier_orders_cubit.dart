import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/app_failure.dart';
import '../../application/use_cases/cashier_use_cases.dart';
import '../../domain/entities/cashier_order.dart';

final class CashierOrdersState extends Equatable {
  const CashierOrdersState({
    this.loading = false,
    this.loadingMore = false,
    this.orders = const [],
    this.filter,
    this.nextAfterId,
    this.newOrderCount = 0,
    this.message,
  });

  final bool loading;
  final bool loadingMore;
  final List<CashierOrder> orders;
  final FulfillmentStatus? filter;
  final String? nextAfterId;
  final int newOrderCount;
  final String? message;

  @override
  List<Object?> get props => [
    loading,
    loadingMore,
    orders,
    filter,
    nextAfterId,
    newOrderCount,
    message,
  ];
}

final class CashierOrdersCubit extends Cubit<CashierOrdersState> {
  CashierOrdersCubit(this._load, this._pollInterval)
    : super(const CashierOrdersState());

  final LoadCashierOrders _load;
  final Duration _pollInterval;
  Timer? _timer;
  int _requestGeneration = 0;

  Future<void> load({bool quiet = false}) async {
    if (quiet && state.loadingMore) return;
    final generation = ++_requestGeneration;
    final filter = state.filter;
    final previous = state.orders;
    if (!quiet) {
      emit(
        CashierOrdersState(
          loading: true,
          orders: previous,
          filter: filter,
          nextAfterId: state.nextAfterId,
        ),
      );
    }
    try {
      final page = await _load(status: filter);
      if (isClosed || generation != _requestGeneration) return;
      final knownIds = previous.map((order) => order.id).toSet();
      final newCount = quiet && previous.isNotEmpty
          ? page.orders
                .where((order) => order.unread && !knownIds.contains(order.id))
                .length
          : 0;
      emit(
        CashierOrdersState(
          orders: page.orders,
          filter: filter,
          nextAfterId: page.nextAfterId,
          newOrderCount: newCount,
        ),
      );
    } on AppFailure catch (failure) {
      if (isClosed || generation != _requestGeneration) return;
      emit(
        CashierOrdersState(
          orders: previous,
          filter: filter,
          nextAfterId: state.nextAfterId,
          message: failure.message,
        ),
      );
    }
  }

  Future<void> selectFilter(FulfillmentStatus? filter) async {
    if (filter == state.filter) return;
    ++_requestGeneration;
    emit(CashierOrdersState(filter: filter, loading: true));
    await load();
  }

  Future<void> loadMore() async {
    final afterId = state.nextAfterId;
    if (afterId == null || state.loading || state.loadingMore) return;
    final generation = _requestGeneration;
    final filter = state.filter;
    final previous = state.orders;
    emit(
      CashierOrdersState(
        orders: previous,
        filter: filter,
        nextAfterId: afterId,
        loadingMore: true,
      ),
    );
    try {
      final page = await _load(status: filter, afterId: afterId);
      if (isClosed || generation != _requestGeneration) return;
      final byId = <String, CashierOrder>{
        for (final order in previous) order.id: order,
        for (final order in page.orders) order.id: order,
      };
      emit(
        CashierOrdersState(
          orders: byId.values.toList(growable: false),
          filter: filter,
          nextAfterId: page.nextAfterId,
        ),
      );
    } on AppFailure catch (failure) {
      if (isClosed || generation != _requestGeneration) return;
      emit(
        CashierOrdersState(
          orders: previous,
          filter: filter,
          nextAfterId: afterId,
          message: failure.message,
        ),
      );
    }
  }

  void clear() {
    ++_requestGeneration;
    stopPolling();
    emit(const CashierOrdersState());
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

  Future<void> load(String id, {String? notice}) async {
    emit(CashierOrderDetailState(loading: true, order: state.order));
    try {
      var order = await _load(id);
      if (order.unread) {
        try {
          order = await _markRead(id);
        } on AppFailure catch (failure) {
          if (isClosed) return;
          emit(CashierOrderDetailState(order: order, message: failure.message));
          return;
        }
      }
      if (isClosed) return;
      emit(CashierOrderDetailState(order: order, message: notice));
    } on AppFailure catch (failure) {
      if (isClosed) return;
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
      if (isClosed) return;
      emit(CashierOrderDetailState(order: updated));
    } on AppFailure catch (failure) {
      if (isClosed) return;
      if (failure.code == FailureCode.invalidTransition) {
        await load(
          order.id,
          notice: 'This order changed. The latest status is shown.',
        );
      } else {
        emit(CashierOrderDetailState(order: order, message: failure.message));
      }
    }
  }
}
