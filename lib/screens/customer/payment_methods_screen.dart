import 'package:flutter/material.dart';
import '../../core/theme.dart';

class PaymentMethodsScreen extends StatelessWidget {
  const PaymentMethodsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: AppTheme.primaryColor,
        title: const Text('Payment Methods', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('PRIMARY METHOD', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Colors.grey, letterSpacing: 1.2)),
            const SizedBox(height: 16),
            _buildPaymentCard(context, 'M-Pesa', 'STK Push enabled', Icons.phone_android, isEnabled: true),
            const SizedBox(height: 24),
            const Text('OTHER METHODS', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Colors.grey, letterSpacing: 1.2)),
            const SizedBox(height: 16),
            _buildPaymentCard(context, 'Cash on Delivery', 'Pay at your doorstep', Icons.money, isEnabled: false),
            _buildPaymentCard(context, 'Credit Card', 'Coming soon', Icons.credit_card, isEnabled: false),
            const Spacer(),
            const Center(
              child: Text(
                'M-Pesa is our preferred premium payment partner.',
                style: TextStyle(color: Colors.grey, fontSize: 12, fontStyle: FontStyle.italic),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentCard(BuildContext context, String title, String subtitle, IconData icon, {required bool isEnabled}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? Theme.of(context).cardColor : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: isEnabled ? Border.all(color: Colors.green.shade200) : (isDark ? Border.all(color: Colors.white10) : null),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: AppTheme.primaryColor.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: AppTheme.primaryColor),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: isDark ? Colors.white : Colors.black87)),
                Text(subtitle, style: TextStyle(color: isDark ? Colors.white38 : Colors.grey.shade500, fontSize: 12, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          if (isEnabled)
            const Icon(Icons.check_circle, color: Colors.green)
          else
            Icon(Icons.lock_outline, color: isDark ? Colors.white24 : Colors.grey, size: 18),
        ],
      ),
    );
  }
}
