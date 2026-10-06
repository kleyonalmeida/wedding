import '../models/gift_product.dart';
import '../models/gift_filter.dart';
import '../../../../core/network/api_client.dart';

class GiftRepository {
  final ApiClient _apiClient;
  List<GiftProduct>? _catalog;
  Future<List<GiftProduct>>? _pending;
  int _generation = 0;

  GiftRepository({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient();

  void invalidate() {
    _generation++;
    _catalog = null;
    _pending = null;
  }

  Future<List<GiftProduct>> getCatalog() {
    if (_catalog != null) return Future.value(_catalog);
    return _pending ??= _fetchCatalog(_generation);
  }

  Future<List<GiftProduct>> _fetchCatalog(int generation) async {
    try {
      final data = await _apiClient.get('/api/gifts') as List;
      final products = data.map((json) {
        final image = json['imageUrl'] as String? ?? '';
        final uri = Uri.tryParse(image);
        final description = json['shortDescription'] as String?;
        return GiftProduct(
          id: json['id'] as String,
          name: json['name'] as String,
          imageUrl: image.isEmpty
              ? ''
              : uri?.hasScheme == true
                  ? image
                  : '${ApiClient.baseUrl}$image',
          category: json['category'] as String? ?? 'Outros',
          occasion: json['occasion'] as String? ?? 'Todas',
          priceCents: json['priceCents'] as int,
          isBestSeller: json['featured'] == true,
          available: json['soldOut'] != true,
          fullDescription: json['description'] as String?,
          description: description?.trim().isNotEmpty == true
              ? description
              : json['description'] as String?,
        );
      }).toList();
      // Stable featured ordering, preserving the API display order for ties.
      final sorted = List<GiftProduct>.unmodifiable([
        ...products.where((p) => p.isBestSeller),
        ...products.where((p) => !p.isBestSeller),
      ]);
      if (generation == _generation) _catalog = sorted;
      return sorted;
    } finally {
      if (generation == _generation) _pending = null;
    }
  }

  Future<List<String>> getCategories() async =>
      (await getCatalog()).map((p) => p.category).toSet().toList()..sort();

  Future<List<GiftProduct>> getProducts(
      {required GiftFilter filter,
      required int page,
      required int limit,
      String? postalCode}) async {
    final products = _filter(await getCatalog(), filter);
    return products.skip((page - 1) * limit).take(limit).toList();
  }

  Future<int> getTotalCount({required GiftFilter filter}) async =>
      _filter(await getCatalog(), filter).length;

  List<GiftProduct> _filter(
          List<GiftProduct> catalog, GiftFilter filter) =>
      catalog
          .where((p) =>
              filter.categories.isEmpty ||
              filter.categories.contains(p.category))
          .toList();

  void dispose() => _apiClient.dispose();
}
