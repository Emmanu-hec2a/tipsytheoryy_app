import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/theme.dart';
import '../../providers/rider_provider.dart';
import '../../widgets/rider_skeleton.dart';
import 'package:shimmer/shimmer.dart';

class RiderEarningsScreen extends StatefulWidget {
  const RiderEarningsScreen({super.key});

  @override
  State<RiderEarningsScreen> createState() => _RiderEarningsScreenState();
}

class _RiderEarningsScreenState extends State<RiderEarningsScreen> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<RiderProvider>(context, listen: false).fetchRiderData();
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final riderProvider = Provider.of<RiderProvider>(context);
    final summary = riderProvider.earningsSummary;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: AppTheme.primaryColor,
        elevation: 0,
        title: const Text('Earnings', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 18)),
        centerTitle: true,
      ),
      body: RefreshIndicator(
        onRefresh: () => riderProvider.fetchRiderData(),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              riderProvider.isLoading && summary.isEmpty
                ? const RiderStatSkeleton()
                : _buildTotalCard(summary),
              const SizedBox(height: 32),
              Text('TRANSACTION HISTORY', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: isDark ? Colors.white38 : Colors.grey, letterSpacing: 1.2)),
              const SizedBox(height: 16),
              riderProvider.isLoading && riderProvider.earningsHistory.isEmpty
                ? Column(children: List.generate(5, (_) => const RiderOrderSkeleton()))
                : _buildEarningsList(riderProvider),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTotalCard(Map<String, dynamic> summary) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(30),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppTheme.primaryColor, Color(0xFF1B4D42)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [BoxShadow(color: AppTheme.primaryColor.withValues(alpha: 0.3), blurRadius: 20, offset: const Offset(0, 10))],
      ),
      child: Column(
        children: [
          const Text('Total Earned', style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 1)),
          const SizedBox(height: 8),
          Text('KSh ${summary['total_earned'] ?? '0'}', style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.w900)),
          const SizedBox(height: 30),
          Row(
            children: [
              _buildMiniStat('Base Fare', 'KSh ${summary['total_base'] ?? '0'}'),
              Container(width: 1, height: 30, color: Colors.white10),
              _buildMiniStat('Total Tips', 'KSh ${summary['total_tips'] ?? '0'}'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMiniStat(String label, String value) {
    return Expanded(
      child: Column(
        children: [
          Text(label, style: const TextStyle(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16)),
        ],
      ),
    );
  }

  Widget _buildEarningsList(RiderProvider provider) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (provider.earningsHistory.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(40),
        decoration: BoxDecoration(
          color: isDark ? Theme.of(context).cardColor : Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: isDark ? Colors.white10 : Colors.grey.shade100),
        ),
        child: Center(
          child: Column(
            children: [
              Icon(Icons.receipt_long_rounded, size: 48, color: isDark ? Colors.white10 : Colors.grey.shade200),
              const SizedBox(height: 16),
              Text('No earnings yet', style: TextStyle(fontWeight: FontWeight.w900, color: isDark ? Colors.white38 : Colors.grey)),
              const SizedBox(height: 4),
              Text('Your earnings will appear here after deliveries.', style: TextStyle(color: isDark ? Colors.white24 : Colors.grey, fontSize: 12, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: provider.earningsHistory.length,
      itemBuilder: (context, index) {
        final item = provider.earningsHistory[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isDark ? Theme.of(context).cardColor : Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: isDark ? [] : [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10)],
            border: isDark ? Border.all(color: Colors.white10) : null,
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: Colors.green.withValues(alpha: 0.1), shape: BoxShape.circle),
                child: const Icon(Icons.add_rounded, color: Colors.green, size: 20),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Delivery #${item['order_number'] ?? item['order'] ?? 'N/A'}', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: isDark ? Colors.white70 : Colors.black87)),
                    const SizedBox(height: 2),
                    Text(
                      item['created_at'] != null 
                        ? DateFormat('MMM dd, hh:mm a').format(DateTime.parse(item['created_at']).toLocal())
                        : 'Unknown date', 
                      style: TextStyle(color: isDark ? Colors.white24 : Colors.grey.shade400, fontSize: 11, fontWeight: FontWeight.bold)
                    ),
                  ],
                ),
              ),
              Text(
                '+ KSh ${item['total'] ?? '0'}', 
                style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: Colors.green)
              ),
            ],
          ),
        );
      },
    );
  }
}
