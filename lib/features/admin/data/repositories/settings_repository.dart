import '../../../../core/network/api_client.dart';
import '../models/app_setting.dart';

class SettingsRepository {
  final ApiClient api;

  SettingsRepository(this.api);

  Future<List<AppSetting>> get() async {
    final response = await api.get('/api/admin/settings');
    final list = response as List;
    return list.map((e) => AppSetting.fromJson(e)).toList();
  }

  Future<void> patch(Map<String, String> values) async {
    await api.patch('/api/admin/settings', {
      'settings': [
        for (final entry in values.entries)
          {'key': entry.key, 'value': entry.value},
      ],
    });
  }
}
