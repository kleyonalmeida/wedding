String formatGiftPrice(int cents) {
  final whole = (cents ~/ 100).toString().replaceAllMapped(
        RegExp(r'\B(?=(\d{3})+(?!\d))'),
        (_) => '.',
      );
  final fraction = (cents % 100).toString().padLeft(2, '0');
  return 'R\$ $whole,$fraction';
}
