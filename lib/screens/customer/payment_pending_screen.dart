import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/api_client.dart';
import '../../core/theme.dart';
import '../../models/order_model.dart';
import 'order_tracking_screen.dart';
import 'payment_result_screen.dart';

class PaymentPendingScreen extends StatefulWidget {
  final int orderId;
  final String orderNumber;
  final String? checkoutRequestId;

  const PaymentPendingScreen({
    super.key,
    required this.orderId,
    required this.orderNumber,
    this.checkoutRequestId,
  });

  @override
  State<PaymentPendingScreen> createState() => _PaymentPendingScreenState();
}

class _PaymentPendingScreenState extends State<PaymentPendingScreen> with WidgetsBindingObserver {
  final ApiClient _apiClient = ApiClient();
  bool _isChecking = false;
  String _statusMessage = 'An M-Pesa STK push has been sent to your phone. Please enter your PIN to complete the payment.';
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _startPolling();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _pollTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkPaymentStatus();
    }
  }

  void _startPolling() {
    _checkPaymentStatus();
    _pollTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      _checkPaymentStatus();
    });
  }

  Future<void> _checkPaymentStatus() async {
    if (_isChecking || !mounted) return;

    setState(() => _isChecking = true);

    try {
      final response = await _apiClient.get('customer/orders/${widget.orderId}/');
      if (response.statusCode == 200) {
        final order = OrderModel.fromJson(response.data);
        if (order.paymentStatus == 'paid') {
          _pollTimer?.cancel();
          if (mounted) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => OrderTrackingScreen(orderId: widget.orderId)),
            );
          }
          return;
        }

        if (order.paymentStatus == 'failed') {
          _pollTimer?.cancel();
          if (mounted) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) => PaymentResultScreen(
                  isSuccess: false,
                  title: 'Payment failed',
                  message: 'Your payment could not be completed. Please ensure you have sufficient funds and try again.',
                  onRetry: () {
                    Navigator.pop(context);
                  },
                  onGoHome: () => Navigator.of(context).popUntil((route) => route.isFirst),
                ),
              ),
            );
          }
          return;
        }

        setState(() => _statusMessage = 'An M-Pesa STK push has been sent to your phone. Please enter your PIN to complete the payment.');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _statusMessage = 'We are still checking your payment status.');
      }
    } finally {
      if (mounted) {
        setState(() => _isChecking = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        title: const Text('Payment pending'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 12)],
              ),
              child: Column(
                children: [
                  const Icon(Icons.phone_android_rounded, size: 56, color: AppTheme.accentColor),
                  const SizedBox(height: 16),
                  Text(
                    'Order ${widget.orderNumber}',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _statusMessage,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.black87, fontSize: 14, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 24),
                  if (_isChecking)
                    const CircularProgressIndicator(color: AppTheme.primaryColor)
                  else
                    const Text(
                      'Checking status...',
                      style: TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _isChecking ? null : _checkPaymentStatus,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('I HAVE PAID', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
              ),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
              child: const Text('Back to Home', style: TextStyle(color: Colors.grey)),
            ),
          ],
        ),
      ),
    );
  }
}
