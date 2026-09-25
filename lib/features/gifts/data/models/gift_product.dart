class GiftProduct {
  final String id;
  final String name;
  final String imageUrl;
  final String category;
  final String occasion;
  final String? flowerType;
  final int priceCents;
  final bool isBestSeller;
  final bool available;

  GiftProduct({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.category,
    required this.occasion,
    this.flowerType,
    required this.priceCents,
    required this.isBestSeller,
    required this.available,
  });
}
