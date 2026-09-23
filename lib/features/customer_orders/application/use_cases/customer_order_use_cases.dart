import '../../domain/entities/customer_order.dart';
import '../../domain/repositories/customer_order_repository.dart';

final class PlaceCustomerOrder {
  const PlaceCustomerOrder(this._repository);
  final CustomerOrderRepository _repository;
  Future<CustomerOrder> call({
    required String checkoutId,
    required List<CheckoutLine> lines,
    required String deliveryAddress,
    required String deliveryNotes,
  }) => _repository.place(
    checkoutId: checkoutId,
    lines: lines,
    deliveryAddress: deliveryAddress,
    deliveryNotes: deliveryNotes,
  );
}

final class LoadCustomerOrder {
  const LoadCustomerOrder(this._repository);
  final CustomerOrderRepository _repository;
  Future<CustomerOrder> call(String orderId) => _repository.order(orderId);
}

final class LoadCustomerOrders {
  const LoadCustomerOrders(this._repository);
  final CustomerOrderRepository _repository;
  Future<List<CustomerOrder>> call() => _repository.orders();
}
