import '../entities/cashier_order.dart';

abstract interface class CashierRepository {
  Future<List<CashierOrder>> orders();
  Future<CashierOrder> order(String id);
  Future<CashierOrder> markRead(String id);
  Future<CashierOrder> advance(String id, FulfillmentStatus target);
}
