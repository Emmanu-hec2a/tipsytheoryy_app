import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../core/theme.dart';
import '../../providers/rider_provider.dart';
import '../../models/order_model.dart';

class DeliveryDetailsScreen extends StatefulWidget {
  final int orderId;
  const DeliveryDetailsScreen({super.key, required this.orderId});

  @override
  State<DeliveryDetailsScreen> createState() => _DeliveryDetailsScreenState();
}

class _DeliveryDetailsScreenState extends State<DeliveryDetailsScreen> {
  String? _imagePath;
  final ImagePicker _picker = ImagePicker();

  Future<void> _takeVerificationPhoto() async {
    final XFile? photo = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 70, // Optimize for upload
    );
    if (photo != null) {
      setState(() => _imagePath = photo.path);
    }
  }

  @override
  Widget build(BuildContext context) {
    final riderProvider = Provider.of<RiderProvider>(context);
    final order = riderProvider.orderQueue.firstWhere((o) => o.id == widget.orderId, orElse: () => throw Exception('Order not found'));
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

                  if (order.status.toLowerCase() == 'arrived') ...[
                    Text('MIDNIGHT MIRROR VERIFICATION', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: isDark ? Colors.white38 : Colors.grey, letterSpacing: 1.2)),
                    const SizedBox(height: 16),
                    _buildVerificationSection(context, order),
                    const SizedBox(height: 32),
                  ],

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
                          // Mandatory check for V1 logic: if required, must have image path or manual verify
                          if (nextStatus == 'delivered' && order.requiresRiderVerification && _imagePath == null) {
                             ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('High-value verification required. Please take a photo.'), backgroundColor: Colors.red),
                            );
                            return;
                          }

                          final success = await riderProvider.updateOrderStatus(
                            order.id, 
                            nextStatus,
                            verificationMethod: 'physical_id',
                            imagePath: _imagePath
                          );
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

  Widget _buildVerificationSection(BuildContext context, OrderModel order) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isRequired = order.requiresRiderVerification;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isRequired ? AppTheme.primaryColor.withValues(alpha: 0.05) : (isDark ? Theme.of(context).cardColor : Colors.white),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isRequired ? AppTheme.primaryColor.withValues(alpha: 0.2) : (isDark ? Colors.white10 : Colors.grey.shade100)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.shield_rounded, color: isRequired ? AppTheme.primaryColor : Colors.grey, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(isRequired ? 'MANDATORY VERIFICATION' : 'OPTIONAL VERIFICATION', 
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: isRequired ? AppTheme.primaryColor : Colors.grey)),
                    Text(isRequired ? 'Required for high-value orders' : 'Manual ID check recommended',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (_imagePath != null) 
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.file(
                File(_imagePath!), 
                height: 150, 
                width: double.infinity, 
                fit: BoxFit.cover
              ),
            )
          else
            InkWell(
              onTap: _takeVerificationPhoto,
              child: Container(
                height: 100,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: isDark ? Colors.white10 : Colors.grey.shade200, style: BorderStyle.solid),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.camera_alt_rounded, color: isRequired ? AppTheme.primaryColor : Colors.grey, size: 32),
                    const SizedBox(height: 8),
                    Text('Capture ID Photo', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: isRequired ? AppTheme.primaryColor : Colors.grey)),
                  ],
                ),
              ),
            ),
        ],
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
