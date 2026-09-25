class AppSetting {
  final String key;
  final String? value;
  final String? description;

  AppSetting({
    required this.key,
    this.value,
    this.description,
  });

  factory AppSetting.fromJson(Map<String, dynamic> json) {
    return AppSetting(
      key: json['key']?.toString() ?? '',
      value: json['value']?.toString(),
      description: json['description']?.toString(),
    );
  }
}
