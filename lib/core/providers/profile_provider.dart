import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'auth_provider.dart';

class ProfileProvider extends ChangeNotifier {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  String? _currentUserId;

  String _name = 'User';
  String _email = '';
  String _phone = '';
  String _address = '';

  String get name => _name;
  String get email => _email;
  String get phone => _phone;
  String get address => _address;

  String get _profileKey {
    if (_currentUserId == null || _currentUserId!.isEmpty) {
      return 'user_profile_data_guest';
    }

    return 'user_profile_data_$_currentUserId';
  }

  void setUser(AppUser? user) {
    final newUserId = user?.id;

    if (_currentUserId == newUserId) return;

    _currentUserId = newUserId;

    if (user == null) {
      _name = 'User';
      _email = '';
      _phone = '';
      _address = '';
      notifyListeners();
      return;
    }

    _name = user.name;
    _email = user.email;
    _phone = '';
    _address = '';

    loadProfile(defaultUser: user);
  }

  Future<void> loadProfile({required AppUser defaultUser}) async {
    try {
      final savedData = await _storage.read(key: _profileKey);

      if (savedData == null || savedData.trim().isEmpty) {
        _name = defaultUser.name;
        _email = defaultUser.email;
        _phone = '';
        _address = '';

        await saveProfile();
        notifyListeners();
        return;
      }

      final data = jsonDecode(savedData) as Map<String, dynamic>;

      _name = data['name']?.toString() ?? defaultUser.name;
      _email = data['email']?.toString() ?? defaultUser.email;
      _phone = data['phone']?.toString() ?? '';
      _address = data['address']?.toString() ?? '';

      notifyListeners();
    } catch (_) {
      _name = defaultUser.name;
      _email = defaultUser.email;
      _phone = '';
      _address = '';

      await saveProfile();
      notifyListeners();
    }
  }

  Future<void> updateProfile({
    required String name,
    required String email,
    required String phone,
    required String address,
  }) async {
    _name = name;
    _email = email;
    _phone = phone;
    _address = address;

    notifyListeners();
    await saveProfile();
  }

  Future<void> saveProfile() async {
    if (_currentUserId == null || _currentUserId!.isEmpty) return;

    try {
      final data = {
        'name': _name,
        'email': _email,
        'phone': _phone,
        'address': _address,
      };

      await _storage.write(
        key: _profileKey,
        value: jsonEncode(data),
      );
    } catch (_) {
      // App still works in memory if storage fails.
    }
  }
}