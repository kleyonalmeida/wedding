import '../models/gift_product.dart';
import '../models/gift_filter.dart';
import '../../../../core/network/api_client.dart';

class GiftRepository {
  final ApiClient _apiClient = ApiClient();

  Future<List<dynamic>> _fetchCatalog() async => (await _apiClient.get('/api/gifts')) as List<dynamic>;

  Future<List<String>> getCategories() async {
    final data = await _fetchCatalog();
    return data.map((item) => item['category'] as String).toSet().toList()..sort();
  }

  Future<List<GiftProduct>> getProducts({
    required GiftFilter filter,
    required int page,
    required int limit,
    String? postalCode,
  }) async {
    try {
      final List<dynamic> data = await _fetchCatalog();

      List<GiftProduct> products = data.map((json) {
        return GiftProduct(
          id: json['id'],
          name: json['name'],
          imageUrl: json['imageUrl'] == null ? '' : '${ApiClient.baseUrl}${json['imageUrl']}',
          category: json['category'] ?? 'Outros',
          occasion: json['occasion'] ?? 'Todas',
          originalPrice: (json['priceCents'] / 100).toDouble(),
          currentPrice: (json['priceCents'] / 100).toDouble(),
          installments: 1, // Optional: if we want installments logic, compute it here
          installmentValue: (json['priceCents'] / 100).toDouble(),
          discountPercentage: 0,
          isBestSeller: json['featured'] ?? false,
          available: true,
          giftUrl: '#',
        );
      }).toList();

      // Apply filtering (if we want to do it locally, or could pass to API)
      if (filter.categories.isNotEmpty) {
        products = products.where((p) => filter.categories.contains(p.category)).toList();
      }

      // Apply sorting
      switch (filter.sortOrder) {
        case GiftSortOrder.highestPrice:
          products.sort((a, b) => b.currentPrice.compareTo(a.currentPrice));
          break;
        case GiftSortOrder.lowestPrice:
          products.sort((a, b) => a.currentPrice.compareTo(b.currentPrice));
          break;
        case GiftSortOrder.bestSeller:
          products.sort((a, b) => a.isBestSeller ? -1 : 1);
          break;
      }

      // Apply pagination
      final startIndex = (page - 1) * limit;
      if (startIndex >= products.length) return [];

      final endIndex = startIndex + limit;
      return products.sublist(
        startIndex,
        endIndex > products.length ? products.length : endIndex
      );
    } catch (_) {
      rethrow;
    }
  }

  Future<int> getTotalCount({required GiftFilter filter}) async {
    final data = await _fetchCatalog();
    return data.where((item) => filter.categories.isEmpty || filter.categories.contains(item['category'])).length;
  }
}
