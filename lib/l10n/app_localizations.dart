import 'package:flutter/material.dart';
import '../services/app_settings.dart';
import 'translations_en.dart';
import 'translations_rw.dart';

class AppLocalizations {
  AppLocalizations._();

  static final AppLocalizations _instance = AppLocalizations._();

  static AppLocalizations of(BuildContext context) => _instance;

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  static const List<Locale> supportedLocales = [
    Locale('en'),
    Locale('rw'),
  ];

  /// Reads the current locale from AppSettings (reactive via ValueNotifier).
  Map<String, String> get _localizedStrings =>
      AppSettings.localeNotifier.value.languageCode == 'rw'
          ? translationsRw
          : translationsEn;

  String tr(String key) => _localizedStrings[key] ?? translationsEn[key] ?? key;

  String cropName(String englishName) {
    final key = 'crop_${englishName.toLowerCase().replaceAll(' ', '_')}';
    final translated = tr(key);
    return translated != key ? translated : englishName;
  }
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => true;

  @override
  Future<AppLocalizations> load(Locale locale) async =>
      AppLocalizations._instance;

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}
