import '../entities/product.dart';

abstract interface class CatalogRepository {
  Future<ProductPage> products({
    int limit = 20,
    String afterId = '',
    int snapshotRevision = 0,
  });
}
