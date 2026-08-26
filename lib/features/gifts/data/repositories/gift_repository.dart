import '../models/gift_product.dart';
import '../models/gift_filter.dart';

class GiftRepository {
  Future<List<GiftProduct>> getProducts({
    required GiftFilter filter,
    required int page,
    required int limit,
    String? postalCode,
  }) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 800));

    // Return dummy data based on the HTML
    List<GiftProduct> products = _mockProducts;

    // Apply filtering
    if (filter.occasions.isNotEmpty) {
      products = products.where((p) => filter.occasions.contains(p.occasion)).toList();
    }
    if (filter.categories.isNotEmpty) {
      products = products.where((p) => filter.categories.contains(p.category)).toList();
    }
    if (filter.flowerTypes.isNotEmpty) {
      products = products.where((p) => p.flowerType != null && filter.flowerTypes.contains(p.flowerType!)).toList();
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
  }

  Future<int> getTotalCount({required GiftFilter filter}) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 200));

    List<GiftProduct> products = _mockProducts;

    if (filter.occasions.isNotEmpty) {
      products = products.where((p) => filter.occasions.contains(p.occasion)).toList();
    }
    if (filter.categories.isNotEmpty) {
      products = products.where((p) => filter.categories.contains(p.category)).toList();
    }
    if (filter.flowerTypes.isNotEmpty) {
      products = products.where((p) => p.flowerType != null && filter.flowerTypes.contains(p.flowerType!)).toList();
    }

    return products.length;
  }

  // Dummy data based on the HTML provided
  static final List<GiftProduct> _mockProducts = [
    GiftProduct(
      id: '1',
      name: 'Piquenique de Margaridinhas Brancas',
      imageUrl: 'https://lh3.googleusercontent.com/aida-public/AB6AXuAe_DnVtUnJqpYSq9oCP36ZgfPfHlv5IAFE4OEoBKdf2rHo6chtfnKT9tiGDKfU77_DrE00qom5btMQoC5VFGRmDJwmFT1PzsLzXMd7C85fKaoxM6SJONCcjr4POk1C1mTCfAcyCa9NMZgzDfQVxLsASSqqzqT-2rjj8An5ol7msipyf0ayPOAQrmdSOVABrBRVhlHBY3vXPIaGFTDOGk8l-L-3tbQF0RvhDrL5YiRPVfrObnV74cgf',
      category: 'Flores',
      occasion: 'Aniversário',
      flowerType: 'Margarida',
      originalPrice: 203.30,
      currentPrice: 178.90,
      installments: 3,
      installmentValue: 59.63,
      discountPercentage: 12,
      isBestSeller: false,
      available: true,
      giftUrl: '#',
    ),
    GiftProduct(
      id: '2',
      name: 'Cesta de Chocolates e Café Premium',
      imageUrl: 'https://lh3.googleusercontent.com/aida-public/AB6AXuAME1MoFaqBg1h20LGm8mcme045JykmTXgCh5Z6cDGeQyGO0buyBGNfnwjBKObCroir3vhK0I_uxgW4vp1NS76jYQy4cOor79o9ssv_Z01_sDMyyZFukHLzcH-dbfovyHZFcp6qSDTE76hzNNPJABILzf5zfS9qVEDXbtJfHeNSuA1WXqG5LCvLPVMK4RBT71Ek8oZuPyBHaFj0iSvi2G-Zrb0qSjdGkSdU3l2V34U02HRF4zg9-td8',
      category: 'Chocolates',
      occasion: 'Agradecimento',
      originalPrice: 340.90,
      currentPrice: 298.90,
      installments: 3,
      installmentValue: 99.63,
      discountPercentage: 15,
      isBestSeller: true,
      available: true,
      giftUrl: '#',
    ),
    GiftProduct(
      id: '3',
      name: 'Box Eterno Amor',
      imageUrl: 'https://lh3.googleusercontent.com/aida-public/AB6AXuCT_coe-W3UfbViDlR8Zf7lSM6qiw7B_u0u9RK1lqtqg63LqB4_tUlj4HDmoj2xru5cYyQgbASmwa5cymJw0Gb92AOiN26IJhhi8R5FwZEVdzhEgWxr6nuA8hM3ZedFwb_27sjEsmEq-5bj9aQV1PyBa5dXzTucjMhvKiLzH4SseTGF-DGPFiGwAhconoiJhxoDK78M0u3qOUxmk-Kfanm2wOjH4XNGOV6PhXw2E75LiS4UgnOL5nwQ',
      category: 'Bebidas',
      occasion: 'Amizade',
      originalPrice: 349.90,
      currentPrice: 314.91,
      installments: 3,
      installmentValue: 104.97,
      discountPercentage: 10,
      isBestSeller: false,
      available: true,
      giftUrl: '#',
    ),
    GiftProduct(
      id: '4',
      name: 'Box Florescer com Pelúcia e Biscoitê e Balão',
      imageUrl: 'https://lh3.googleusercontent.com/aida-public/AB6AXuAAcFXauUGjfWkybY-bTxmFClWJlWV3UdjOIxCGPz8u5xa66eNojQZvLBD4Cbfy9MfC0egpdcwRx3KWa2EBq07EiSlBGhp8rrV8ZesZFnkEShV-bFkmkgxI9MFLY54YwkwSbp6rhraoaWgZ1WxiUZOLaYDrQvZdtiEPr5WeAz-ke451bdAZvxsRn_-KgCfwOXdC4Y1oOR-5B7VtFhkZUJ51_qulpsfsGEaditGjDVI94bTHVkXT4Rqi',
      category: 'Balões',
      occasion: 'Aniversário',
      originalPrice: 391.90,
      currentPrice: 267.90,
      installments: 3,
      installmentValue: 89.30,
      discountPercentage: 32,
      isBestSeller: true,
      available: true,
      giftUrl: '#',
    ),
  ];
}
