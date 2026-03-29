import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppSettings {
  static const _notificationsKey = 'cropsense_notifications_v1';

  /// In-memory value — always load via [init] on startup.
  static bool notificationsEnabled = true;

  /// Reactive notifier — widgets can listen to this for instant UI updates.
  static final notificationsNotifier = ValueNotifier<bool>(true);

  /// Call once in main() before runApp to hydrate from disk.
  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    notificationsEnabled = prefs.getBool(_notificationsKey) ?? true;
    notificationsNotifier.value = notificationsEnabled;
  }

  /// Toggle and persist in one call — use this instead of setting the bool directly.
  static Future<void> setNotifications(bool value) async {
    notificationsEnabled = value;
    notificationsNotifier.value = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_notificationsKey, value);
  }
}
