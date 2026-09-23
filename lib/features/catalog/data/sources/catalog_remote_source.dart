import '../../../../core/networking/json_http_client.dart';
import '../../domain/entities/product.dart';
import '../models/product_model.dart';

final class CatalogRemoteSource {
  const CatalogRemoteSource(this._api);
  final AuthenticatedApiClient _api;

  Future<ProductPage> products({
    required int limit,
    required String afterId,
    required int snapshotRevision,
  }) async {
    final query = <String, String>{'limit': '$limit'};
    if (afterId.isNotEmpty) query['after_id'] = afterId;
    if (snapshotRevision > 0) {
      query['snapshot_revision'] = '$snapshotRevision';
    }
    final response = await _api.request('GET', '/v1/products', query: query);
    final data = response['data'] as Map<String, dynamic>;
    return ProductPage(
      products: (data['products'] as List<dynamic>)
          .map((value) => ProductModel.fromJson(value as Map<String, dynamic>))
          .toList(growable: false),
      snapshotRevision: data['snapshot_revision'] as int,
      afterId: data['after_id'] as String,
      hasMore: data['has_more'] as bool,
    );
  }
}
