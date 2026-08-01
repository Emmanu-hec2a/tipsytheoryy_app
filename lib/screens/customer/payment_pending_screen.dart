import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/api_client.dart';
import '../../core/theme.dart';
import '../../models/order_model.dart';
import 'order_tracking_screen.dart';
import 'payment_result_screen.dart';
import 'customer_shell.dart';
import '../../services/notification_service.dart';

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
  StreamSubscription? _fcmSubscription;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _startPolling();

    // 🛡️ Task: Listen for phone format errors or progress
    _fcmSubscription = NotificationService().onMessageReceived.listen((message) {
      final type = message.data['type'];
      if (type == 'phone_format_error') {
        _pollTimer?.cancel();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Invalid phone number. Please check the format and try again."),
              backgroundColor: Colors.red,
            ),
          );
          _showRetryDialog();
        }
      } else if (type == 'stk_initiated' || type == 'stk_confirmed') {
        _checkPaymentStatus();
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _pollTimer?.cancel();
    _fcmSubscription?.cancel();
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
      final response = await _apiClient.get('customer/orders/${widget.orderId}/payment-status/');
      if (response.statusCode == 200) {
        final paymentStatus = response.data['payment_status'];
        if (paymentStatus == 'paid') {
          _pollTimer?.cancel();
          if (mounted) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => OrderTrackingScreen(orderId: widget.orderId)),
            );
          }
          return;
        }

        if (paymentStatus == 'failed') {
          _pollTimer?.cancel();
          if (mounted) {
            final shouldRetry = await Navigator.of(context, rootNavigator: true).push<bool>(
              MaterialPageRoute(
                builder: (_) => PaymentResultScreen(
                  isSuccess: false,
                  title: 'Payment failed',
                  message: 'Your payment could not be completed. Please ensure you have sufficient funds and try again.',
                  onRetry: () => Navigator.pop(context, true),
                  onGoHome: () => Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const CustomerShell()),
                    (route) => false,
                  ),
                ),
              ),
            );

            if (shouldRetry == true && mounted) {
              _showRetryDialog();
            }
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

  void _showRetryDialog() {
    final TextEditingController phoneController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Retry Payment'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Verify your M-Pesa phone number to retry.'),
            const SizedBox(height: 16),
            TextField(
              controller: phoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'M-Pesa Phone Number',
                hintText: 'e.g. 0712345678',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              final phone = phoneController.text.trim();
              Navigator.pop(context);
              _performRealRetry(phone: phone.isNotEmpty ? phone : null);
            },
            child: const Text('Send STK Push'),
          ),
        ],
      ),
    );
  }

  Future<void> _performRealRetry({String? phone}) async {
    setState(() => _isChecking = true);
    try {
      final response = await _apiClient.post('customer/orders/retry-payment/', data: {
        'order_number': widget.orderNumber,
        if (phone != null) 'mpesa_phone': phone,
      });

      if (response.statusCode == 200) {
        if (mounted) {
          // Restart this screen with the new ID
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => PaymentPendingScreen(
                orderId: widget.orderId,
                orderNumber: widget.orderNumber,
                checkoutRequestId: response.data['checkout_request_id'],
              ),
            ),
          );
        }
      } else {
        throw Exception(response.data['error'] ?? 'Retry failed');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Retry failed: $e')));
      }
    } finally {
      if (mounted) setState(() => _isChecking = false);
    }
  }

  Future<void> _triggerManualStatusQuery() async {
    setState(() => _isChecking = true);
    try {
      final response = await _apiClient.post('customer/orders/${widget.orderId}/mpesa-query/');
      if (response.statusCode == 200) {
        if (response.data['status'] == 'paid') {
          _pollTimer?.cancel();
          if (mounted) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => OrderTrackingScreen(orderId: widget.orderId)),
            );
          }
          return;
        }
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(response.data['message'] ?? 'Status updated.'))
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not reach Safaricom. Please wait a moment.'))
        );
      }
    } finally {
      if (mounted) setState(() => _isChecking = false);
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
                onPressed: _isChecking ? null : _triggerManualStatusQuery,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.accentColor,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('STUCK? CHECK STATUS', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: OutlinedButton(
                onPressed: _isChecking ? null : _checkPaymentStatus,
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppTheme.primaryColor),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('REFRESH', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryColor)),
              ),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const CustomerShell()),
                (route) => false,
              ),
              child: const Text('Back to Home', style: TextStyle(color: Colors.grey)),
            ),
          ],
        ),
      ),
    );
  }
}
