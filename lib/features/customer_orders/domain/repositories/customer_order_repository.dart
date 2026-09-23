import '../entities/customer_order.dart';

abstract interface class CustomerOrderRepository {
  Future<CustomerOrder> place({
    required String checkoutId,
    required List<CheckoutLine> lines,
    required String deliveryAddress,
    required String deliveryNotes,
  });
  Future<CustomerOrder> order(String orderId);
  Future<List<CustomerOrder>> orders();
}

abstract interface class CheckoutIdGenerator {
  String next();
}
