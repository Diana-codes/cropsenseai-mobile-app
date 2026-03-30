import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppSettings {
  static const _notificationsKey = 'cropsense_notifications_v1';
  static const _localeKey = 'cropsense_locale_v1';

  /// In-memory value — always load via [init] on startup.
  static bool notificationsEnabled = true;

  /// Reactive notifier — widgets can listen to this for instant UI updates.
  static final notificationsNotifier = ValueNotifier<bool>(true);

  /// Language notifier — drives app-wide locale switching.
  static final localeNotifier = ValueNotifier<Locale>(const Locale('en'));

  /// Call once in main() before runApp to hydrate from disk.
  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    notificationsEnabled = prefs.getBool(_notificationsKey) ?? true;
    notificationsNotifier.value = notificationsEnabled;

    final savedLocale = prefs.getString(_localeKey) ?? 'en';
    localeNotifier.value = Locale(savedLocale);
  }

  /// Toggle and persist in one call — use this instead of setting the bool directly.
  static Future<void> setNotifications(bool value) async {
    notificationsEnabled = value;
    notificationsNotifier.value = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_notificationsKey, value);
  }

  /// Change app language and persist.
  static Future<void> setLocale(Locale locale) async {
    localeNotifier.value = locale;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_localeKey, locale.languageCode);
  }
}
