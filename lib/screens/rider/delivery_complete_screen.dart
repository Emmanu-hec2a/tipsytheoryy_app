import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';
import '../../providers/rider_provider.dart';
import '../../models/order_model.dart';

class DeliveryCompleteScreen extends StatefulWidget {
  const DeliveryCompleteScreen({super.key});

  @override
  State<DeliveryCompleteScreen> createState() => _DeliveryCompleteScreenState();
}

class _DeliveryCompleteScreenState extends State<DeliveryCompleteScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<RiderProvider>(context, listen: false).fetchRiderData();
    });
  }

  @override
  Widget build(BuildContext context) {
    final riderProvider = Provider.of<RiderProvider>(context);
    final completedOrders = riderProvider.deliveryHistory;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: AppTheme.primaryColor,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Completed Tasks',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 18),
        ),
      ),
      body: Stack(
        children: [
          RefreshIndicator(
            onRefresh: () => riderProvider.fetchRiderData(),
            child: completedOrders.isEmpty
              ? _buildEmptyState(context)
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
                  physics: const BouncingScrollPhysics(),
                  itemCount: completedOrders.length,
                  itemBuilder: (context, index) {
                    return _buildCompletedCard(context, completedOrders[index]);
                  },
                ),
          ),
          Positioned(
            bottom: 30,
            left: 20,
            right: 20,
            child: SizedBox(
              height: 55,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 8,
                  shadowColor: AppTheme.primaryColor.withValues(alpha: 0.3),
                ),
                child: const Text(
                  'BACK TO HOME',
                  style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1, color: Colors.white),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.assignment_turned_in_rounded, size: 80, color: isDark ? Colors.white.withValues(alpha: 0.05) : AppTheme.primaryColor.withValues(alpha: 0.05)),
          const SizedBox(height: 20),
          Text('No completed tasks yet', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: isDark ? Colors.white70 : AppTheme.primaryColor)),
          const SizedBox(height: 8),
          Text('Complete your first delivery to see history.', style: TextStyle(color: isDark ? Colors.white38 : Colors.grey, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildCompletedCard(BuildContext context, OrderModel order) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? Theme.of(context).cardColor : Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: isDark ? [] : [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 15, offset: const Offset(0, 5))],
        border: isDark ? Border.all(color: Colors.white10) : null,
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('#${order.orderNumber}', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: AppTheme.primaryColor)),
              Text(
                DateFormat('MMM dd, hh:mm a').format(order.createdAt),
                style: TextStyle(color: isDark ? Colors.white24 : Colors.grey.shade400, fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Divider(height: 1, color: isDark ? Colors.white10 : Colors.grey.shade100),
          ),
          _buildInfoRow(context, Icons.location_on_rounded, 'Destination', order.addressString ?? 'Customer Location'),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('EARNED', style: TextStyle(color: isDark ? Colors.white24 : Colors.grey, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
                  Text('KSh ${order.deliveryFee.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: Colors.green)),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(color: Colors.green.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
                child: const Text('SUCCESSFUL', style: TextStyle(color: Colors.green, fontWeight: FontWeight.w900, fontSize: 10)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(BuildContext context, IconData icon, String label, String value) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      children: [
        Icon(icon, size: 16, color: isDark ? Colors.white10 : AppTheme.primaryColor.withValues(alpha: 0.4)),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(color: isDark ? Colors.white24 : Colors.grey.shade400, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
              Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: isDark ? Colors.white70 : const Color(0xFF1E293B)), maxLines: 1, overflow: TextOverflow.ellipsis),
            ],
          ),
        ),
      ],
    );
  }
}
