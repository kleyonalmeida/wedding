class RsvpData {
  final String name;
  final bool attending;
  final int adults;
  final int children;
  final String email;
  final String phone;
  final String message;
  final bool acceptTerms;
  final bool acceptUpdates;

  RsvpData({
    required this.name,
    required this.attending,
    required this.adults,
    required this.children,
    required this.email,
    required this.phone,
    required this.message,
    required this.acceptTerms,
    required this.acceptUpdates,
  });
}
