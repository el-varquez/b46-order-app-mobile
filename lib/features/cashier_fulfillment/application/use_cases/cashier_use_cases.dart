import '../../domain/entities/cashier_order.dart';
import '../../domain/repositories/cashier_repository.dart';

final class LoadCashierOrders {
  const LoadCashierOrders(this._repository);
  final CashierRepository _repository;
  Future<CashierOrderPage> call({FulfillmentStatus? status, String? afterId}) =>
      _repository.orders(status: status, afterId: afterId);
}

final class LoadCashierOrder {
  const LoadCashierOrder(this._repository);
  final CashierRepository _repository;
  Future<CashierOrder> call(String id) => _repository.order(id);
}

final class MarkCashierOrderRead {
  const MarkCashierOrderRead(this._repository);
  final CashierRepository _repository;
  Future<CashierOrder> call(String id) => _repository.markRead(id);
}

final class AdvanceCashierOrder {
  const AdvanceCashierOrder(this._repository);
  final CashierRepository _repository;
  Future<CashierOrder> call(String id, FulfillmentStatus target) =>
      _repository.advance(id, target);
}
