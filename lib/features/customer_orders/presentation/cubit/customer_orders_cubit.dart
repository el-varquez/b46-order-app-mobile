import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/app_failure.dart';
import '../../application/use_cases/customer_order_use_cases.dart';
import '../../domain/entities/customer_order.dart';
import '../../domain/repositories/customer_order_repository.dart';

enum CustomerOrdersStatus { idle, loading, placing, ready, failure }

final class CustomerOrdersState extends Equatable {
  const CustomerOrdersState({
    this.status = CustomerOrdersStatus.idle,
    this.orders = const [],
    this.active,
    this.message,
  });
  final CustomerOrdersStatus status;
  final List<CustomerOrder> orders;
  final CustomerOrder? active;
  final String? message;

  @override
  List<Object?> get props => [status, orders, active, message];
}

final class CustomerOrdersCubit extends Cubit<CustomerOrdersState> {
  CustomerOrdersCubit({
    required PlaceCustomerOrder place,
    required LoadCustomerOrder loadOrder,
    required LoadCustomerOrders loadOrders,
    required CheckoutIdGenerator ids,
    required Duration pollInterval,
  }) : _place = place,
       _loadOrder = loadOrder,
       _loadOrders = loadOrders,
       _ids = ids,
       _pollInterval = pollInterval,
       super(const CustomerOrdersState());

  final PlaceCustomerOrder _place;
  final LoadCustomerOrder _loadOrder;
  final LoadCustomerOrders _loadOrders;
  final CheckoutIdGenerator _ids;
  final Duration _pollInterval;
  String? _checkoutId;
  Timer? _timer;
  bool _requestInFlight = false;

  Future<CustomerOrder?> place({
    required List<CheckoutLine> lines,
    required String deliveryAddress,
    required String deliveryNotes,
  }) async {
    if (_requestInFlight) return null;
    _requestInFlight = true;
    _checkoutId ??= _ids.next();
    emit(
      CustomerOrdersState(
        status: CustomerOrdersStatus.placing,
        orders: state.orders,
        active: state.active,
      ),
    );
    try {
      final order = await _place(
        checkoutId: _checkoutId!,
        lines: lines,
        deliveryAddress: deliveryAddress,
        deliveryNotes: deliveryNotes,
      );
      _checkoutId = null;
      emit(
        CustomerOrdersState(
          status: CustomerOrdersStatus.ready,
          orders: state.orders,
          active: order,
        ),
      );
      if (order.status != CustomerOrderStatus.rejected &&
          order.status != CustomerOrderStatus.delivered) {
        startPolling();
      }
      return order;
    } on AppFailure catch (failure) {
      emit(
        CustomerOrdersState(
          status: CustomerOrdersStatus.failure,
          orders: state.orders,
          active: state.active,
          message: failure.message,
        ),
      );
      return null;
    } finally {
      _requestInFlight = false;
    }
  }

  Future<void> loadAll() async {
    emit(
      CustomerOrdersState(
        status: CustomerOrdersStatus.loading,
        orders: state.orders,
        active: state.active,
      ),
    );
    try {
      final orders = await _loadOrders();
      final active = orders
          .where((order) => order.status != CustomerOrderStatus.delivered)
          .firstOrNull;
      emit(
        CustomerOrdersState(
          status: CustomerOrdersStatus.ready,
          orders: orders,
          active: active,
        ),
      );
      if (active != null && active.status != CustomerOrderStatus.rejected) {
        startPolling();
      }
    } on AppFailure catch (failure) {
      emit(
        CustomerOrdersState(
          status: CustomerOrdersStatus.failure,
          orders: state.orders,
          active: state.active,
          message: failure.message,
        ),
      );
    }
  }

  Future<void> refreshActive() async {
    final active = state.active;
    if (active == null) return;
    try {
      final order = await _loadOrder(active.id);
      emit(
        CustomerOrdersState(
          status: CustomerOrdersStatus.ready,
          orders: state.orders,
          active: order,
        ),
      );
      if (order.status == CustomerOrderStatus.delivered ||
          order.status == CustomerOrderStatus.rejected) {
        stopPolling();
        if (order.status == CustomerOrderStatus.rejected) _checkoutId = null;
      }
    } on Object {
      // Foreground polling keeps the last authoritative state and retries.
    }
  }

  void startPolling() {
    _timer?.cancel();
    _timer = Timer.periodic(_pollInterval, (_) => refreshActive());
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
