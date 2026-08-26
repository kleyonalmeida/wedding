import 'package:flutter/foundation.dart';
import '../../data/models/gift_product.dart';
import '../../data/models/gift_filter.dart';
import '../../data/repositories/gift_repository.dart';

class GiftCatalogController extends ChangeNotifier {
  final GiftRepository _repository = GiftRepository();
  
  List<GiftProduct> products = [];
  bool isLoading = false;
  String? error;
  
  GiftFilter currentFilter = GiftFilter();
  int currentPage = 1;
  final int limit = 10;
  bool hasMore = true;
  
  int totalResults = 0;

  GiftCatalogController() {
    loadProducts(refresh: true);
  }

  Future<void> loadProducts({bool refresh = false}) async {
    if (isLoading) return;
    
    if (refresh) {
      currentPage = 1;
      products = [];
      hasMore = true;
    }

    if (!hasMore) return;

    isLoading = true;
    error = null;
    notifyListeners();

    try {
      final newProducts = await _repository.getProducts(
        filter: currentFilter,
        page: currentPage,
        limit: limit,
      );
      
      totalResults = await _repository.getTotalCount(filter: currentFilter);

      if (newProducts.length < limit) {
        hasMore = false;
      }
      
      products.addAll(newProducts);
      currentPage++;
    } catch (e) {
      error = 'Erro ao carregar produtos. Tente novamente.';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  void updateFilter(GiftFilter newFilter) {
    currentFilter = newFilter;
    loadProducts(refresh: true);
  }

  void setSortOrder(GiftSortOrder order) {
    if (currentFilter.sortOrder == order) return;
    updateFilter(currentFilter.copyWith(sortOrder: order));
  }
  
  void clearFilters() {
    updateFilter(GiftFilter(sortOrder: currentFilter.sortOrder));
  }

  void toggleOccasion(String occasion) {
    final list = List<String>.from(currentFilter.occasions);
    if (list.contains(occasion)) {
      list.remove(occasion);
    } else {
      list.add(occasion);
    }
    updateFilter(currentFilter.copyWith(occasions: list));
  }
  
  void toggleCategory(String category) {
    final list = List<String>.from(currentFilter.categories);
    if (list.contains(category)) {
      list.remove(category);
    } else {
      list.add(category);
    }
    updateFilter(currentFilter.copyWith(categories: list));
  }
}
