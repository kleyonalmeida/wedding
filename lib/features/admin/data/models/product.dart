class Product {
  final String id;
  final String name;
  final String slug;
  final int priceCents;
  final String category;
  final String? description;
  final String? shortDescription;
  final int displayOrder;
  final bool active;
  final bool featured;
  final String? imageUrl;

  Product({
    required this.id,
    required this.name,
    required this.slug,
    required this.priceCents,
    required this.category,
    this.description,
    this.shortDescription,
    required this.displayOrder,
    required this.active,
    required this.featured,
    this.imageUrl,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    final images = json['images'] as List?;
    final primaryImage = images == null || images.isEmpty
        ? null
        : images.cast<Map<String, dynamic>>().firstWhere(
              (image) => image['isPrimary'] == true,
              orElse: () => images.first as Map<String, dynamic>,
            );
    return Product(
      id: json['id'] as String,
      name: json['name'] as String? ?? '',
      slug: json['slug'] as String? ?? '',
      priceCents: json['priceCents'] as int? ?? 0,
      category: json['category'] as String? ?? '',
      description: json['description'] as String?,
      shortDescription: json['shortDescription'] as String?,
      displayOrder: json['displayOrder'] as int? ?? 0,
      active: json['active'] as bool? ?? false,
      featured: json['featured'] as bool? ?? false,
      imageUrl:
          primaryImage?['imageUrl'] as String? ?? json['imageUrl'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'slug': slug,
      'priceCents': priceCents,
      'category': category,
      'description': description,
      'shortDescription': shortDescription,
      'displayOrder': displayOrder,
    };
  }
}
