import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

class ApiClient {
  static const String _defaultBase = 'http://127.0.0.1:8000/api';
  static const String base =
      String.fromEnvironment('BACKEND_BASE_URL', defaultValue: _defaultBase);

  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  Future<void> _saveTokens(String access, String refresh) async {
    await _storage.write(key: 'access', value: access);
    await _storage.write(key: 'refresh', value: refresh);
  }

  Future<String?> get _accessToken async => _storage.read(key: 'access');

  Future<String?> get _refreshToken async => _storage.read(key: 'refresh');

  Future<void> logout() async {
    await _storage.deleteAll();
  }

  Future<(bool, String?)> register({
    required String username,
    String? email,
    required String password,
    String? fullName,
    String? phone,
    int? age,
    String? gender,
  }) async {
    final payload = <String, dynamic>{
      'username': username,
      'password': password,
    };

    void addIfPresent(String key, dynamic value) {
      if (value == null) return;
      if (value is String && value.trim().isEmpty) return;
      payload[key] = value;
    }

    addIfPresent('email', email);
    addIfPresent('full_name', fullName);
    addIfPresent('phone', phone);
    if (age != null) {
      payload['age'] = age;
    }
    addIfPresent('gender', gender);

    final response = await http.post(
      Uri.parse('$base/auth/register/'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(payload),
    );

    return (response.statusCode == 201, response.body);
  }

  Future<(bool, String?)> login(String username, String password) async {
    final response = await http.post(
      Uri.parse('$base/auth/token/'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'username': username,
        'password': password,
      }),
    );

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      await _saveTokens(decoded['access'] as String, decoded['refresh'] as String);
      return (true, null);
    }

    return (false, response.body);
  }

  Future<bool> _refreshTokenIfNeeded() async {
    final refresh = await _refreshToken;
    if (refresh == null) {
      return false;
    }

    final response = await http.post(
      Uri.parse('$base/auth/token/refresh/'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'refresh': refresh}),
    );

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      if (decoded['access'] != null) {
        await _storage.write(key: 'access', value: decoded['access'] as String);
        return true;
      }
    }

    return false;
  }

  Future<Map<String, dynamic>?> getProfile() async {
    Future<http.Response> call() async {
      final access = await _accessToken;
      return http.get(
        Uri.parse('$base/profile/'),
        headers: {
          if (access != null) 'Authorization': 'Bearer $access',
        },
      );
    }

    var response = await call();
    if (response.statusCode == 401 && await _refreshTokenIfNeeded()) {
      response = await call();
    }

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    return null;
  }
}

