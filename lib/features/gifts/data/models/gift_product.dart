class GiftProduct {
  final String id;
  final String name;
  final String imageUrl;
  final String category;
  final String occasion;
  final String? flowerType;
  final double originalPrice;
  final double currentPrice;
  final int installments;
  final double installmentValue;
  final int discountPercentage;
  final bool isBestSeller;
  final bool available;
  final String giftUrl;

  GiftProduct({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.category,
    required this.occasion,
    this.flowerType,
    required this.originalPrice,
    required this.currentPrice,
    required this.installments,
    required this.installmentValue,
    required this.discountPercentage,
    required this.isBestSeller,
    required this.available,
    required this.giftUrl,
  });
}
