import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../core/api_client.dart';
import '../models/shiriki_session_model.dart';

class ShirikiProvider with ChangeNotifier {
  final ApiClient _apiClient = ApiClient();
  final _storage = const FlutterSecureStorage();
  
  ShirikiSessionModel? _currentSession;
  String? _activeInviteCode;
  bool _isLoading = false;
  String? _error;

  ShirikiSessionModel? get currentSession => _currentSession;
  String? get activeInviteCode => _activeInviteCode;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> _persistSession(String code) async {
    _activeInviteCode = code;
    await _storage.write(key: 'active_shiriki_code', value: code);
    notifyListeners();
  }

  Future<void> loadPersistedSession() async {
    final code = await _storage.read(key: 'active_shiriki_code');
    if (code != null) {
      _activeInviteCode = code;
      await fetchSession(code);
    }
  }

  Future<void> clear() async {
    _currentSession = null;
    _activeInviteCode = null;
    _error = null;
    await _storage.delete(key: 'active_shiriki_code');
    notifyListeners();
  }

  Future<bool> createSession(String orderNumber) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiClient.post('customer/shiriki/create/', data: {
        'order_number': orderNumber,
      });

      if (response.statusCode == 201) {
        _currentSession = ShirikiSessionModel.fromJson(response.data);
        await _persistSession(_currentSession!.inviteCode);
        return true;
      } else {
        _error = response.data['error'] ?? 'Failed to create session';
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
    return false;
  }

  Future<void> fetchSession(String inviteCode) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // 🛡️ NO CACHE: Ensure we see real-time pot progress
      final response = await _apiClient.get(
        'customer/shiriki/session/$inviteCode/',
        noCache: true,
      );
      if (response.statusCode == 200) {
        _currentSession = ShirikiSessionModel.fromJson(response.data);
        if (_currentSession?.status == 'active') {
          await _persistSession(inviteCode);
        } else {
          await clear(); // Auto-clear if completed/expired
        }
      } else {
        _error = 'Session not found';
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<Map<String, dynamic>> contribute({
    required String inviteCode,
    required double amount,
    required String phone,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiClient.post('customer/shiriki/contribute/', data: {
        'invite_code': inviteCode,
        'amount': amount,
        'phone': phone,
      });

      if (response.statusCode == 200 || response.statusCode == 201) {
        return response.data;
      } else {
        final err = response.data['error'] ?? 'Contribution failed';
        _error = err;
        return {'success': false, 'error': err};
      }
    } catch (e) {
      _error = e.toString();
      return {'success': false, 'error': e.toString()};
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
