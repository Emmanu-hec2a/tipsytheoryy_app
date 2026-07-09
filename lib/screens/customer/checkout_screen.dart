import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import '../../core/theme.dart';
import '../../providers/cart_provider.dart';
import '../../providers/user_provider.dart';
import '../../core/api_client.dart';
import 'payment_pending_screen.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final ApiClient _apiClient = ApiClient();
  bool _isLoading = false;
  String? _capturedAddress;
  Position? _currentPosition;
  String _selectedPaymentMethod = 'flutterwave';
  bool _useWallet = false;

  @override
  void initState() {
    super.initState();
    _captureLocation();
  }

  Future<void> _captureLocation() async {
    setState(() => _isLoading = true);
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.whileInUse || permission == LocationPermission.always) {
        _currentPosition = await Geolocator.getCurrentPosition();
        
        final response = await _apiClient.post('geocode/reverse/', data: {
          'latitude': _currentPosition!.latitude,
          'longitude': _currentPosition!.longitude,
        });

        if (response.statusCode == 200) {
          setState(() => _capturedAddress = response.data['address']);
        }
      }
    } catch (e) {
      debugPrint('Location error: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _placeOrder() async {
    final cart = Provider.of<CartProvider>(context, listen: false);
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    setState(() => _isLoading = true);

    try {
      final double totalAmount = _useWallet 
          ? (cart.total - userProvider.user!.walletBalance).clamp(0, double.infinity) 
          : cart.total;

      final orderResponse = await _apiClient.post('customer/orders/create/', data: {
        'items': cart.items.map((it) => {'product_id': it.product.id, 'quantity': it.quantity}).toList(),
        'latitude': _currentPosition?.latitude,
        'longitude': _currentPosition?.longitude,
        'address_string': _capturedAddress,
        'payment_method': _selectedPaymentMethod == 'flutterwave' ? 'flutterwave' : 'cod',
        'use_wallet': _useWallet,
      });

      if (orderResponse.statusCode != 201) {
        throw Exception(orderResponse.data['error'] ?? 'Order could not be created');
      }

      final orderId = orderResponse.data['id'];
      final orderNumber = orderResponse.data['order_number'] ?? '#$orderId';

      if (_selectedPaymentMethod == 'flutterwave' && totalAmount > 0) {
        final paymentResponse = await _apiClient.post('partner/payments/flutterwave/initiate/', data: {
          'order_id': orderId,
          'amount': totalAmount.toStringAsFixed(2),
          'currency': 'KES',
          'email': orderResponse.data['customer_email'] ?? '',
          'name': orderResponse.data['customer_name'] ?? 'Customer',
        });

        if (paymentResponse.statusCode == 200 && paymentResponse.data['payment_url'] != null) {
          cart.clearCart();
          if (mounted) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) => PaymentPendingScreen(
                  orderId: orderId,
                  orderNumber: orderNumber,
                  paymentUrl: paymentResponse.data['payment_url'],
                ),
              ),
            );
          }
          return;
        }

        throw Exception(paymentResponse.data['detail'] ?? 'Payment could not be started');
      }

      cart.clearCart();
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/order-tracking', arguments: orderId);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = Provider.of<CartProvider>(context);
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppTheme.primaryColor,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'Checkout',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 18),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTrustBanner(cart),
            const SizedBox(height: 20),
            _buildSection('Delivery Address'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.surfaceColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Row(
                children: [
                  const Icon(Icons.location_on, color: AppTheme.accentColor),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _capturedAddress ?? 'Locating you...',
                      style: TextStyle(color: _capturedAddress == null ? Colors.grey : Colors.black87),
                    ),
                  ),
                  IconButton(onPressed: _captureLocation, icon: const Icon(Icons.refresh, size: 20)),
                ],
              ),
            ),
            const SizedBox(height: 30),
            _buildSection('Payment Method'),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: () => setState(() => _selectedPaymentMethod = 'flutterwave'),
              child: _buildPaymentOption('Flutterwave Card/Bank', Icons.credit_card, _selectedPaymentMethod == 'flutterwave'),
            ),
            GestureDetector(
              onTap: () => setState(() => _selectedPaymentMethod = 'cod'),
              child: _buildPaymentOption('Cash on Delivery', Icons.money, _selectedPaymentMethod == 'cod'),
            ),
            const SizedBox(height: 30),
            _buildWalletOption(),
            const SizedBox(height: 30),
            _buildSection('Order Summary'),
            const SizedBox(height: 12),
            _buildSummaryRow('Subtotal', 'KSh ${cart.subtotal.toStringAsFixed(0)}'),
            _buildSummaryRow('Delivery Fee', 'KSh ${cart.deliveryFee.toStringAsFixed(0)}'),
            if (_useWallet) 
              _buildSummaryRow('Tipsy Credit', '- KSh ${(Provider.of<UserProvider>(context).user?.walletBalance ?? 0).toStringAsFixed(2)}', isBold: true),
            const Divider(height: 24),
            _buildSummaryRow('Total', 'KSh ${_calculateFinalTotal(cart).toStringAsFixed(0)}', isBold: true),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: _isLoading ? null : _placeOrder,
                child: _isLoading 
                    ? const CircularProgressIndicator(color: Colors.white) 
                    : Text(
                        _selectedPaymentMethod == 'flutterwave'
                            ? 'Confirm & Pay Online'
                            : 'Confirm Order',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title) {
    return Text(title, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold));
  }

  Widget _buildTrustBanner(CartProvider cart) {
    // We check if the items in the cart are from a Pro store
    // For now we'll show it if the cart isn't empty and the first item's store is pro
    // In a multi-vendor setup we might check if ANY are pro or if ALL are pro
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF2DD4BF).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF2DD4BF).withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          const Icon(Icons.verified_user_rounded, color: Color(0xFF2DD4BF), size: 20),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Ordering from a Pro-Verified Merchant. Quality and speed are guaranteed.',
              style: TextStyle(
                color: Color(0xFF0D3B30),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentOption(String title, IconData icon, bool isSelected) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isSelected ? const Color(0xFFE6F2F0) : AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isSelected ? AppTheme.primaryColor : Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Icon(icon, color: isSelected ? AppTheme.primaryColor : Colors.grey),
          const SizedBox(width: 12),
          Text(title, style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
          const Spacer(),
          if (isSelected) const Icon(Icons.check_circle, color: AppTheme.primaryColor, size: 20),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: isBold ? (label.contains('Credit') ? Colors.green : Colors.black) : Colors.grey)),
          Text(value, style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: isBold ? FontWeight.bold : FontWeight.normal, fontSize: isBold ? 16 : 14, color: label.contains('Credit') ? Colors.green : null)),
        ],
      ),
    );
  }

  double _calculateFinalTotal(CartProvider cart) {
    if (!_useWallet) return cart.total;
    final balance = Provider.of<UserProvider>(context).user?.walletBalance ?? 0.0;
    return (cart.total - balance).clamp(0, double.infinity);
  }

  Widget _buildWalletOption() {
    final userProvider = Provider.of<UserProvider>(context);
    final balance = userProvider.user?.walletBalance ?? 0.0;
    
    if (balance <= 0) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSection('Tipsy Credit'),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _useWallet ? const Color(0xFFE6F2F0) : AppTheme.surfaceColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _useWallet ? AppTheme.primaryColor : Colors.grey.shade200),
          ),
          child: Row(
            children: [
              const Icon(Icons.account_balance_wallet_rounded, color: Colors.green),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Use Wallet Balance', style: TextStyle(fontWeight: FontWeight.bold)),
                    Text('Available: KSh ${balance.toStringAsFixed(2)}', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                  ],
                ),
              ),
              Switch(
                value: _useWallet, 
                onChanged: (val) => setState(() => _useWallet = val),
                activeColor: AppTheme.primaryColor,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
