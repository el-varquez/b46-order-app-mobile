import '../../../../core/networking/json_http_client.dart';
import '../../domain/entities/cashier_order.dart';
import '../models/cashier_order_model.dart';

final class CashierRemoteSource {
  const CashierRemoteSource(this._api);
  final AuthenticatedApiClient _api;

  Future<CashierOrderPage> orders({
    FulfillmentStatus? status,
    String? afterId,
  }) async {
    final response = await _api.request(
      'GET',
      '/v1/staff/orders',
      query: {
        'limit': '30',
        if (status != null) 'status': status.name.toUpperCase(),
        if (afterId != null) 'after_id': afterId,
      },
    );
    final data = response['data'] as Map<String, dynamic>;
    final orders = (data['orders'] as List<dynamic>)
        .map(
          (value) => CashierOrderModel.fromJson(value as Map<String, dynamic>),
        )
        .toList(growable: false);
    final next = data['next_after_id'] as String?;
    return CashierOrderPage(
      orders: orders,
      nextAfterId: next == null || next.isEmpty ? null : next,
    );
  }

  Future<CashierOrder> order(String id) async {
    final response = await _api.request('GET', '/v1/staff/orders/$id');
    return CashierOrderModel.fromJson(response['data'] as Map<String, dynamic>);
  }

  Future<CashierOrder> markRead(String id) async {
    final response = await _api.request('POST', '/v1/staff/orders/$id/read');
    return CashierOrderModel.fromJson(response['data'] as Map<String, dynamic>);
  }

  Future<CashierOrder> advance(String id, FulfillmentStatus target) async {
    final response = await _api.request(
      'PATCH',
      '/v1/staff/orders/$id/status',
      body: {'status': target.name.toUpperCase()},
    );
    return CashierOrderModel.fromJson(response['data'] as Map<String, dynamic>);
  }
}
