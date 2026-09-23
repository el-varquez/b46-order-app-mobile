import '../../domain/entities/cashier_order.dart';
import '../../domain/repositories/cashier_repository.dart';
import '../sources/cashier_remote_source.dart';

final class CashierRepositoryImpl implements CashierRepository {
  const CashierRepositoryImpl(this._source);
  final CashierRemoteSource _source;
  @override
  Future<CashierOrder> advance(String id, FulfillmentStatus target) =>
      _source.advance(id, target);
  @override
  Future<CashierOrder> markRead(String id) => _source.markRead(id);
  @override
  Future<CashierOrder> order(String id) => _source.order(id);
  @override
  Future<List<CashierOrder>> orders() => _source.orders();
}
