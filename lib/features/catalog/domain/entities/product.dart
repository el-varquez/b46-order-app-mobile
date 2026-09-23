final class Product {
  const Product({
    required this.id,
    required this.name,
    required this.description,
    required this.priceCentavos,
    required this.categoryId,
    required this.categoryName,
    required this.available,
    this.imageUrl,
  });

  final String id;
  final String name;
  final String description;
  final int priceCentavos;
  final String categoryId;
  final String categoryName;
  final bool available;
  final Uri? imageUrl;
}

final class ProductPage {
  const ProductPage({
    required this.products,
    required this.snapshotRevision,
    required this.afterId,
    required this.hasMore,
  });
  final List<Product> products;
  final int snapshotRevision;
  final String afterId;
  final bool hasMore;
}
