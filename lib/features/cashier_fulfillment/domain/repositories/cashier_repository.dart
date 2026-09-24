import '../entities/cashier_order.dart';

abstract interface class CashierRepository {
  Future<CashierOrderPage> orders({FulfillmentStatus? status, String? afterId});
  Future<CashierOrder> order(String id);
  Future<CashierOrder> markRead(String id);
  Future<CashierOrder> advance(String id, FulfillmentStatus target);
}
