import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/api_client.dart';
import '../models/user_model.dart';

class UserProvider with ChangeNotifier {
  final ApiClient _apiClient = ApiClient();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  UserModel? _user;
  bool _isLoading = false;
  String? _error;

  UserProvider() {
    _loadCachedProfile();
  }

  UserModel? get user => _user;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> _loadCachedProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final cachedData = prefs.getString('user_profile');
    if (cachedData != null) {
      _user = UserModel.fromJson(jsonDecode(cachedData));
      notifyListeners();
    }
  }

  Future<void> _cacheProfile(UserModel user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_profile', jsonEncode(user.toJson()));
  }

  Future<void> fetchProfile() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Determine endpoint based on role stored in secure storage
      final role = await _storage.read(key: 'role');
      if (role == null) return; // Guard: No role, no request

      String endpoint = 'customer/profile/';
      if (role == 'rider') {
        endpoint = 'rider/profile/';
      }

      final response = await _apiClient.get(endpoint);
      if (response.statusCode == 200) {
        _user = UserModel.fromJson(response.data);
        _cacheProfile(_user!);
      }
    } catch (e) {
      _error = "Failed to load profile";
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Updates profile. Supports JSON [data] or Multipart [imagePath].
  Future<bool> updateProfile({Map<String, dynamic>? data, String? imagePath}) async {
    _isLoading = true;
    notifyListeners();

    try {
      final role = await _storage.read(key: 'role');
      if (role == null) return false;

      String endpoint = 'customer/profile/';
      if (role == 'rider') {
        endpoint = 'rider/profile/';
      }

      dynamic payload;
      
      if (imagePath != null) {
        // Use FormData for multipart requests
        payload = FormData.fromMap({
          if (data != null) ...data,
          'profile_picture': await MultipartFile.fromFile(imagePath),
        });
      } else {
        // Use plain Map for JSON requests
        payload = data;
      }

      final response = await _apiClient.patch(endpoint, data: payload);
      
      if (response.statusCode == 200) {
        _user = UserModel.fromJson(response.data);
        _cacheProfile(_user!);
        return true;
      }
    } catch (e) {
      _error = "Failed to update profile";
      debugPrint("Update Profile Error: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
    return false;
  }

  // Initial set from login
  void setUser(UserModel user) {
    _user = user;
    notifyListeners();
  }

  Future<Map<String, dynamic>> redeemPoints() async {
    _isLoading = true;
    notifyListeners();
    try {
      final response = await _apiClient.post('customer/profile/redeem/');
      if (response.statusCode == 200) {
        await fetchProfile(); // Refresh points and wallet
        return {'success': true, 'message': response.data['message']};
      } else {
        return {'success': false, 'message': response.data['error'] ?? 'Redemption failed'};
      }
    } catch (e) {
      debugPrint("Redeem Points Error: $e");
      return {'success': false, 'message': 'Network error during redemption'};
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
