import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import '../core/api_client.dart';
import '../services/notification_service.dart';

enum AuthStatus { unauthenticated, authenticating, authenticated, failed }

class AuthProvider with ChangeNotifier {
  final ApiClient _apiClient = ApiClient();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  
  AuthStatus _status = AuthStatus.unauthenticated;
  String? _role;
  String? _errorMessage;
  bool _requiresPhoneSetup = false;
  ThemeMode _themeMode = ThemeMode.system;

  AuthStatus get status => _status;
  String? get role => _role;
  String? get errorMessage => _errorMessage;
  bool get requiresPhoneSetup => _requiresPhoneSetup;
  ThemeMode get themeMode => _themeMode;

  AuthProvider() {
    checkAuth();
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    final theme = await _storage.read(key: 'theme_mode');
    if (theme == 'light') {
      _themeMode = ThemeMode.light;
    } else if (theme == 'dark') {
      _themeMode = ThemeMode.dark;
    } else {
      _themeMode = ThemeMode.system;
    }
    notifyListeners();
  }

  Future<void> toggleTheme() async {
    if (_themeMode == ThemeMode.light) {
      _themeMode = ThemeMode.dark;
      await _storage.write(key: 'theme_mode', value: 'dark');
    } else {
      _themeMode = ThemeMode.light;
      await _storage.write(key: 'theme_mode', value: 'light');
    }
    notifyListeners();
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
    String? dob,
    Map<String, dynamic>? metadata,
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
        'dob': dob,
        'verification_metadata': metadata,
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

  // --- 🌐 SOCIAL AUTHENTICATION ---

  Future<bool> signInWithGoogle() async {
    _status = AuthStatus.authenticating;
    _errorMessage = null;
    notifyListeners();

    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) {
        _status = AuthStatus.unauthenticated;
        notifyListeners();
        return false;
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential = await FirebaseAuth.instance.signInWithCredential(credential);
      final String? idToken = await userCredential.user?.getIdToken();

      if (idToken != null) {
        return await _socialAuthenticateWithBackend(idToken);
      }
    } catch (e) {
      _errorMessage = "Google sign-in failed. Please try again.";
      debugPrint("Google Auth Error: $e");
    }

    _status = AuthStatus.failed;
    notifyListeners();
    return false;
  }

  Future<bool> signInWithApple() async {
    _status = AuthStatus.authenticating;
    _errorMessage = null;
    notifyListeners();

    try {
      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );

      final OAuthCredential credential = OAuthProvider("apple.com").credential(
        idToken: appleCredential.identityToken,
        accessToken: appleCredential.authorizationCode,
      );

      final UserCredential userCredential = await FirebaseAuth.instance.signInWithCredential(credential);
      final String? idToken = await userCredential.user?.getIdToken();

      if (idToken != null) {
        return await _socialAuthenticateWithBackend(idToken);
      }
    } catch (e) {
      _errorMessage = "Apple sign-in failed. Please try again.";
      debugPrint("Apple Auth Error: $e");
    }

    _status = AuthStatus.failed;
    notifyListeners();
    return false;
  }

  Future<bool> _socialAuthenticateWithBackend(String token) async {
    try {
      final response = await _apiClient.post('auth/social-login/', data: {
        'token': token,
      });

      if (response.statusCode == 200) {
        final data = response.data;
        
        if (data['requires_phone_setup'] == true) {
          // Temporarily save tokens but flag that we need phone linking
          await _saveAuthData(data);
          return true; // The UI will check the state and navigate to Phone Link
        }

        await _saveAuthData(data);
        return true;
      }
    } catch (e) {
      _errorMessage = "Social authentication failed on server.";
      debugPrint("Backend Social Auth Error: $e");
    }
    return false;
  }

  Future<bool> linkSocialPhone(String phone) async {
    _status = AuthStatus.authenticating;
    notifyListeners();
    try {
      final response = await _apiClient.post('auth/social-link-phone/', data: {
        'phone': phone,
      });
      if (response.statusCode == 200) {
        final data = response.data;
        // If we merged, we might have new tokens
        if (data['access'] != null) {
          await _saveAuthData(data);
        }
        return true;
      }
    } catch (e) {
      _errorMessage = "Failed to link phone. It might be in use elsewhere.";
    } finally {
      _status = AuthStatus.authenticated;
      notifyListeners();
    }
    return false;
  }

  Future<void> _saveAuthData(Map<String, dynamic> data) async {
    await _storage.write(key: 'access_token', value: data['access']);
    await _storage.write(key: 'refresh_token', value: data['refresh']);
    await _storage.write(key: 'role', value: data['role']);
    
    _role = data['role'];
    _requiresPhoneSetup = data['requires_phone_setup'] ?? false;
    _status = AuthStatus.authenticated;
    
    // Register FCM token after successful authentication
    NotificationService().registerToken();

    notifyListeners();
  }

  Future<void> logout({
    VoidCallback? onLogout,
  }) async {
    await _storage.deleteAll();
    _apiClient.clearCache(); // Clear the networking cache
    _role = null;
    _status = AuthStatus.unauthenticated;
    if (onLogout != null) onLogout();
    notifyListeners();
  }

  Future<void> checkAuth() async {
    final token = await _storage.read(key: 'access_token');
    final role = await _storage.read(key: 'role');
    
    if (token != null && role != null) {
      _role = role;
      _status = AuthStatus.authenticated;
      
      // Ensure FCM token is registered on startup if authenticated
      NotificationService().registerToken();
    } else {
      _role = null;
      _status = AuthStatus.unauthenticated;
      // If we have a token but no role, it's an inconsistent state.
      if (token != null) await logout();
    }
    notifyListeners();
  }

  // --- 🔐 FORGOT PASSWORD ---

  Future<bool> requestPasswordReset(String email) async {
    _status = AuthStatus.authenticating;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _apiClient.post('auth/password-reset/request/', data: {
        'email': email,
      });

      if (response.statusCode == 200) {
        _status = AuthStatus.unauthenticated; // Reset to unauthenticated so UI can show message
        notifyListeners();
        return true;
      }
    } catch (e) {
      _errorMessage = "Failed to request reset. Please check your internet.";
    }

    _status = AuthStatus.failed;
    notifyListeners();
    return false;
  }

  Future<bool> verifyPasswordReset(String email, String otp, String newPassword) async {
    _status = AuthStatus.authenticating;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _apiClient.post('auth/password-reset/verify/', data: {
        'email': email,
        'otp': otp,
        'password': newPassword,
      });

      if (response.statusCode == 200) {
        _status = AuthStatus.unauthenticated;
        notifyListeners();
        return true;
      }
    } catch (e) {
      _errorMessage = "Invalid code or reset failed. Please try again.";
    }

    _status = AuthStatus.failed;
    notifyListeners();
    return false;
  }
}
