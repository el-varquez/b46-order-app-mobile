import '../../../../core/networking/json_http_client.dart';
import '../../domain/entities/customer_order.dart';
import '../models/customer_order_model.dart';

final class CustomerOrderRemoteSource {
  const CustomerOrderRemoteSource(this._api);
  final AuthenticatedApiClient _api;

  Future<CustomerOrder> place({
    required String checkoutId,
    required List<CheckoutLine> lines,
    required String deliveryAddress,
    required String deliveryNotes,
  }) async {
    final response = await _api.request(
      'POST',
      '/v1/orders',
      body: {
        'checkout_id': checkoutId,
        'lines': lines
            .map(
              (line) => {
                'product_id': line.productId,
                'quantity': line.quantity,
                'expected_unit_price_centavos': line.expectedUnitPriceCentavos,
              },
            )
            .toList(growable: false),
        'delivery_address': deliveryAddress,
        'delivery_notes': deliveryNotes,
      },
    );
    return CustomerOrderModel.fromJson(
      response['data'] as Map<String, dynamic>,
    );
  }

  Future<CustomerOrder> order(String id) async {
    final response = await _api.request('GET', '/v1/orders/$id');
    return CustomerOrderModel.fromJson(
      response['data'] as Map<String, dynamic>,
    );
  }

  Future<List<CustomerOrder>> orders() async {
    final response = await _api.request(
      'GET',
      '/v1/orders',
      query: {'limit': '20'},
    );
    final data = response['data'] as Map<String, dynamic>;
    return (data['orders'] as List<dynamic>)
        .map(
          (value) => CustomerOrderModel.fromJson(value as Map<String, dynamic>),
        )
        .toList(growable: false);
  }
}
