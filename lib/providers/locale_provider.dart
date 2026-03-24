import 'package:flutter/foundation.dart';
import '../utils/app_localizations.dart';

/// Provider for managing app-wide locale (English/Arabic) switching.
class LocaleProvider extends ChangeNotifier {
  String _locale = 'en'; // Default to English

  String get locale => _locale;
  bool get isArabic => _locale == 'ar';
  bool get isEnglish => _locale == 'en';

  AppLocalizations get l10n => AppLocalizations(_locale);

  /// Toggle between English and Arabic.
  void toggleLocale() {
    _locale = _locale == 'en' ? 'ar' : 'en';
    notifyListeners();
  }

  /// Set a specific locale.
  void setLocale(String locale) {
    if (locale != _locale && (locale == 'en' || locale == 'ar')) {
      _locale = locale;
      notifyListeners();
    }
  }
}
