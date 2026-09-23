import 'dart:async';

import 'package:b46_order_app_mobile/core/errors/app_failure.dart';
import 'package:b46_order_app_mobile/features/customer_orders/application/use_cases/customer_order_use_cases.dart';
import 'package:b46_order_app_mobile/features/customer_orders/domain/entities/customer_order.dart';
import 'package:b46_order_app_mobile/features/customer_orders/domain/repositories/customer_order_repository.dart';
import 'package:b46_order_app_mobile/features/customer_orders/presentation/cubit/customer_orders_cubit.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('duplicate place taps share one logical checkout attempt', () async {
    final repository = _OrderRepository();
    final ids = _Ids();
    final cubit = CustomerOrdersCubit(
      place: PlaceCustomerOrder(repository),
      loadOrder: LoadCustomerOrder(repository),
      loadOrders: LoadCustomerOrders(repository),
      ids: ids,
      pollInterval: const Duration(days: 1),
    );
    const lines = [
      CheckoutLine(productId: 'p', quantity: 1, expectedUnitPriceCentavos: 100),
    ];
    final first = cubit.place(
      lines: lines,
      deliveryAddress: 'Bria',
      deliveryNotes: '',
    );
    final second = await cubit.place(
      lines: lines,
      deliveryAddress: 'Bria',
      deliveryNotes: '',
    );
    expect(second, isNull);
    expect(repository.placeCalls, 1);
    repository.completer.complete(_order);
    expect((await first)?.checkoutId, 'checkout-1');
    expect(ids.calls, 1);
    await cubit.close();
  });

  test(
    'network retry retains its checkout ID and the next order gets a new ID',
    () async {
      final repository = _RetryOrderRepository();
      final ids = _Ids();
      final cubit = CustomerOrdersCubit(
        place: PlaceCustomerOrder(repository),
        loadOrder: LoadCustomerOrder(repository),
        loadOrders: LoadCustomerOrders(repository),
        ids: ids,
        pollInterval: const Duration(days: 1),
      );
      const lines = [
        CheckoutLine(
          productId: 'p',
          quantity: 1,
          expectedUnitPriceCentavos: 100,
        ),
      ];

      expect(
        await cubit.place(
          lines: lines,
          deliveryAddress: 'Bria',
          deliveryNotes: '',
        ),
        isNull,
      );
      expect(
        (await cubit.place(
          lines: lines,
          deliveryAddress: 'Bria',
          deliveryNotes: '',
        ))?.checkoutId,
        'checkout-1',
      );
      expect(
        (await cubit.place(
          lines: lines,
          deliveryAddress: 'Bria',
          deliveryNotes: '',
        ))?.checkoutId,
        'checkout-2',
      );

      expect(repository.checkoutIds, [
        'checkout-1',
        'checkout-1',
        'checkout-2',
      ]);
      expect(ids.calls, 2);
      await cubit.close();
    },
  );
}

final _order = CustomerOrder(
  id: 'order-1',
  checkoutId: 'checkout-1',
  status: CustomerOrderStatus.preparing,
  totalCentavos: 100,
  deliveryAddress: 'Bria',
  lines: const [],
  unavailableProductIds: const [],
  createdAt: DateTime.utc(2026),
);

final class _Ids implements CheckoutIdGenerator {
  int calls = 0;
  @override
  String next() {
    calls++;
    return 'checkout-$calls';
  }
}

final class _OrderRepository implements CustomerOrderRepository {
  int placeCalls = 0;
  final completer = Completer<CustomerOrder>();
  @override
  Future<CustomerOrder> place({
    required String checkoutId,
    required List<CheckoutLine> lines,
    required String deliveryAddress,
    required String deliveryNotes,
  }) {
    placeCalls++;
    return completer.future;
  }

  @override
  Future<CustomerOrder> order(String orderId) async => _order;
  @override
  Future<List<CustomerOrder>> orders() async => [_order];
}

final class _RetryOrderRepository implements CustomerOrderRepository {
  final checkoutIds = <String>[];

  @override
  Future<CustomerOrder> place({
    required String checkoutId,
    required List<CheckoutLine> lines,
    required String deliveryAddress,
    required String deliveryNotes,
  }) async {
    checkoutIds.add(checkoutId);
    if (checkoutIds.length == 1) {
      throw const AppFailure(FailureCode.network, 'Try again.');
    }
    return CustomerOrder(
      id: 'order-${checkoutIds.length}',
      checkoutId: checkoutId,
      status: CustomerOrderStatus.preparing,
      totalCentavos: 100,
      deliveryAddress: 'Bria',
      lines: const [],
      unavailableProductIds: const [],
      createdAt: DateTime.utc(2026),
    );
  }

  @override
  Future<CustomerOrder> order(String orderId) async => _order;

  @override
  Future<List<CustomerOrder>> orders() async => [_order];
}
