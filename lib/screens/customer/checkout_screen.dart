import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import '../../core/theme.dart';
import '../../providers/cart_provider.dart';
import '../../providers/user_provider.dart';
import '../../providers/promotion_provider.dart';
import '../../core/api_client.dart';
import 'payment_pending_screen.dart';
import 'age_verification_screen.dart';

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
  String _selectedPaymentMethod = 'mpesa';
  bool _useWallet = false;
  final TextEditingController _mpesaPhoneController = TextEditingController();
  final TextEditingController _promoController = TextEditingController();
  bool _isValidatingPromo = false;

  @override
  void initState() {
    super.initState();
    _loadCachedLocation();
    _prefillMpesaPhone();
    _fetchAvailablePromos();
  }

  void _fetchAvailablePromos() {
    final cart = Provider.of<CartProvider>(context, listen: false);
    if (cart.activeStoreId != null) {
      Provider.of<PromotionProvider>(context, listen: false).fetchPromotions(cart.activeStoreId!);
    }
  }

  void _prefillMpesaPhone() {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    if (userProvider.user?.phone != null) {
      _mpesaPhoneController.text = userProvider.user!.phone!;
    }
  }

  void _loadCachedLocation() {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    if (userProvider.cachedAddress != null) {
      setState(() {
        _capturedAddress = userProvider.cachedAddress;
        if (userProvider.cachedLat != null && userProvider.cachedLng != null) {
          _currentPosition = Position(
            latitude: userProvider.cachedLat!,
            longitude: userProvider.cachedLng!,
            timestamp: DateTime.now(),
            accuracy: 0,
            altitude: 0,
            heading: 0,
            speed: 0,
            speedAccuracy: 0,
            altitudeAccuracy: 0,
            headingAccuracy: 0,
          );
        }
      });
    } else {
      _captureLocation();
    }
  }

  Future<void> _captureLocation() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
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
          final address = response.data['address'];
          setState(() => _capturedAddress = address);
          // Cache it in the provider
          userProvider.cacheLocation(
            address, 
            _currentPosition!.latitude, 
            _currentPosition!.longitude
          );
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
        'payment_method': _selectedPaymentMethod,
        'mpesa_phone': _selectedPaymentMethod == 'mpesa' ? _mpesaPhoneController.text.trim() : null,
        'use_wallet': _useWallet,
        'promo_code': cart.appliedPromoCode,
        'total': cart.total, // Pass total for risk calculation
      });

      if (orderResponse.statusCode == 403 && orderResponse.data['error'] == 'age_verification_required') {
        setState(() => _isLoading = false);
        if (mounted) {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (context) => Container(
              height: MediaQuery.of(context).size.height * 0.85,
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
              ),
              child: AgeVerificationScreen(
                onVerified: () {
                  Navigator.pop(context); // Close sheet
                  _placeOrder(); // Retry order
                },
              ),
            ),
          );
        }
        return;
      }

      if (orderResponse.statusCode != 201) {
        throw Exception(orderResponse.data['error'] ?? 'Order could not be created');
      }

      final orderId = orderResponse.data['id'];
      final orderNumber = orderResponse.data['order_number'] ?? '#$orderId';

      if (_selectedPaymentMethod == 'mpesa' && totalAmount > 0) {
        final checkoutRequestId = orderResponse.data['checkout_request_id'];
        final mpesaError = orderResponse.data['mpesa_error'];

        if (checkoutRequestId == null) {
          // 🚨 STK Push failed on backend
          throw Exception(mpesaError ?? 'M-Pesa STK Push could not be initiated. Please check your number or try again.');
        }
        
        // ✨ SMOOTH TRANSITION: Navigate first, THEN clear cart
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => PaymentPendingScreen(
                orderId: orderId,
                orderNumber: orderNumber,
                checkoutRequestId: checkoutRequestId,
              ),
            ),
          );
          
          // Clear cart in background after navigation starts
          Future.delayed(const Duration(milliseconds: 500), () {
            cart.clearCart();
          });
        }
        return;
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
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
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: isDark ? Colors.white10 : Colors.grey.shade200),
              ),
              child: Row(
                children: [
                  const Icon(Icons.location_on, color: AppTheme.accentColor),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _capturedAddress ?? 'Locating you...',
                      style: TextStyle(color: _capturedAddress == null ? (isDark ? Colors.white24 : Colors.grey) : (isDark ? Colors.white70 : Colors.black87)),
                    ),
                  ),
                  IconButton(onPressed: _captureLocation, icon: Icon(Icons.refresh, size: 20, color: isDark ? Colors.white38 : Colors.grey)),
                ],
              ),
            ),
            const SizedBox(height: 30),
            _buildSection('Payment Method'),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: () => setState(() => _selectedPaymentMethod = 'mpesa'),
              child: _buildPaymentOption('M-Pesa STK Push', Icons.phone_android_rounded, _selectedPaymentMethod == 'mpesa'),
            ),
            if (_selectedPaymentMethod == 'mpesa')
              Padding(
                padding: const EdgeInsets.only(top: 8, bottom: 16),
                child: TextField(
                  controller: _mpesaPhoneController,
                  keyboardType: TextInputType.phone,
                  style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontWeight: FontWeight.bold),
                  decoration: InputDecoration(
                    labelText: 'M-Pesa Number for STK Push',
                    labelStyle: TextStyle(color: AppTheme.primaryColor),
                    hintText: 'e.g. 0712345678',
                    prefixIcon: const Icon(Icons.phone, color: AppTheme.primaryColor),
                    filled: true,
                    fillColor: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade50,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  ),
                ),
              ),
            GestureDetector(
              onTap: () => setState(() => _selectedPaymentMethod = 'cod'),
              child: _buildPaymentOption('Cash on Delivery', Icons.money, _selectedPaymentMethod == 'cod'),
            ),
            const SizedBox(height: 30),
            _buildWalletOption(),
            const SizedBox(height: 30),
            _buildPromotionSection(),
            const SizedBox(height: 30),
            _buildSection('Order Summary'),
            const SizedBox(height: 12),
            _buildSummaryRow('Subtotal', 'KSh ${cart.subtotal.toStringAsFixed(0)}'),
            _buildSummaryRow('Delivery Fee', 'KSh ${cart.deliveryFee.toStringAsFixed(0)}'),
            if (cart.appliedPromoCode != null)
              _buildSummaryRow('Promo (${cart.appliedPromoCode})', '- KSh ${cart.discountAmount.toStringAsFixed(0)}', isBold: true),
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
                        _selectedPaymentMethod == 'mpesa'
                            ? 'Pay via M-PESA'
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF2DD4BF).withValues(alpha: isDark ? 0.05 : 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF2DD4BF).withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          const Icon(Icons.verified_user_rounded, color: Color(0xFF2DD4BF), size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Ordering from a Pro-Verified Merchant. Quality and speed are guaranteed.',
              style: TextStyle(
                color: isDark ? const Color(0xFF2DD4BF).withValues(alpha: 0.8) : const Color(0xFF0D3B30),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isSelected ? (isDark ? AppTheme.primaryColor : const Color(0xFFE6F2F0)) : Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isSelected ? AppTheme.primaryColor : (isDark ? Colors.white10 : Colors.grey.shade200)),
      ),
      child: Row(
        children: [
          Icon(icon, color: isSelected ? Colors.white : (isDark ? Colors.white38 : Colors.grey)),
          const SizedBox(width: 12),
          Text(
            title, 
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              color: isSelected ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
            )
          ),
          const Spacer(),
          if (isSelected) const Icon(Icons.check_circle, color: Colors.white, size: 20),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, {bool isBold = false}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: isBold ? (isDark ? Colors.white : Colors.black) : (isDark ? Colors.white38 : Colors.grey))),
          Text(value, style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: isBold ? FontWeight.bold : FontWeight.normal, fontSize: isBold ? 16 : 14, color: label.contains('Credit') ? Colors.green : (isDark ? Colors.white : null))),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    if (balance <= 0) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSection('Tipsy Credit'),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _useWallet ? (isDark ? AppTheme.primaryColor : const Color(0xFFE6F2F0)) : Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _useWallet ? AppTheme.primaryColor : (isDark ? Colors.white10 : Colors.grey.shade200)),
          ),
          child: Row(
            children: [
              const Icon(Icons.account_balance_wallet_rounded, color: Colors.green),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Use Wallet Balance', style: TextStyle(fontWeight: FontWeight.bold, color: _useWallet && isDark ? Colors.white : (isDark ? Colors.white : Colors.black))),
                    Text('Available: KSh ${balance.toStringAsFixed(2)}', style: TextStyle(color: isDark ? Colors.white38 : Colors.grey.shade600, fontSize: 12)),
                  ],
                ),
              ),
              Switch(
                value: _useWallet, 
                onChanged: (val) => setState(() => _useWallet = val),
                activeColor: Colors.white,
                activeTrackColor: Colors.green,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPromotionSection() {
    final promoProvider = Provider.of<PromotionProvider>(context);
    final cart = Provider.of<CartProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSection('Promotions & Offers'),
        const SizedBox(height: 12),
        
        // 🎫 Promo Input
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: cart.appliedPromoCode != null ? Colors.green : (isDark ? Colors.white10 : Colors.grey.shade200)),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _promoController,
                      enabled: cart.appliedPromoCode == null,
                      style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontWeight: FontWeight.bold, fontSize: 14),
                      decoration: InputDecoration(
                        hintText: 'Enter Promo Code',
                        hintStyle: TextStyle(color: isDark ? Colors.white24 : Colors.grey),
                        border: InputBorder.none,
                        prefixIcon: const Icon(Icons.local_offer_outlined, color: AppTheme.primaryColor),
                      ),
                    ),
                  ),
                  if (cart.appliedPromoCode == null)
                    _isValidatingPromo 
                      ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.accentColor))
                      : TextButton(
                          onPressed: _applyPromoCode,
                          child: const Text('APPLY', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.accentColor)),
                        )
                  else
                    IconButton(
                      icon: const Icon(Icons.cancel, color: Colors.red),
                      onPressed: () {
                        cart.removePromo();
                        _promoController.clear();
                      },
                    ),
                ],
              ),
              if (cart.appliedPromoCode != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8, left: 12),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle, color: Colors.green, size: 14),
                      const SizedBox(width: 8),
                      Text(
                        'Promo Applied: KSh ${cart.discountAmount.toStringAsFixed(0)} saved!',
                        style: const TextStyle(color: Colors.green, fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),

        // 🛍️ Available Offers List
        if (promoProvider.availablePromotions.isNotEmpty) ...[
          const SizedBox(height: 16),
          SizedBox(
            height: 85,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: promoProvider.availablePromotions.length,
              itemBuilder: (context, index) {
                final promo = promoProvider.availablePromotions[index];
                final bool isEligible = cart.subtotal >= promo.minOrderAmount;
                
                return GestureDetector(
                  onTap: (cart.appliedPromoCode == null && isEligible) ? () {
                    _promoController.text = promo.code;
                    _applyPromoCode();
                  } : null,
                  child: Container(
                    width: 180,
                    margin: const EdgeInsets.only(right: 12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isEligible 
                        ? AppTheme.accentColor.withValues(alpha: isDark ? 0.15 : 0.05)
                        : (isDark ? Colors.white.withValues(alpha: 0.02) : Colors.grey.shade100),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isEligible 
                          ? AppTheme.accentColor.withValues(alpha: 0.3)
                          : (isDark ? Colors.white10 : Colors.grey.shade200)
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Row(
                          children: [
                            Expanded(
                                child: Text(
                                    promo.title, 
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold, 
                                        fontSize: 11, 
                                        color: isEligible 
                                            ? (isDark ? Colors.white : Colors.black87)
                                            : (isDark ? Colors.white24 : Colors.grey)
                                    ), 
                                    maxLines: 1, 
                                    overflow: TextOverflow.ellipsis
                                )
                            ),
                            if (!isEligible)
                                const Icon(Icons.lock_outline, size: 10, color: Colors.grey),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                            promo.discountPercentage != null 
                                ? '${promo.discountPercentage?.toStringAsFixed(0)}% OFF'
                                : 'KSh ${promo.discountAmount?.toStringAsFixed(0)} OFF',
                            style: TextStyle(
                                color: isEligible ? AppTheme.accentColor : Colors.grey, 
                                fontWeight: FontWeight.w900, 
                                fontSize: 13
                            )
                        ),
                        const SizedBox(height: 2),
                        Text(
                            isEligible ? 'Use code: ${promo.code}' : 'Min. KSh ${promo.minOrderAmount.toStringAsFixed(0)}',
                            style: TextStyle(
                                color: isEligible ? AppTheme.accentColor.withValues(alpha: 0.8) : Colors.redAccent,
                                fontSize: 9, 
                                fontWeight: FontWeight.bold
                            )
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ],
    );
  }

  Future<void> _applyPromoCode() async {
    final code = _promoController.text.trim();
    if (code.isEmpty) return;

    final cart = Provider.of<CartProvider>(context, listen: false);
    final promoProvider = Provider.of<PromotionProvider>(context, listen: false);

    setState(() => _isValidatingPromo = true);

    final result = await promoProvider.validatePromo(code, cart.activeStoreId!, cart.subtotal);

    setState(() => _isValidatingPromo = false);

    if (result['success']) {
      cart.applyPromo(code, result['discount_amount']);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Promo applied! You saved KSh ${result['discount_amount'].toStringAsFixed(0)}'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['error']),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
