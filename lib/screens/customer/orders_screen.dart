import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';
import '../../core/theme.dart';
import '../../providers/order_provider.dart';
import '../../providers/cart_provider.dart';
import '../../models/order_model.dart';
import '../../models/product_model.dart';

import '../../core/api_client.dart';
import 'payment_pending_screen.dart';

class OrdersScreen extends StatefulWidget {
  final bool isStandalone;
  const OrdersScreen({super.key, this.isStandalone = false});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  String _selectedFilter = 'All';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<OrderProvider>(context, listen: false).fetchOrders();
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final orderProvider = Provider.of<OrderProvider>(context);
    final orders = orderProvider.getFilteredOrders(_selectedFilter);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: AppTheme.primaryColor,
        elevation: 0,
        centerTitle: true,
        leading: widget.isStandalone ? IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ) : null,
        title: const Text(
          'My Orders',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 18)
        ),
        actions: [
          IconButton(
            onPressed: () => orderProvider.fetchOrders(),
            icon: const Icon(Icons.refresh, color: Colors.white)
          ),
        ],
      ),
      body: Column(
        children: [
          _buildFilters(),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => orderProvider.fetchOrders(),
              child: _buildBody(orderProvider, orders),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(OrderProvider provider, List<OrderModel> orders) {
    if (provider.isLoading && orders.isEmpty) {
      return _buildOrderSkeletons(context);
    }

    if (provider.error != null && orders.isEmpty) {
      return _buildErrorState(provider);
    }

    if (orders.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 120), // 🛡️ Bottom padding to avoid navbar obstruction
      physics: const BouncingScrollPhysics(),
      itemCount: orders.length,
      itemBuilder: (context, index) {
        return _buildOrderCard(orders[index]);
      },
    );
  }

  Widget _buildErrorState(OrderProvider provider) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppTheme.accentColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.wifi_off_rounded, size: 48, color: AppTheme.accentColor),
            ),
            const SizedBox(height: 32),
            Text(
              'Connection Issue',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: isDark ? Colors.white : AppTheme.primaryColor,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              provider.error!,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isDark ? Colors.white38 : Colors.grey.shade600,
                height: 1.5,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: 200,
              child: ElevatedButton(
                onPressed: () => provider.fetchOrders(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text('RETRY CONNECTION', style: TextStyle(fontWeight: FontWeight.w900)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withValues(alpha: 0.05),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.shopping_bag_outlined, 
                size: 64, 
                color: isDark ? Colors.white24 : Colors.grey.shade300
              ),
            ),
            const SizedBox(height: 32),
            Text(
              _selectedFilter == 'All' ? 'No orders yet' : 'No $_selectedFilter orders',
              style: TextStyle(
                fontSize: 20, 
                fontWeight: FontWeight.w900, 
                color: isDark ? Colors.white : AppTheme.primaryColor
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Your future refreshments will appear here once you place an order.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isDark ? Colors.white38 : Colors.grey.shade500, 
                height: 1.5,
                fontWeight: FontWeight.w600
              ),
            ),
            const SizedBox(height: 32),
            if (_selectedFilter == 'All')
              SizedBox(
                width: 200,
                child: ElevatedButton(
                  onPressed: () {
                    // 🔄 REPAIR: Pop back to the Shell which defaults to the first route.
                    // If we are already on the shell, we need to trigger the tab change.
                    if (widget.isStandalone) {
                      Navigator.of(context).pop();
                    } else {
                      // Navigate to the start of the app (Home Tab)
                      Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text('START SHOPPING', style: TextStyle(fontWeight: FontWeight.w900)),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilters() {
    final filters = ['All', 'Pending', 'Assigned', 'Picked_up', 'Delivered', 'Cancelled'];

    return Container(
      color: AppTheme.primaryColor,
      height: 64,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        physics: const BouncingScrollPhysics(),
        itemCount: filters.length,
        itemBuilder: (context, index) {
          final f = filters[index];
          final isSelected = _selectedFilter == f;
          
          return GestureDetector(
            onTap: () => setState(() => _selectedFilter = f),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(right: 6),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
              decoration: BoxDecoration(
                // 🟠 Selected: Bright Orange | Inactive: Matches Dark Surface for consistency
                color: isSelected 
                    ? AppTheme.accentColor 
                    : Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(100),
              ),
              child: Center(
                child: Text(
                  f.replaceAll('_', ' ').toUpperCase(),
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.white.withValues(alpha: 0.5),
                    fontWeight: isSelected ? FontWeight.w900 : FontWeight.w700,
                    fontSize: 10,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildOrderCard(OrderModel order) {
    final isPaymentPending = order.status.toLowerCase() == 'payment_pending';
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Theme.of(context).cardColor : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: isDark ? [] : [
          BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 15, offset: const Offset(0, 6))
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white.withValues(alpha: 0.05) : AppTheme.primaryColor.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.liquor_rounded, color: isDark ? Colors.white : AppTheme.primaryColor, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('#${order.orderNumber}', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: isDark ? Colors.white : AppTheme.primaryColor)),
                    const SizedBox(height: 1),
                    Text(
                      order.addressString ?? 'Delivery Order',
                      style: TextStyle(color: isDark ? Colors.white38 : Colors.grey.shade500, fontSize: 11, fontWeight: FontWeight.bold),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _buildStatusBadge(order.status),
                  const SizedBox(height: 4),
                  _buildPaymentBadge(order.paymentStatus, order.paymentMethod),
                ],
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Divider(height: 1, color: isDark ? Colors.white10 : Colors.grey.shade100),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    DateFormat('MMM dd, yyyy • hh:mm a').format(order.createdAt),
                    style: TextStyle(color: isDark ? Colors.white38 : Colors.grey.shade500, fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Icon(
                        order.isShiriki ? Icons.people_alt_rounded : Icons.shopping_bag_outlined, 
                        size: 12, 
                        color: order.isShiriki ? AppTheme.accentColor : (isDark ? Colors.white24 : Colors.grey.shade400)
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${order.isShiriki ? "SHIRIKI • " : ""}${order.itemCount} items', 
                        style: TextStyle(
                          color: order.isShiriki ? AppTheme.accentColor : (isDark ? Colors.white38 : Colors.grey.shade500), 
                          fontSize: 11, 
                          fontWeight: FontWeight.bold
                        )
                      ),
                    ],
                  ),
                ],
              ),
              Text(
                'KSh ${order.total.toStringAsFixed(0)}',
                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: isDark ? Colors.white : AppTheme.primaryColor)
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              if (isPaymentPending)
                Expanded(
                  child: SizedBox(
                    height: 42,
                    child: ElevatedButton(
                      onPressed: () => _retryPayment(order),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.accentColor,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                      child: const Text('RETRY PAYMENT', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12, letterSpacing: 0.5, color: Colors.white)),
                    ),
                  ),
                )
              else if (['pending', 'confirmed', 'assigned', 'picked_up', 'arrived'].contains(order.status.toLowerCase()))
                Expanded(
                  child: SizedBox(
                    height: 42,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pushNamed(context, '/order-tracking', arguments: order.id);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                      child: const Text('TRACK ORDER', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12, letterSpacing: 0.5)),
                    ),
                  ),
                )
              else
                Expanded(
                  child: SizedBox(
                    height: 42,
                    child: ElevatedButton(
                      onPressed: () => _reorder(order),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                      child: const Text('REORDER', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12, letterSpacing: 0.5)),
                    ),
                  ),
                ),
              if (order.status.toLowerCase() == 'delivered') ...[
                const SizedBox(width: 12),
                SizedBox(
                  height: 42,
                  child: OutlinedButton(
                    onPressed: () => Navigator.pushNamed(context, '/rate-order', arguments: order.id),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppTheme.primaryColor, width: 1.5),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Icon(Icons.star_outline_rounded, color: AppTheme.primaryColor, size: 20),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _reorder(OrderModel order) async {
    final cart = Provider.of<CartProvider>(context, listen: false);
    
    if (cart.items.isNotEmpty) {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Clear Cart?', style: TextStyle(fontWeight: FontWeight.bold)),
          content: const Text('Reordering will clear your current cart. Continue?'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('CANCEL')),
            TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('CONTINUE')),
          ],
        ),
      );
      if (confirm != true) return;
    }

    // Convert Order items to Cart items
    final newItems = order.items.map((it) => CartItem(
      product: ProductModel(
        id: it.productId,
        name: it.productName,
        price: it.priceAtOrder,
        image: it.productImage,
        storeId: it.storeId,
      ),
      quantity: it.quantity,
    )).toList();

    cart.reorder(
      newItems,
      storeName: order.storeName,
      deliveryFee: order.deliveryFee,
      storeLat: order.storeLatitude,
      storeLng: order.storeLongitude,
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Items added to cart!'), backgroundColor: Colors.green)
      );
      Navigator.pushNamed(context, '/cart');
    }
  }

  Future<void> _retryPayment(OrderModel order) async {
    final apiClient = ApiClient();
    try {
      final response = await apiClient.post('customer/orders/retry-payment/', data: {
        'order_number': order.orderNumber,
      });

      if (response.statusCode == 200) {
        if (mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => PaymentPendingScreen(
                orderId: order.id,
                orderNumber: order.orderNumber,
                checkoutRequestId: response.data['checkout_request_id'],
              ),
            ),
          );
        }
      } else {
        throw Exception(response.data['message'] ?? 'Failed to initiate payment');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    switch (status.toLowerCase()) {
      case 'delivered': color = Colors.green; break;
      case 'pending': color = Colors.orange; break;
      case 'payment_pending': color = Colors.amber; break;
      case 'assigned': color = Colors.blue; break;
      case 'picked_up': color = Colors.purple; break;
      case 'cancelled': color = Colors.red; break;
      default: color = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        status.replaceAll('_', ' ').toUpperCase(),
        style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 0.5),
      ),
    );
  }

  Widget _buildPaymentBadge(String paymentStatus, String paymentMethod) {
    final normalizedStatus = paymentStatus.toLowerCase();
    final normalizedMethod = paymentMethod.toLowerCase();

    Color color;
    String label;

    if (normalizedStatus == 'paid') {
      color = Colors.green;
      label = normalizedMethod == 'mpesa' ? 'PAID VIA M-PESA' : 'PAID';
    } else if (normalizedStatus == 'failed') {
      color = Colors.red;
      label = 'PAYMENT FAILED';
    } else if (normalizedMethod == 'cod') {
      color = Colors.orange;
      label = 'CASH ON DELIVERY';
    } else {
      color = Colors.amber;
      label = 'PAYMENT PENDING';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 0.5),
      ),
    );
  }

  Widget _buildOrderSkeletons(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 120),
      physics: const NeverScrollableScrollPhysics(),
      itemCount: 4,
      itemBuilder: (_, __) => Shimmer.fromColors(
        baseColor: isDark ? AppTheme.darkShimmerBase : AppTheme.shimmerBase,
        highlightColor: isDark ? AppTheme.darkShimmerHighlight : AppTheme.shimmerHighlight,
        child: Container(
          height: 220,
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
        ),
      ),
    );
  }
}
