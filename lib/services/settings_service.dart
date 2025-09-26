import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsService extends ChangeNotifier {
  static const String _currencyKey = 'currency_code';

  String _currencyCode = 'XOF'; // FCFA par défaut

  String get currencyCode => _currencyCode;
  String get currencySymbol => _symbolFor(_currencyCode);

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _currencyCode = prefs.getString(_currencyKey) ?? 'XOF';
    notifyListeners();
  }

  Future<void> setCurrency(String code) async {
    _currencyCode = code;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_currencyKey, code);
    notifyListeners();
  }

  String formatAmount(num value) {
    final symbol = _symbolFor(_currencyCode);
    final formatter = NumberFormat.currency(locale: 'fr_FR', symbol: symbol);
    String out = formatter.format(value);
    // Remove trailing ,00 or .00 if present (keep non-zero decimals)
    out = out.replaceAll(RegExp(r'(,|\.)00(?=\s|$)'), '');
    return out;
  }

  String _symbolFor(String code) {
    switch (code) {
      case 'XOF':
        return 'FCFA';
      case 'EUR':
        return '€';
      case 'USD':
        return '\$';
      default:
        return code;
    }
  }
}


