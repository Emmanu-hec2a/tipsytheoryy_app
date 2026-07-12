import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';
import '../../core/theme.dart';
import '../../providers/order_provider.dart';
import '../../models/order_model.dart';

import '../../core/api_client.dart';
import 'payment_pending_screen.dart';

class OrdersScreen extends StatefulWidget {
  final bool isStandalone;
  const OrdersScreen({super.key, this.isStandalone = false});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
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
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(provider.error!, style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () => provider.fetchOrders(),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (orders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.shopping_bag_outlined, size: 80, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text('No orders found in $_selectedFilter', style: TextStyle(color: Colors.grey.shade500, fontSize: 16, fontWeight: FontWeight.w600)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      physics: const BouncingScrollPhysics(),
      itemCount: orders.length,
      itemBuilder: (context, index) {
        return _buildOrderCard(orders[index]);
      },
    );
  }

  Widget _buildFilters() {
    final filters = ['All', 'Pending', 'Assigned', 'Picked_up', 'Delivered', 'Cancelled'];
    return Container(
      color: AppTheme.primaryColor,
      height: 60,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        physics: const BouncingScrollPhysics(),
        child: Row(
          children: filters.map((f) => Container(
            margin: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => setState(() => _selectedFilter = f),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: _selectedFilter == f ? AppTheme.accentColor : Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Text(
                  f.replaceAll('_', ' ').toUpperCase(),
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 11,
                    letterSpacing: 0.5
                  ),
                ),
              ),
            ),
          )).toList(),
        ),
      ),
    );
  }

  Widget _buildOrderCard(OrderModel order) {
    final isPaymentPending = order.status.toLowerCase() == 'payment_pending';
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? Theme.of(context).cardColor : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: isDark ? Border.all(color: Colors.white10) : null,
        boxShadow: isDark ? [] : [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 20, offset: const Offset(0, 8))
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white.withValues(alpha: 0.05) : AppTheme.primaryColor.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(Icons.liquor_rounded, color: isDark ? Colors.white : AppTheme.primaryColor, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('#${order.orderNumber}', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: isDark ? Colors.white : AppTheme.primaryColor)),
                    const SizedBox(height: 2),
                    Text(
                      order.addressString ?? 'Delivery Order',
                      style: TextStyle(color: isDark ? Colors.white38 : Colors.grey.shade500, fontSize: 12, fontWeight: FontWeight.bold),
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
                  const SizedBox(height: 6),
                  _buildPaymentBadge(order.paymentStatus, order.paymentMethod),
                ],
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
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
                    style: TextStyle(color: isDark ? Colors.white38 : Colors.grey.shade500, fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.shopping_bag_outlined, size: 14, color: isDark ? Colors.white24 : Colors.grey.shade400),
                      const SizedBox(width: 4),
                      Text('${order.itemCount} items', style: TextStyle(color: isDark ? Colors.white38 : Colors.grey.shade500, fontSize: 12, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ],
              ),
              Text(
                'KSh ${order.total.toStringAsFixed(0)}',
                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: isDark ? Colors.white : AppTheme.primaryColor)
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              if (isPaymentPending)
                Expanded(
                  child: SizedBox(
                    height: 48,
                    child: ElevatedButton(
                      onPressed: () => _retryPayment(order),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.accentColor,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                      child: const Text('RETRY PAYMENT', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 1, color: Colors.white)),
                    ),
                  ),
                )
              else
                Expanded(
                  child: SizedBox(
                    height: 48,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pushNamed(context, '/order-tracking', arguments: order.id);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                      child: const Text('TRACK ORDER', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 1)),
                    ),
                  ),
                ),
              if (order.status.toLowerCase() == 'delivered') ...[
                const SizedBox(width: 12),
                SizedBox(
                  height: 48,
                  child: OutlinedButton(
                    onPressed: () => Navigator.pushNamed(context, '/rate-order', arguments: order.id),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppTheme.primaryColor, width: 1.5),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Icon(Icons.star_outline_rounded, color: AppTheme.primaryColor),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _retryPayment(OrderModel order) async {
    final apiClient = ApiClient();
    try {
      final response = await apiClient.post('partner/payments/mpesa/initiate/', data: {
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
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
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
