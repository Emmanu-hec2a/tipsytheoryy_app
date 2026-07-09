import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../core/api_client.dart';

enum AuthStatus { unauthenticated, authenticating, authenticated, failed }

class AuthProvider with ChangeNotifier {
  final ApiClient _apiClient = ApiClient();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  
  AuthStatus _status = AuthStatus.unauthenticated;
  String? _role;
  String? _errorMessage;

  AuthStatus get status => _status;
  String? get role => _role;
  String? get errorMessage => _errorMessage;

  AuthProvider() {
    checkAuth();
  }

  Future<bool> login(String username, String password) async {
    _status = AuthStatus.authenticating;
    _errorMessage = null;
    notifyListeners();

    try {
      // Use the new unified login endpoint
      final response = await _apiClient.post('auth/login/', data: {
        'username': username,
        'password': password,
      });

      if (response.statusCode == 200) {
        final data = response.data;
        await _saveAuthData(data);
        return true;
      }
    } catch (e) {
      _errorMessage = "Login failed. Please check your credentials.";
    }

    _status = AuthStatus.failed;
    notifyListeners();
    return false;
  }

  Future<bool> signup({
    required String email,
    required String password,
    required String fullName,
    required String phone,
    required String role,
  }) async {
    _status = AuthStatus.authenticating;
    _errorMessage = null;
    notifyListeners();

    try {
      final String path = role == 'rider' ? 'auth/rider/signup/' : 'auth/customer/signup/';
      final response = await _apiClient.post(path, data: {
        'email': email,
        'password': password,
        'username': email, // Use email as username
        'full_name': fullName,
        'phone': phone,
      });

      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = response.data;
        await _saveAuthData(data);
        return true;
      }
    } catch (e) {
      _errorMessage = "Signup failed. Please try again.";
      print("Signup error: $e");
    }

    _status = AuthStatus.failed;
    notifyListeners();
    return false;
  }

  Future<void> _saveAuthData(Map<String, dynamic> data) async {
    await _storage.write(key: 'access_token', value: data['access']);
    await _storage.write(key: 'refresh_token', value: data['refresh']);
    await _storage.write(key: 'role', value: data['role']);
    
    _role = data['role'];
    _status = AuthStatus.authenticated;
    notifyListeners();
  }

  Future<void> logout() async {
    await _storage.deleteAll();
    _role = null;
    _status = AuthStatus.unauthenticated;
    notifyListeners();
  }

  Future<void> checkAuth() async {
    final token = await _storage.read(key: 'access_token');
    final role = await _storage.read(key: 'role');
    if (token != null) {
      _role = role;
      _status = AuthStatus.authenticated;
    } else {
      _status = AuthStatus.unauthenticated;
    }
    notifyListeners();
  }
}
