import '../../domain/entities/product.dart';

abstract final class ProductModel {
  static Product fromJson(Map<String, dynamic> value) => Product(
    id: value['product_id'] as String,
    name: value['name'] as String,
    description: value['description'] as String,
    priceCentavos: value['price_centavos'] as int,
    categoryId: value['category_id'] as String,
    categoryName: value['category_name'] as String,
    imageUrl: value['image_url'] == null
        ? null
        : Uri.parse(value['image_url'] as String),
    available: value['available'] as bool,
  );
}
