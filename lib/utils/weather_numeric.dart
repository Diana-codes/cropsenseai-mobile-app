/// Parse temperature/humidity/wind from API JSON (may be int, double, or string).
class WeatherNumeric {
  WeatherNumeric._();

  static double? parseDouble(dynamic v) {
    if (v == null) return null;
    if (v is num) return v.toDouble();
    if (v is String) {
      final s = v.trim();
      if (s.isEmpty || s.toUpperCase() == 'N/A') return null;
      return double.tryParse(s);
    }
    return null;
  }

  static int? parseIntRounded(dynamic v) {
    final d = parseDouble(v);
    return d == null ? null : d.round();
  }
}
