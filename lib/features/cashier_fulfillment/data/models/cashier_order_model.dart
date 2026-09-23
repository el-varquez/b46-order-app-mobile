import '../../domain/entities/cashier_order.dart';

abstract final class CashierOrderModel {
  static CashierOrder fromJson(Map<String, dynamic> value) {
    final customer = value['customer'] as Map<String, dynamic>;
    return CashierOrder(
      id: value['order_id'] as String,
      customerName: customer['name'] as String,
      status: _status(value['status'] as String)!,
      nextAction: value['next_action'] == null
          ? null
          : _status(value['next_action'] as String),
      unread: value['unread'] as bool,
      totalCentavos: value['total_centavos'] as int,
      deliveryAddress: value['delivery_address'] as String,
      deliveryNotes: value['delivery_notes'] as String,
      lines: (value['lines'] as List<dynamic>)
          .map((item) {
            final line = item as Map<String, dynamic>;
            return CashierOrderLine(
              name: line['product_name'] as String,
              quantity: line['quantity'] as int,
            );
          })
          .toList(growable: false),
      createdAt: DateTime.parse(value['created_at'] as String).toUtc(),
    );
  }

  static FulfillmentStatus? _status(String value) => switch (value) {
    'PREPARING' => FulfillmentStatus.preparing,
    'DELIVERING' => FulfillmentStatus.delivering,
    'DELIVERED' => FulfillmentStatus.delivered,
    _ => null,
  };
}
