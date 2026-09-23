import '../../domain/entities/customer_order.dart';

abstract final class CustomerOrderModel {
  static CustomerOrder fromJson(Map<String, dynamic> value) {
    final rejection = value['rejection'] as Map<String, dynamic>?;
    final unavailable =
        rejection?['unavailable_items'] as List<dynamic>? ?? const [];
    return CustomerOrder(
      id: value['order_id'] as String,
      checkoutId: value['checkout_id'] as String,
      status: switch (value['status']) {
        'PREPARING' => CustomerOrderStatus.preparing,
        'ON_THE_WAY' => CustomerOrderStatus.onTheWay,
        'DELIVERED' => CustomerOrderStatus.delivered,
        'REJECTED' => CustomerOrderStatus.rejected,
        _ => throw const FormatException('Unknown order status'),
      },
      totalCentavos: value['total_centavos'] as int,
      deliveryAddress: value['delivery_address'] as String,
      lines: (value['lines'] as List<dynamic>)
          .map((item) {
            final line = item as Map<String, dynamic>;
            return CustomerOrderLine(
              productId: line['product_id'] as String,
              productName: line['product_name'] as String,
              quantity: line['quantity'] as int,
              unitPriceCentavos: line['unit_price_centavos'] as int,
            );
          })
          .toList(growable: false),
      unavailableProductIds: unavailable
          .map((item) => (item as Map<String, dynamic>)['product_id'] as String)
          .toList(growable: false),
      createdAt: DateTime.parse(value['created_at'] as String).toUtc(),
    );
  }
}
