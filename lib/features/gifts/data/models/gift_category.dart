String normalizeGiftText(String value) {
  const accented = 'áàâãäéèêëíìîïóòôõöúùûüç';
  const plain = 'aaaaaeeeeiiiiooooouuuuc';
  var result = value.toLowerCase().trim();
  for (var i = 0; i < accented.length; i++) {
    result = result.replaceAll(accented[i], plain[i]);
  }
  return result.replaceAll(RegExp(r'\s+'), ' ');
}

/// Presentation aliases only: the stored category is never rewritten.
String giftCategoryId(String category) => switch (normalizeGiftText(category)) {
      'lar' || 'casa' || 'nosso novo lar' => 'lar',
      'luademel' ||
      'lua de mel' ||
      'lua de mel & experiencias' ||
      'experiencias' =>
        'luademel',
      'momentos' || 'jantares' || 'jantares & momentos' => 'momentos',
      'cotas' || 'cotas flexiveis' => 'cotas',
      _ => category,
    };

String giftCategoryLabel(String category) => switch (giftCategoryId(category)) {
      'lar' => 'Nosso Novo Lar',
      'luademel' => 'Lua de Mel',
      'momentos' => 'Jantares & Momentos',
      'cotas' => 'Cotas Flexíveis',
      _ => category,
    };
