import 'dart:async';
import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:wedding_app/core/network/api_client.dart';
import 'package:wedding_app/features/gifts/data/repositories/gift_repository.dart';
import 'package:wedding_app/features/gifts/presentation/controllers/gift_catalog_controller.dart';

Map<String, Object> product(int i) => {
      'id': '$i',
      'name': i == 0 ? 'Cafeteira' : 'Presente $i',
      'category': i < 12 ? 'Casa' : 'Lua de Mel',
      'priceCents': 1000,
      'description': i == 0 ? 'Café nas manhãs' : 'Memória',
      'imageUrl': 'https://example.com/image.jpg'
    };

void main() {
  test('catálogo compartilha GET; busca/categorias/páginas são locais',
      () async {
    var requests = 0;
    final repository =
        GiftRepository(apiClient: ApiClient(client: MockClient((_) async {
      requests++;
      return http.Response(jsonEncode(List.generate(20, product)), 200);
    })));
    final controller = GiftCatalogController(repository: repository);
    addTearDown(controller.dispose);
    await repository.getCategories();
    await Future<void>.delayed(Duration.zero);
    expect(requests, 1);
    expect(controller.products.length, 12);
    expect(controller.hasMore, isTrue);
    await controller.loadProducts();
    expect(controller.products.length, 20);
    expect(controller.hasMore, isFalse);
    controller.selectCategory('lar');
    await Future<void>.delayed(Duration.zero);
    expect(controller.totalResults, 12);
    controller.updateSearch('cafe');
    await Future<void>.delayed(const Duration(milliseconds: 280));
    expect(controller.products.single.name, 'Cafeteira');
    expect(
        controller.products.single.imageUrl, 'https://example.com/image.jpg');
    controller.selectCategory('luademel');
    await Future<void>.delayed(Duration.zero);
    expect(controller.products, isEmpty);
    expect(requests, 1);
    await controller.loadProducts(refresh: true);
    expect(requests, 2);
  });

  test('último filtro prevalece durante request; dispose não notifica',
      () async {
    final response = Completer<http.Response>();
    var requests = 0;
    final repository =
        GiftRepository(apiClient: ApiClient(client: MockClient((_) {
      requests++;
      return response.future;
    })));
    final controller = GiftCatalogController(repository: repository);
    controller.selectCategory('lar');
    controller.selectCategory('luademel');
    response
        .complete(http.Response(jsonEncode(List.generate(20, product)), 200));
    await Future<void>.delayed(Duration.zero);
    expect(
        controller.products.every((p) => p.category == 'Lua de Mel'), isTrue);
    expect(controller.totalResults, 8);
    expect(requests, 1);
    controller.dispose();
  });

  test('sair durante carregamento não produz notify após dispose', () async {
    final response = Completer<http.Response>();
    final repository = GiftRepository(
        apiClient: ApiClient(client: MockClient((_) => response.future)));
    final controller = GiftCatalogController(repository: repository);
    controller.dispose();
    response.complete(http.Response('[]', 200));
    await Future<void>.delayed(Duration.zero);
    expect(
        controller.isLoading, isTrue); // disposed state is no longer observed
  });
}
