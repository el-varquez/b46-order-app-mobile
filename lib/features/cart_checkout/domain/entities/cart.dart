final class CartProduct {
  const CartProduct({
    required this.id,
    required this.name,
    required this.unitPriceCentavos,
  });
  final String id;
  final String name;
  final int unitPriceCentavos;
}

final class CartLine {
  const CartLine({required this.product, required this.quantity});
  final CartProduct product;
  final int quantity;
  int get lineTotalCentavos => product.unitPriceCentavos * quantity;

  CartLine copyWith({int? quantity}) =>
      CartLine(product: product, quantity: quantity ?? this.quantity);
}
