import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class CurrencyProvider extends ChangeNotifier {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  String? _currentUserId;

  String _currencyCode = 'PKR';

  String get currencyCode => _currencyCode;

  List<String> get availableCurrencies {
    return const [
      'PKR',
      'QAR',
      'USD',
      'EUR',
      'GBP',
      'AED',
      'SAR',
      'INR',
      'TRY',
      'CAD',
      'AUD',
    ];
  }

  String get _currencyStorageKey {
    if (_currentUserId == null || _currentUserId!.isEmpty) {
      return 'currency_settings_guest';
    }

    return 'currency_settings_$_currentUserId';
  }

  void setUserId(String? userId) {
    if (_currentUserId == userId) return;

    _currentUserId = userId;

    if (userId == null || userId.isEmpty) {
      _currencyCode = 'PKR';
      notifyListeners();
      return;
    }

    loadCurrency();
  }

  Future<void> loadCurrency() async {
    if (_currentUserId == null || _currentUserId!.isEmpty) return;

    try {
      final savedData = await _storage.read(key: _currencyStorageKey);

      if (savedData == null || savedData.trim().isEmpty) {
        _currencyCode = 'PKR';
        await saveCurrency();
        notifyListeners();
        return;
      }

      final decoded = jsonDecode(savedData) as Map<String, dynamic>;
      final savedCurrency = decoded['currencyCode']?.toString() ?? 'PKR';

      _currencyCode =
          availableCurrencies.contains(savedCurrency) ? savedCurrency : 'PKR';

      notifyListeners();
    } catch (_) {
      _currencyCode = 'PKR';
      await saveCurrency();
      notifyListeners();
    }
  }

  Future<void> changeCurrency(String value) async {
    if (!availableCurrencies.contains(value)) return;

    _currencyCode = value;

    notifyListeners();
    await saveCurrency();
  }

  Future<void> saveCurrency() async {
    if (_currentUserId == null || _currentUserId!.isEmpty) return;

    try {
      final data = {
        'currencyCode': _currencyCode,
      };

      await _storage.write(
        key: _currencyStorageKey,
        value: jsonEncode(data),
      );
    } catch (_) {
      // App still works in memory if storage fails.
    }
  }

  String get symbol {
    switch (_currencyCode) {
      case 'PKR':
        return 'Rs';
      case 'QAR':
        return 'QAR';
      case 'USD':
        return '\$';
      case 'EUR':
        return '€';
      case 'GBP':
        return '£';
      case 'AED':
        return 'AED';
      case 'SAR':
        return 'SAR';
      case 'INR':
        return '₹';
      case 'TRY':
        return '₺';
      case 'CAD':
        return 'C\$';
      case 'AUD':
        return 'A\$';
      default:
        return _currencyCode;
    }
  }

  String formatAmount(double amount) {
    final cleanAmount = amount.abs() >= 100000
        ? amount.toStringAsFixed(0)
        : amount.toStringAsFixed(amount.truncateToDouble() == amount ? 0 : 2);

    return '$symbol $cleanAmount';
  }
}