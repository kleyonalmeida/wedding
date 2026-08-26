enum GiftSortOrder {
  bestSeller,
  highestPrice,
  lowestPrice,
}

class GiftFilter {
  final List<String> occasions;
  final List<String> categories;
  final List<String> flowerTypes;
  final GiftSortOrder sortOrder;

  GiftFilter({
    this.occasions = const [],
    this.categories = const [],
    this.flowerTypes = const [],
    this.sortOrder = GiftSortOrder.bestSeller,
  });

  GiftFilter copyWith({
    List<String>? occasions,
    List<String>? categories,
    List<String>? flowerTypes,
    GiftSortOrder? sortOrder,
  }) {
    return GiftFilter(
      occasions: occasions ?? this.occasions,
      categories: categories ?? this.categories,
      flowerTypes: flowerTypes ?? this.flowerTypes,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }

  bool get isEmpty => occasions.isEmpty && categories.isEmpty && flowerTypes.isEmpty;
}
