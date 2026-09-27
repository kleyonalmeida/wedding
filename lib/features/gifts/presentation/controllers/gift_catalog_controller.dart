import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../data/models/gift_product.dart';
import '../../data/models/gift_filter.dart';
import '../../data/models/gift_category.dart';
import '../../data/repositories/gift_repository.dart';

class GiftCatalogController extends ChangeNotifier {
  final GiftRepository _repository;
  List<GiftProduct> products = [];
  List<String> categories = [];
  bool isLoading = false;
  String? error;
  GiftFilter currentFilter = GiftFilter();
  String searchQuery = '';
  int currentPage = 1;
  final int limit = 10;
  bool hasMore = true;
  int totalResults = 0;
  int _request = 0;
  bool _disposed = false;
  Timer? _searchTimer;

  GiftCatalogController({GiftRepository? repository})
      : _repository = repository ?? GiftRepository() {
    loadProducts();
  }

  Future<void> loadProducts(
      {bool refresh = false, bool reloadCatalog = true}) async {
    if (_disposed || (!refresh && (isLoading || !hasMore))) return;
    final request = ++_request;
    if (refresh) {
      if (reloadCatalog) _repository.invalidate();
      currentPage = 1;
      hasMore = true;
      products = [];
    }
    isLoading = true;
    error = null;
    notifyListeners();
    try {
      final catalog = await _repository.getCatalog();
      if (_disposed || request != _request) return;
      categories = catalog.map((p) => p.category).toSet().toList()..sort();
      final term = normalizeGiftText(searchQuery);
      final filtered = catalog
          .where((p) =>
              (currentFilter.categories.isEmpty ||
                  currentFilter.categories.any((c) =>
                      giftCategoryId(c) == giftCategoryId(p.category))) &&
              (term.isEmpty ||
                  normalizeGiftText('${p.name} ${p.description ?? ''}')
                      .contains(term)))
          .toList();
      totalResults = filtered.length;
      products = filtered.take(currentPage * limit).toList();
      hasMore = products.length < totalResults;
      currentPage++;
    } catch (_) {
      if (!_disposed && request == _request) {
        error = 'Erro ao carregar produtos. Tente novamente.';
      }
    } finally {
      if (!_disposed && request == _request) {
        isLoading = false;
        notifyListeners();
      }
    }
  }

  void updateSearch(String query) {
    searchQuery = query;
    _searchTimer?.cancel();
    // Invalidate an older response immediately, before the debounce finishes.
    _request++;
    _searchTimer = Timer(const Duration(milliseconds: 250), () {
      loadProducts(refresh: true, reloadCatalog: false);
    });
  }

  void selectCategory(String category) => updateFilter(currentFilter.copyWith(
      categories: category == 'todas' ? [] : [category]));

  void updateFilter(GiftFilter filter) {
    currentFilter = filter;
    loadProducts(refresh: true, reloadCatalog: false);
  }

  void clearFilters() => updateFilter(GiftFilter());
  void toggleOccasion(String occasion) {
    final list = [...currentFilter.occasions];
    list.contains(occasion) ? list.remove(occasion) : list.add(occasion);
    updateFilter(currentFilter.copyWith(occasions: list));
  }

  void toggleCategory(String category) => selectCategory(category);

  @override
  void dispose() {
    _disposed = true;
    _request++;
    _searchTimer?.cancel();
    _repository.dispose();
    super.dispose();
  }
}
