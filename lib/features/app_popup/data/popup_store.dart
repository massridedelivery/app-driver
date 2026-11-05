import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// `app_popup_dismissed` = `{id: version}` in SharedPreferences.
class PopupStore {
  const PopupStore();

  static const key = 'app_popup_dismissed';

  Future<Map<String, int>> read() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(key);
      if (raw == null) return {};
      final map = jsonDecode(raw);
      if (map is! Map) return {};
      return {
        for (final e in map.entries)
          if (e.value is num) e.key.toString(): (e.value as num).toInt(),
      };
    } catch (_) {
      return {};
    }
  }

  Future<void> write(Map<String, int> dismissed) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(key, jsonEncode(dismissed));
    } catch (_) {}
  }
}
