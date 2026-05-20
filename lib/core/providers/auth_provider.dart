import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AuthProvider extends ChangeNotifier {
  AuthProvider() {
    loadCurrentUser();
  }

  static const String _usersKey = 'budget_home_users';
  static const String _currentUserKey = 'budget_home_current_user';

  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  AppUser? _currentUser;
  bool _isLoading = true;

  AppUser? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  bool get isLoggedIn => _currentUser != null;
  String? get currentUserId => _currentUser?.id;

  String _hashPassword(String password) {
    final normalized = password.trim();
    final bytes = utf8.encode('budget_home_local_salt::$normalized');
    return base64Url.encode(bytes);
  }

  Future<void> loadCurrentUser() async {
    try {
      final currentUserJson = await _storage.read(key: _currentUserKey);

      if (currentUserJson != null && currentUserJson.trim().isNotEmpty) {
        _currentUser = AppUser.fromJson(jsonDecode(currentUserJson));
      }
    } catch (_) {
      _currentUser = null;
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<List<AppUser>> _loadUsers() async {
    try {
      final usersJson = await _storage.read(key: _usersKey);

      if (usersJson == null || usersJson.trim().isEmpty) {
        return [];
      }

      final decoded = jsonDecode(usersJson) as List;

      return decoded.map((item) => AppUser.fromJson(item)).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> _saveUsers(List<AppUser> users) async {
    await _storage.write(
      key: _usersKey,
      value: jsonEncode(users.map((item) => item.toJson()).toList()),
    );
  }

  Future<void> _saveCurrentUser(AppUser user) async {
    await _storage.write(
      key: _currentUserKey,
      value: jsonEncode(user.toJson()),
    );
  }

  Future<AuthResult> register({
    required String name,
    required String email,
    required String password,
  }) async {
    final cleanName = name.trim();
    final cleanEmail = email.trim().toLowerCase();
    final cleanPassword = password.trim();

    if (cleanName.isEmpty || cleanEmail.isEmpty || cleanPassword.isEmpty) {
      return AuthResult(
        success: false,
        message: 'Please fill all required fields',
      );
    }

    if (!cleanEmail.contains('@')) {
      return AuthResult(
        success: false,
        message: 'Please enter a valid email address',
      );
    }

    if (cleanPassword.length < 6) {
      return AuthResult(
        success: false,
        message: 'Password must be at least 6 characters',
      );
    }

    final users = await _loadUsers();

    final alreadyExists = users.any(
      (item) => item.email.toLowerCase() == cleanEmail,
    );

    if (alreadyExists) {
      return AuthResult(
        success: false,
        message: 'This email is already registered',
      );
    }

    final newUser = AppUser(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      name: cleanName,
      email: cleanEmail,
      passwordHash: _hashPassword(cleanPassword),
      createdAt: DateTime.now().toIso8601String(),
    );

    users.add(newUser);

    await _saveUsers(users);
    await _saveCurrentUser(newUser);

    _currentUser = newUser;
    notifyListeners();

    return AuthResult(
      success: true,
      message: 'Account created successfully',
    );
  }

  Future<AuthResult> login({
    required String email,
    required String password,
  }) async {
    final cleanEmail = email.trim().toLowerCase();
    final cleanPassword = password.trim();

    if (cleanEmail.isEmpty || cleanPassword.isEmpty) {
      return AuthResult(
        success: false,
        message: 'Please enter email and password',
      );
    }

    final users = await _loadUsers();
    final passwordHash = _hashPassword(cleanPassword);

    final matchedUsers = users.where(
      (item) =>
          item.email.toLowerCase() == cleanEmail &&
          item.passwordHash == passwordHash,
    );

    if (matchedUsers.isEmpty) {
      return AuthResult(
        success: false,
        message: 'Invalid email or password',
      );
    }

    final user = matchedUsers.first;

    await _saveCurrentUser(user);

    _currentUser = user;
    notifyListeners();

    return AuthResult(
      success: true,
      message: 'Logged in successfully',
    );
  }

  Future<AuthResult> resetPassword({
    required String email,
    required String newPassword,
    required String confirmPassword,
  }) async {
    final cleanEmail = email.trim().toLowerCase();
    final cleanNewPassword = newPassword.trim();
    final cleanConfirmPassword = confirmPassword.trim();

    if (cleanEmail.isEmpty ||
        cleanNewPassword.isEmpty ||
        cleanConfirmPassword.isEmpty) {
      return AuthResult(
        success: false,
        message: 'Please fill all reset password fields',
      );
    }

    if (!cleanEmail.contains('@')) {
      return AuthResult(
        success: false,
        message: 'Please enter a valid email address',
      );
    }

    if (cleanNewPassword.length < 6) {
      return AuthResult(
        success: false,
        message: 'New password must be at least 6 characters',
      );
    }

    if (cleanNewPassword != cleanConfirmPassword) {
      return AuthResult(
        success: false,
        message: 'New password and confirm password do not match',
      );
    }

    try {
      final users = await _loadUsers();
      final index = users.indexWhere(
        (item) => item.email.toLowerCase() == cleanEmail,
      );

      if (index == -1) {
        return AuthResult(
          success: false,
          message: 'No account found with this email',
        );
      }

      final user = users[index];

      final updatedUser = user.copyWith(
        passwordHash: _hashPassword(cleanNewPassword),
      );

      users[index] = updatedUser;

      await _saveUsers(users);

      if (_currentUser?.id == updatedUser.id) {
        _currentUser = updatedUser;
        await _saveCurrentUser(updatedUser);
        notifyListeners();
      }

      return AuthResult(
        success: true,
        message: 'Password reset successfully. You can login now.',
      );
    } catch (_) {
      return AuthResult(
        success: false,
        message: 'Unable to reset password',
      );
    }
  }

  Future<AuthResult> changePassword({
    required String currentPassword,
    required String newPassword,
    required String confirmPassword,
  }) async {
    final user = _currentUser;

    if (user == null) {
      return AuthResult(
        success: false,
        message: 'No logged-in user found',
      );
    }

    final cleanCurrentPassword = currentPassword.trim();
    final cleanNewPassword = newPassword.trim();
    final cleanConfirmPassword = confirmPassword.trim();

    if (cleanCurrentPassword.isEmpty ||
        cleanNewPassword.isEmpty ||
        cleanConfirmPassword.isEmpty) {
      return AuthResult(
        success: false,
        message: 'Please fill all password fields',
      );
    }

    if (_hashPassword(cleanCurrentPassword) != user.passwordHash) {
      return AuthResult(
        success: false,
        message: 'Current password is incorrect',
      );
    }

    if (cleanNewPassword.length < 6) {
      return AuthResult(
        success: false,
        message: 'New password must be at least 6 characters',
      );
    }

    if (cleanNewPassword != cleanConfirmPassword) {
      return AuthResult(
        success: false,
        message: 'New password and confirm password do not match',
      );
    }

    if (_hashPassword(cleanNewPassword) == user.passwordHash) {
      return AuthResult(
        success: false,
        message: 'New password must be different from current password',
      );
    }

    try {
      final users = await _loadUsers();
      final index = users.indexWhere((item) => item.id == user.id);

      if (index == -1) {
        return AuthResult(
          success: false,
          message: 'User account not found',
        );
      }

      final updatedUser = user.copyWith(
        passwordHash: _hashPassword(cleanNewPassword),
      );

      users[index] = updatedUser;

      await _saveUsers(users);
      await _saveCurrentUser(updatedUser);

      _currentUser = updatedUser;
      notifyListeners();

      return AuthResult(
        success: true,
        message: 'Password changed successfully',
      );
    } catch (_) {
      return AuthResult(
        success: false,
        message: 'Unable to change password',
      );
    }
  }

  Future<void> logout() async {
    await _storage.delete(key: _currentUserKey);

    _currentUser = null;
    notifyListeners();
  }

  Future<AuthResult> deleteCurrentAccount() async {
    final user = _currentUser;

    if (user == null) {
      return AuthResult(
        success: false,
        message: 'No logged-in user found',
      );
    }

    try {
      final users = await _loadUsers();

      users.removeWhere((item) => item.id == user.id);

      await _saveUsers(users);
      await _storage.delete(key: _currentUserKey);
      await _storage.delete(key: 'finance_records_data_${user.id}');
      await _storage.delete(key: 'user_profile_data_${user.id}');
      await _storage.delete(key: 'currency_settings_${user.id}');

      _currentUser = null;
      notifyListeners();

      return AuthResult(
        success: true,
        message: 'Account deleted successfully',
      );
    } catch (_) {
      return AuthResult(
        success: false,
        message: 'Unable to delete account',
      );
    }
  }
}

class AppUser {
  AppUser({
    required this.id,
    required this.name,
    required this.email,
    required this.passwordHash,
    required this.createdAt,
  });

  final String id;
  final String name;
  final String email;
  final String passwordHash;
  final String createdAt;

  AppUser copyWith({
    String? id,
    String? name,
    String? email,
    String? passwordHash,
    String? createdAt,
  }) {
    return AppUser(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      passwordHash: passwordHash ?? this.passwordHash,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  factory AppUser.fromJson(dynamic json) {
    final map = Map<String, dynamic>.from(json as Map);

    return AppUser(
      id: map['id']?.toString() ?? '',
      name: map['name']?.toString() ?? '',
      email: map['email']?.toString() ?? '',
      passwordHash:
          map['passwordHash']?.toString() ?? map['password']?.toString() ?? '',
      createdAt: map['createdAt']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'passwordHash': passwordHash,
      'createdAt': createdAt,
    };
  }
}

class AuthResult {
  AuthResult({
    required this.success,
    required this.message,
  });

  final bool success;
  final String message;
}