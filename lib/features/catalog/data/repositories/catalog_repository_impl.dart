import '../../domain/entities/product.dart';
import '../../domain/repositories/catalog_repository.dart';
import '../sources/catalog_remote_source.dart';

final class CatalogRepositoryImpl implements CatalogRepository {
  const CatalogRepositoryImpl(this._source);
  final CatalogRemoteSource _source;

  @override
  Future<ProductPage> products({
    int limit = 20,
    String afterId = '',
    int snapshotRevision = 0,
  }) => _source.products(
    limit: limit,
    afterId: afterId,
    snapshotRevision: snapshotRevision,
  );
}
