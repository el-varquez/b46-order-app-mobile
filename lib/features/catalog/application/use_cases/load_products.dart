import '../../domain/entities/product.dart';
import '../../domain/repositories/catalog_repository.dart';

final class LoadProducts {
  const LoadProducts(this._repository);
  final CatalogRepository _repository;

  Future<ProductPage> call({String afterId = '', int snapshotRevision = 0}) =>
      _repository.products(
        afterId: afterId,
        snapshotRevision: snapshotRevision,
      );
}
