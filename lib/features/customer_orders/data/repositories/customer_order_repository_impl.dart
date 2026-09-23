import 'package:uuid/uuid.dart';

import '../../domain/entities/customer_order.dart';
import '../../domain/repositories/customer_order_repository.dart';
import '../sources/customer_order_remote_source.dart';

final class CustomerOrderRepositoryImpl implements CustomerOrderRepository {
  const CustomerOrderRepositoryImpl(this._source);
  final CustomerOrderRemoteSource _source;

  @override
  Future<CustomerOrder> place({
    required String checkoutId,
    required List<CheckoutLine> lines,
    required String deliveryAddress,
    required String deliveryNotes,
  }) => _source.place(
    checkoutId: checkoutId,
    lines: lines,
    deliveryAddress: deliveryAddress,
    deliveryNotes: deliveryNotes,
  );
  @override
  Future<CustomerOrder> order(String orderId) => _source.order(orderId);
  @override
  Future<List<CustomerOrder>> orders() => _source.orders();
}

final class UuidCheckoutIdGenerator implements CheckoutIdGenerator {
  const UuidCheckoutIdGenerator();
  @override
  String next() => const Uuid().v4();
}
