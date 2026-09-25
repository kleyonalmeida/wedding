import 'dart:typed_data';
import '../../../../core/network/api_client.dart';
import '../models/product.dart';

class PaginatedProducts {
  final List<Product> data;
  final int totalPages;
  final int page;

  PaginatedProducts(this.data, this.totalPages, this.page);
}

class ProductRepository {
  final ApiClient api;

  ProductRepository(this.api);

  Future<PaginatedProducts> list({int page = 1, int pageSize = 20}) async {
    final response =
        await api.get('/api/admin/products?page=$page&pageSize=$pageSize');
    final list = response['data'] as List;
    final totalPages = response['totalPages'] as int? ?? 1;
    final currentPage = response['page'] as int? ?? page;

    return PaginatedProducts(
      list.map((e) => Product.fromJson(e)).toList(),
      totalPages,
      currentPage,
    );
  }

  Future<Product> get(String id) async {
    final response = await api.get('/api/admin/products/$id');
    return Product.fromJson(response);
  }

  Future<Product> create(Map<String, dynamic> data) async {
    final response = await api.post('/api/admin/products', data);
    return Product.fromJson(response);
  }

  Future<Product> update(String id, Map<String, dynamic> data) async {
    final response = await api.put('/api/admin/products/$id', data);
    return Product.fromJson(response);
  }

  Future<void> delete(String id) async {
    await api.delete('/api/admin/products/$id');
  }

  Future<void> patchStatus(String id,
      {required bool active, required bool featured}) async {
    await api.patch('/api/admin/products/$id/status', {
      'active': active,
      'featured': featured,
    });
  }

  Future<void> patchOrder(String id, int order) async {
    await api.patch('/api/admin/products/$id/order', {'displayOrder': order});
  }

  Future<void> uploadImage(String id, Uint8List bytes, String filename) async {
    await api.upload('/api/admin/products/$id/images', bytes, filename);
  }
}
