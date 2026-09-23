enum CustomerOrderStatus { preparing, onTheWay, delivered, rejected }

final class CheckoutLine {
  const CheckoutLine({
    required this.productId,
    required this.quantity,
    required this.expectedUnitPriceCentavos,
  });
  final String productId;
  final int quantity;
  final int expectedUnitPriceCentavos;
}

final class CustomerOrderLine {
  const CustomerOrderLine({
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.unitPriceCentavos,
  });
  final String productId;
  final String productName;
  final int quantity;
  final int unitPriceCentavos;
}

final class CustomerOrder {
  const CustomerOrder({
    required this.id,
    required this.checkoutId,
    required this.status,
    required this.totalCentavos,
    required this.deliveryAddress,
    required this.lines,
    required this.unavailableProductIds,
    required this.createdAt,
  });
  final String id;
  final String checkoutId;
  final CustomerOrderStatus status;
  final int totalCentavos;
  final String deliveryAddress;
  final List<CustomerOrderLine> lines;
  final List<String> unavailableProductIds;
  final DateTime createdAt;
}
