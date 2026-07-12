import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/theme.dart';
import '../../providers/rider_provider.dart';
import '../../models/order_model.dart';

class AvailableOrdersScreen extends StatefulWidget {
  const AvailableOrdersScreen({super.key});

  @override
  State<AvailableOrdersScreen> createState() => _AvailableOrdersScreenState();
}

class _AvailableOrdersScreenState extends State<AvailableOrdersScreen> {
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
    final isOnline = riderProvider.isOnline;
    final availableOrders = riderProvider.orderQueue.where((o) => o.status.toLowerCase() == 'pending').toList();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: RefreshIndicator(
        onRefresh: () => riderProvider.fetchRiderData(),
        displacement: 40,
        color: AppTheme.accentColor,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            _buildAppBar(riderProvider, isOnline),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildEarningsOverview(riderProvider),
                    const SizedBox(height: 32),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'AVAILABLE REQUESTS (${availableOrders.length})', 
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Colors.grey.shade400, letterSpacing: 1.2)
                        ),
                        if (isOnline) const Icon(Icons.radar_rounded, color: AppTheme.accentColor, size: 18),
                      ],
                    ),
                    const SizedBox(height: 16),
                    if (!isOnline)
                      _buildOfflineOverlay()
                    else if (riderProvider.isLoading && availableOrders.isEmpty)
                      const Center(child: Padding(padding: EdgeInsets.all(60), child: CircularProgressIndicator(color: AppTheme.primaryColor)))
                    else if (availableOrders.isEmpty)
                      _buildEmptyState()
                    else
                      ...availableOrders.map((order) => _buildOrderCard(context, order, riderProvider)),
                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar(RiderProvider provider, bool isOnline) {
    final topPadding = MediaQuery.of(context).padding.top;
    const collapsedHeight = kToolbarHeight;
    const expandedHeight = 110.0; // Minimalist height

    return SliverAppBar(
      pinned: true,
      expandedHeight: expandedHeight,
      collapsedHeight: collapsedHeight,
      backgroundColor: AppTheme.primaryColor,
      elevation: 0,
      automaticallyImplyLeading: false,
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 8.0),
          child: Row(
            children: [
              Text(
                isOnline ? 'ONLINE' : 'OFFLINE', 
                style: TextStyle(color: isOnline ? Colors.greenAccent : Colors.white54, fontSize: 10, fontWeight: FontWeight.w900)
              ),
              const SizedBox(width: 4),
              Switch(
                value: isOnline,
                onChanged: (val) => provider.toggleAvailability(val),
                activeColor: Colors.greenAccent,
                inactiveThumbColor: Colors.white24,
                inactiveTrackColor: Colors.black12,
              ),
            ],
          ),
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        collapseMode: CollapseMode.pin,
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppTheme.primaryColor, Color(0xFF06211B)],
            ),
          ),
          child: Stack(
            children: [
              // Title - manually positioned to stay fixed relative to top
              Positioned(
                left: 20,
                top: topPadding + 15,
                child: const Text(
                  'Rider Dashboard',
                  style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900),
                ),
              ),
              // Content Row - manually positioned to sit tight under the title
              Positioned(
                left: 20,
                right: 20,
                top: topPadding + 44, 
                child: Row(
                  children: [
                    const CircleAvatar(
                      radius: 11,
                      backgroundColor: Colors.white12,
                      child: Icon(Icons.person, size: 12, color: Colors.white),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        provider.riderProfile?.email ?? 'Connecting...',
                        style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 12, fontWeight: FontWeight.w600),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Row(
                      children: [
                        const Icon(Icons.star_rounded, color: Color(0xFFFFB800), size: 12),
                        const SizedBox(width: 4),
                        Text(
                          provider.riderProfile?.avgRating.toStringAsFixed(1) ?? '5.0',
                          style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w900),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEarningsOverview(RiderProvider provider) {
    final earnings = provider.earningsSummary;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? Theme.of(context).cardColor : Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: isDark ? [] : [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 25, offset: const Offset(0, 10))],
        border: isDark ? Border.all(color: Colors.white10) : null,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildEarningStat(context, 'TODAY', 'KSh ${earnings['total_earned'] ?? '0'}', isPrimary: true),
          _buildDivider(context),
          _buildEarningStat(context, 'TRIPS', '${earnings['delivery_count'] ?? '0'}'),
          _buildDivider(context),
          _buildEarningStat(context, 'TIPS', 'KSh ${earnings['total_tips'] ?? '0'}'),
        ],
      ),
    );
  }

  Widget _buildDivider(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(width: 1, height: 35, color: isDark ? Colors.white10 : Colors.grey.shade100);
  }

  Widget _buildEarningStat(BuildContext context, String label, String value, {bool isPrimary = false}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      children: [
        Text(label, style: TextStyle(color: isDark ? Colors.white38 : Colors.grey.shade400, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
        const SizedBox(height: 6),
        Text(
          value, 
          style: TextStyle(
            fontSize: isPrimary ? 18 : 16, 
            fontWeight: FontWeight.w900, 
            color: isPrimary ? (isDark ? Colors.white : AppTheme.primaryColor) : (isDark ? Colors.white70 : const Color(0xFF1E293B))
          )
        ),
      ],
    );
  }

  Widget _buildOfflineOverlay() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(50),
      decoration: BoxDecoration(
        color: isDark ? Theme.of(context).cardColor : Colors.white,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: isDark ? Colors.white10 : Colors.grey.shade100),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade50, shape: BoxShape.circle),
            child: Icon(Icons.wifi_off_rounded, size: 48, color: isDark ? Colors.white24 : Colors.grey.shade300),
          ),
          const SizedBox(height: 24),
          Text('You are Offline', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 20, color: isDark ? Colors.white : AppTheme.primaryColor)),
          const SizedBox(height: 8),
          Text(
            'Go online to see delivery requests near you and start earning.', 
            textAlign: TextAlign.center, 
            style: TextStyle(color: isDark ? Colors.white38 : Colors.grey, fontWeight: FontWeight.w500, height: 1.4)
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(50),
      child: Column(
        children: [
          Icon(Icons.radar_rounded, size: 64, color: isDark ? Colors.white.withValues(alpha: 0.05) : AppTheme.primaryColor.withValues(alpha: 0.05)),
          const SizedBox(height: 20),
          Text('Searching...', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: isDark ? Colors.white70 : AppTheme.primaryColor)),
          const SizedBox(height: 8),
          Text('New requests will appear here in real-time.', style: TextStyle(color: isDark ? Colors.white38 : Colors.grey, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildOrderCard(BuildContext context, OrderModel order, RiderProvider provider) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isDark ? Theme.of(context).cardColor : Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: isDark ? [] : [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 20, offset: const Offset(0, 8))],
        border: isDark ? Border.all(color: Colors.white10) : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: () {}, // Future detail view
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(color: AppTheme.primaryColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                      child: Text('#${order.orderNumber}', style: const TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.w900, fontSize: 12)),
                    ),
                    Row(
                      children: [
                        const Icon(Icons.access_time_filled_rounded, size: 14, color: AppTheme.accentColor),
                        const SizedBox(width: 4),
                        Text(DateFormat('hh:mm a').format(order.createdAt), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 12, color: AppTheme.accentColor)),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                _buildRouteItem(context, Icons.storefront_rounded, 'PICKUP', order.storeName ?? 'Store Location', isStore: true),
                Padding(
                  padding: const EdgeInsets.only(left: 11),
                  child: Align(alignment: Alignment.centerLeft, child: Text('⋮', style: TextStyle(color: isDark ? Colors.white24 : Colors.grey, fontSize: 18))),
                ),
                _buildRouteItem(context, Icons.location_on_rounded, 'DROP-OFF', order.addressString ?? 'Customer Address'),
                const SizedBox(height: 20),
                Divider(height: 1, color: isDark ? Colors.white10 : Colors.grey.shade100),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('POTENTIAL EARNING', style: TextStyle(color: isDark ? Colors.white38 : Colors.grey, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
                        const SizedBox(height: 4),
                        Text('KSh ${order.deliveryFee.toStringAsFixed(0)}', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 24, color: isDark ? Colors.white : AppTheme.primaryColor)),
                      ],
                    ),
                    SizedBox(
                      height: 50,
                      child: ElevatedButton(
                        onPressed: provider.isLoading ? null : () async {
                          final success = await provider.acceptOrder(order.id);
                          if (success && context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Order Accepted! Opening navigation...'), backgroundColor: Colors.green),
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.accentColor,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                        ),
                        child: provider.isLoading 
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Text('ACCEPT TASK', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1, fontSize: 13, color: Colors.white)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRouteItem(BuildContext context, IconData icon, String label, String address, {bool isStore = false}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      children: [
        Icon(icon, size: 22, color: isStore ? AppTheme.primaryColor : AppTheme.accentColor),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(color: isDark ? Colors.white38 : Colors.grey.shade400, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
              const SizedBox(height: 2),
              Text(address, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: isDark ? Colors.white70 : const Color(0xFF1E293B)), maxLines: 1, overflow: TextOverflow.ellipsis),
            ],
          ),
        ),
      ],
    );
  }
}
