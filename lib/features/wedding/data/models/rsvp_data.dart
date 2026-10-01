class RsvpData {
  final String identificacaoNoConvite;
  final bool attending;
  final int children;
  final String email;
  final String phone;
  final bool acceptTerms;

  RsvpData({
    required this.identificacaoNoConvite,
    required this.attending,
    required this.children,
    required this.email,
    required this.phone,
    required this.acceptTerms,
  });
}
