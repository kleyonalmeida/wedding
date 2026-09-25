class GiftFilter {
  final List<String> occasions;
  final List<String> categories;
  final List<String> flowerTypes;

  GiftFilter({
    this.occasions = const [],
    this.categories = const [],
    this.flowerTypes = const [],
  });

  GiftFilter copyWith({
    List<String>? occasions,
    List<String>? categories,
    List<String>? flowerTypes,
  }) {
    return GiftFilter(
      occasions: occasions ?? this.occasions,
      categories: categories ?? this.categories,
      flowerTypes: flowerTypes ?? this.flowerTypes,
    );
  }

  bool get isEmpty =>
      occasions.isEmpty && categories.isEmpty && flowerTypes.isEmpty;
}
