import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme.dart';
import '../../providers/rider_provider.dart';
import '../../models/order_model.dart';

class DeliveryDetailsScreen extends StatelessWidget {
  final int orderId;
  const DeliveryDetailsScreen({super.key, required this.orderId});

  @override
  Widget build(BuildContext context) {
    final riderProvider = Provider.of<RiderProvider>(context);
    final order = riderProvider.orderQueue.firstWhere((o) => o.id == orderId, orElse: () => throw Exception('Order not found'));
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: AppTheme.primaryColor,
        elevation: 0,
        centerTitle: true,
        title: Text('Task #${order.orderNumber}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 18)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildStatusHeader(order.status),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('ROUTE DETAILS', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: isDark ? Colors.white38 : Colors.grey, letterSpacing: 1.2)),
                  const SizedBox(height: 16),
                  _buildAddressCard(context, Icons.storefront_rounded, 'Pickup Point', 'Merchant Shop Location', isPickup: true),
                  _buildRouteConnector(context),
                  _buildAddressCard(context, Icons.location_on_rounded, 'Drop-off Point', order.addressString ?? 'Customer Address'),
                  
                  const SizedBox(height: 32),
                  Text('ORDER SUMMARY', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: isDark ? Colors.white38 : Colors.grey, letterSpacing: 1.2)),
                  const SizedBox(height: 16),
                  _buildSummaryCard(context, order),
                  
                  const SizedBox(height: 40),
                  
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton.icon(
                      onPressed: () => _launchNavigation(order),
                      icon: const Icon(Icons.navigation_rounded, color: Colors.white),
                      label: const Text('NAVIGATE TO CUSTOMER', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.accentColor,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  if (order.status.toLowerCase() != 'delivered')
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: OutlinedButton(
                      onPressed: () async {
                        final nextStatus = _getNextStatusValue(order.status);
                        if (nextStatus != null) {
                          final success = await riderProvider.updateOrderStatus(order.id, nextStatus);
                          if (success && context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Status updated to ${nextStatus.replaceAll('_', ' ')}'), backgroundColor: Colors.green),
                            );
                          }
                        }
                      },
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: isDark ? AppTheme.accentColor : AppTheme.primaryColor, width: 2),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: Text(
                        _getNextStatusAction(order.status),
                        style: TextStyle(color: isDark ? AppTheme.accentColor : AppTheme.primaryColor, fontWeight: FontWeight.w900, letterSpacing: 1),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusHeader(String status) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 20),
      decoration: const BoxDecoration(
        color: AppTheme.primaryColor,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(30)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20)),
            child: Text(
              status.toUpperCase(),
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 12, letterSpacing: 1),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddressCard(BuildContext context, IconData icon, String label, String address, {bool isPickup = false}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? Theme.of(context).cardColor : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDark ? Colors.white10 : Colors.grey.shade100),
      ),
      child: Row(
        children: [
          Icon(icon, color: isPickup ? AppTheme.primaryColor : AppTheme.accentColor, size: 28),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: isDark ? Colors.white38 : Colors.grey)),
                const SizedBox(height: 4),
                Text(address, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: isDark ? Colors.white70 : const Color(0xFF1E293B))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRouteConnector(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(left: 33),
      height: 20,
      child: CustomPaint(painter: _DashedLinePainter(color: isDark ? Colors.white10 : Colors.grey.shade300)),
    );
  }

  Widget _buildSummaryCard(BuildContext context, OrderModel order) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? Theme.of(context).cardColor : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: isDark ? Colors.white10 : Colors.grey.shade100),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildSummaryItem(context, 'EST. EARNING', 'KSh ${order.deliveryFee.toStringAsFixed(0)}'),
          _buildSummaryItem(context, 'TOTAL VALUE', 'KSh ${order.total.toStringAsFixed(0)}'),
          _buildSummaryItem(context, 'ITEMS', '${order.itemCount} Units'),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(BuildContext context, String label, String value) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      children: [
        Text(label, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: isDark ? Colors.white24 : Colors.grey, letterSpacing: 0.5)),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: isDark ? Colors.white : AppTheme.primaryColor)),
      ],
    );
  }

  String _getNextStatusAction(String status) {
    switch (status.toLowerCase()) {
      case 'assigned': return 'MARK AS PICKED UP';
      case 'picked_up': return 'MARK AS ARRIVED';
      case 'arrived': return 'MARK AS DELIVERED';
      default: return 'TASK COMPLETED';
    }
  }

  String? _getNextStatusValue(String status) {
    switch (status.toLowerCase()) {
      case 'assigned': return 'picked_up';
      case 'picked_up': return 'arrived';
      case 'arrived': return 'delivered';
      default: return null;
    }
  }

  Future<void> _launchNavigation(OrderModel order) async {
    final String query = Uri.encodeComponent(order.addressString ?? '');
    final String googleMapsUrl = "https://www.google.com/maps/dir/?api=1&destination=$query&travelmode=driving";
    
    final Uri uri = Uri.parse(googleMapsUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}

class _DashedLinePainter extends CustomPainter {
  final Color color;
  _DashedLinePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    var paint = Paint()..color = color..strokeWidth = 2;
    var max = size.height;
    var dashWidth = 4;
    var dashSpace = 4;
    double startY = 0;
    while (startY < max) {
      canvas.drawLine(Offset(0, startY), Offset(0, startY + dashWidth), paint);
      startY += dashWidth + dashSpace;
    }
  }
  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
