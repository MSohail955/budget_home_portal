import 'dart:async';
import 'dart:convert';
import 'dart:html' as html;

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AuthProvider extends ChangeNotifier {
  AuthProvider() {
    loadCurrentUser();
  }

  static const String baseUrl = 'http://localhost:5168/api';

  static const String _currentUserKey = 'budget_home_current_user';
  static const String _authTokenKey = 'budget_home_auth_token';

  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  AppUser? _currentUser;
  String? _token;
  bool _isLoading = true;

  AppUser? get currentUser => _currentUser;
  String? get token => _token;
  bool get isLoading => _isLoading;
  bool get isLoggedIn => _currentUser != null && (_token?.isNotEmpty ?? false);
  String? get currentUserId => _currentUser?.id;

  Map<String, String> get authorizedHeaders {
    return {
      'Content-Type': 'application/json',
      if (_token != null && _token!.isNotEmpty) 'Authorization': 'Bearer $_token',
    };
  }

  Future<Map<String, dynamic>> _postJson(
    String path,
    Map<String, dynamic> body,
  ) async {
    final completer = Completer<Map<String, dynamic>>();
    final request = html.HttpRequest();

    void completeFromResponse() {
      final statusCode = request.status ?? 0;
      final responseText = request.responseText ?? '';
      final isSuccess = statusCode >= 200 && statusCode < 300;

      if (responseText.trim().isEmpty) {
        completer.complete({
          'success': isSuccess,
          'statusCode': statusCode,
          'message': isSuccess
              ? 'Request completed successfully'
              : _friendlyHttpMessage(statusCode),
        });
        return;
      }

      try {
        final decoded = jsonDecode(responseText);

        if (decoded is Map<String, dynamic>) {
          completer.complete({
            ...decoded,
            'success': isSuccess,
            'statusCode': statusCode,
            if (!decoded.containsKey('message') && !isSuccess)
              'message': _friendlyHttpMessage(statusCode),
          });
          return;
        }

        completer.complete({
          'success': isSuccess,
          'statusCode': statusCode,
          'message': decoded.toString(),
        });
      } catch (_) {
        completer.complete({
          'success': isSuccess,
          'statusCode': statusCode,
          'message': responseText.trim().isNotEmpty
              ? responseText
              : _friendlyHttpMessage(statusCode),
        });
      }
    }

    try {
      request.open('POST', '$baseUrl$path');
      request.setRequestHeader('Content-Type', 'application/json');

      request.onLoadEnd.listen((_) {
        if (!completer.isCompleted) {
          completeFromResponse();
        }
      });

      request.onError.listen((_) {
        if (!completer.isCompleted) {
          completer.complete({
            'success': false,
            'statusCode': 0,
            'message':
                'Cannot reach the server. Please make sure the backend API is running and CORS is enabled.',
          });
        }
      });

      request.onTimeout.listen((_) {
        if (!completer.isCompleted) {
          completer.complete({
            'success': false,
            'statusCode': 0,
            'message': 'Server request timed out. Please try again.',
          });
        }
      });

      request.timeout = 15000;
      request.send(jsonEncode(body));

      return completer.future;
    } catch (_) {
      return {
        'success': false,
        'statusCode': 0,
        'message':
            'Cannot reach the server. Please make sure the backend API is running and CORS is enabled.',
      };
    }
  }

  String _friendlyHttpMessage(int statusCode) {
    switch (statusCode) {
      case 400:
        return 'Please check the submitted information and try again.';
      case 401:
        return 'Incorrect email or password. Please check your login details.';
      case 403:
        return 'You do not have permission to perform this action.';
      case 404:
        return 'Requested API endpoint was not found.';
      case 409:
        return 'This record already exists.';
      case 500:
        return 'Server error. Please try again later.';
      default:
        return 'Request failed. Please try again.';
    }
  }

  String _extractMessage(Map<String, dynamic> response, String fallback) {
    final message = response['message'] ??
        response['title'] ??
        response['error'] ??
        response['errors'];

    if (message == null) return fallback;

    if (message is String) return message;

    return message.toString();
  }

  AppUser _userFromBackend(Map<String, dynamic> data) {
    final userMap = data['user'] is Map
        ? Map<String, dynamic>.from(data['user'] as Map)
        : data;

    final firstName = userMap['firstName']?.toString() ?? '';
    final lastName = userMap['lastName']?.toString() ?? '';
    final backendName = userMap['name']?.toString();

    final fullName = backendName?.trim().isNotEmpty == true
        ? backendName!.trim()
        : '$firstName $lastName'.trim();

    return AppUser(
      id: userMap['id']?.toString() ?? '',
      name: fullName.isEmpty ? 'User' : fullName,
      email: userMap['email']?.toString() ?? '',
      passwordHash: '',
      createdAt: userMap['createdAt']?.toString() ?? DateTime.now().toIso8601String(),
    );
  }

  Future<void> loadCurrentUser() async {
    try {
      final currentUserJson = await _storage.read(key: _currentUserKey);
      final savedToken = await _storage.read(key: _authTokenKey);

      if (currentUserJson != null &&
          currentUserJson.trim().isNotEmpty &&
          savedToken != null &&
          savedToken.trim().isNotEmpty) {
        _currentUser = AppUser.fromJson(jsonDecode(currentUserJson));
        _token = savedToken;
      }
    } catch (_) {
      _currentUser = null;
      _token = null;
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> _saveSession({
    required AppUser user,
    required String token,
  }) async {
    await _storage.write(
      key: _currentUserKey,
      value: jsonEncode(user.toJson()),
    );

    await _storage.write(
      key: _authTokenKey,
      value: token,
    );

    _currentUser = user;
    _token = token;
    notifyListeners();
  }

  Future<AuthResult> sendRegistrationOtp({
    required String email,
  }) async {
    final cleanEmail = email.trim().toLowerCase();

    if (cleanEmail.isEmpty || !cleanEmail.contains('@')) {
      return AuthResult(
        success: false,
        message: 'Please enter a valid email address',
      );
    }

    final response = await _postJson(
      '/Auth/send-registration-otp',
      {'email': cleanEmail},
    );

    final success = response['success'] == true;

    return AuthResult(
      success: success,
      message: _extractMessage(
        response,
        success ? 'Registration OTP sent successfully' : 'Unable to send OTP',
      ),
    );
  }

  Future<AuthResult> register({
    required String name,
    required String email,
    required String password,
    String? confirmPassword,
    String? otp,
  }) async {
    final cleanName = name.trim();
    final cleanEmail = email.trim().toLowerCase();
    final cleanPassword = password.trim();
    final cleanConfirmPassword = (confirmPassword ?? password).trim();

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

    if (cleanPassword != cleanConfirmPassword) {
      return AuthResult(
        success: false,
        message: 'Password and confirm password do not match',
      );
    }

    final nameParts = cleanName.split(RegExp(r'\s+'));
    final firstName = nameParts.isEmpty ? cleanName : nameParts.first;
    final lastName = nameParts.length > 1 ? nameParts.skip(1).join(' ') : '';

    final response = await _postJson(
      '/Auth/register',
      {
        'name': cleanName,
        'firstName': firstName,
        'lastName': lastName,
        'email': cleanEmail,
        'password': cleanPassword,
        'confirmPassword': cleanConfirmPassword,
        if (otp != null && otp.trim().isNotEmpty) 'otp': otp.trim(),
      },
    );

    final success = response['success'] == true;

    if (!success) {
      return AuthResult(
        success: false,
        message: _extractMessage(response, 'Unable to create account'),
      );
    }

    final token = response['token']?.toString();

    if (token != null && token.isNotEmpty) {
      await _saveSession(
        user: _userFromBackend(response),
        token: token,
      );
    }

    return AuthResult(
      success: true,
      message: _extractMessage(response, 'Account created successfully'),
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

    final response = await _postJson(
      '/Auth/login',
      {
        'email': cleanEmail,
        'password': cleanPassword,
      },
    );

    final success = response['success'] == true;
    final token = response['token']?.toString();

    if (!success || token == null || token.isEmpty) {
      final statusCode = response['statusCode'];

      return AuthResult(
        success: false,
        message: statusCode == 400 || statusCode == 401
            ? 'Incorrect email or password. Please check your login details and try again.'
            : _extractMessage(
                response,
                'Unable to login right now. Please try again.',
              ),
      );
    }

    await _saveSession(
      user: _userFromBackend(response),
      token: token,
    );

    return AuthResult(
      success: true,
      message: 'Logged in successfully',
    );
  }

  Future<AuthResult> sendForgotPasswordOtp({
    required String email,
  }) async {
    final cleanEmail = email.trim().toLowerCase();

    if (cleanEmail.isEmpty || !cleanEmail.contains('@')) {
      return AuthResult(
        success: false,
        message: 'Please enter a valid email address',
      );
    }

    final response = await _postJson(
      '/Auth/send-forgot-password-otp',
      {'email': cleanEmail},
    );

    final success = response['success'] == true;

    return AuthResult(
      success: success,
      message: _extractMessage(
        response,
        success ? 'Password reset OTP sent successfully' : 'Unable to send OTP',
      ),
    );
  }

  Future<AuthResult> resetPassword({
    required String email,
    required String newPassword,
    required String confirmPassword,
    String? otp,
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

    final response = await _postJson(
      '/Auth/reset-password',
      {
        'email': cleanEmail,
        'newPassword': cleanNewPassword,
        'confirmPassword': cleanConfirmPassword,
        if (otp != null && otp.trim().isNotEmpty) 'otp': otp.trim(),
      },
    );

    final success = response['success'] == true;

    return AuthResult(
      success: success,
      message: _extractMessage(
        response,
        success ? 'Password reset successfully. You can login now.' : 'Unable to reset password',
      ),
    );
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

    final cleanNewPassword = newPassword.trim();
    final cleanConfirmPassword = confirmPassword.trim();

    if (currentPassword.trim().isEmpty ||
        cleanNewPassword.isEmpty ||
        cleanConfirmPassword.isEmpty) {
      return AuthResult(
        success: false,
        message: 'Please fill all password fields',
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

    // Backend currently exposes reset-password/forgot-password but not a visible
    // change-password endpoint in Swagger. Keep this safe frontend response.
    return AuthResult(
      success: false,
      message:
          'Change password API is not available yet. Use Forgot Password from login screen.',
    );
  }

  Future<void> logout() async {
    await _storage.delete(key: _currentUserKey);
    await _storage.delete(key: _authTokenKey);

    _currentUser = null;
    _token = null;
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

    await _storage.delete(key: _currentUserKey);
    await _storage.delete(key: _authTokenKey);
    await _storage.delete(key: 'finance_records_data_${user.id}');
    await _storage.delete(key: 'user_profile_data_${user.id}');
    await _storage.delete(key: 'currency_settings_${user.id}');

    _currentUser = null;
    _token = null;
    notifyListeners();

    return AuthResult(
      success: true,
      message:
          'Local session deleted. Backend delete account API is not available yet.',
    );
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