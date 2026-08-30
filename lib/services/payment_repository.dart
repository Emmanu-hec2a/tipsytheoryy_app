import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../core/api_client.dart';
import '../models/payment_attempt_model.dart';

class PaymentRepository {
  final ApiClient api;
  final FlutterSecureStorage storage;
  static const _activeKey = 'active_payment_attempt';

  PaymentRepository({ApiClient? api, FlutterSecureStorage? storage})
    : api = api ?? ApiClient(),
      storage = storage ?? const FlutterSecureStorage();

  Future<PaymentAttemptModel?> loadActive() async {
    final raw = await storage.read(key: _activeKey);
    if (raw == null) return null;
    return PaymentAttemptModel.fromJson(jsonDecode(raw));
  }

  Future<void> saveActive(PaymentAttemptModel payment) async {
    await storage.write(key: _activeKey, value: jsonEncode(payment.toJson()));
  }

  Future<void> clearActive() => storage.delete(key: _activeKey);

  Future<PaymentAttemptModel> fetch(String paymentId, {int? orderId}) async {
    // ✅ Poll the order payment status endpoint (not the payment endpoint which doesn't exist)
    if (orderId != null) {
      final response = await api.get(
        'customer/orders/$orderId/payment-status/',
        noCache: true,
      );
      return PaymentAttemptModel.fromJson(
        Map<String, dynamic>.from(response.data),
      );
    }
    
    // Fallback to payment endpoint if orderId not provided
    final response = await api.get('payments/$paymentId/', noCache: true);
    return PaymentAttemptModel.fromJson(
      Map<String, dynamic>.from(response.data),
    );
  }
}
