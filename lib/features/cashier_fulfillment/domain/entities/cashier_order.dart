enum FulfillmentStatus { preparing, delivering, delivered }

final class CashierOrderLine {
  const CashierOrderLine({
    required this.id,
    required this.name,
    required this.quantity,
  });
  final String id;
  final String name;
  final int quantity;
}

final class CashierOrderPage {
  const CashierOrderPage({required this.orders, required this.nextAfterId});
  final List<CashierOrder> orders;
  final String? nextAfterId;
}

final class CashierOrder {
  const CashierOrder({
    required this.id,
    required this.customerName,
    required this.status,
    required this.unread,
    required this.totalCentavos,
    required this.deliveryAddress,
    required this.deliveryNotes,
    required this.lines,
    required this.createdAt,
    this.nextAction,
  });
  final String id;
  final String customerName;
  final FulfillmentStatus status;
  final FulfillmentStatus? nextAction;
  final bool unread;
  final int totalCentavos;
  final String deliveryAddress;
  final String deliveryNotes;
  final List<CashierOrderLine> lines;
  final DateTime createdAt;
}
