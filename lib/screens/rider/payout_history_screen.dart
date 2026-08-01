import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/theme.dart';
import '../../providers/rider_provider.dart';

class PayoutHistoryScreen extends StatefulWidget {
  const PayoutHistoryScreen({super.key});

  @override
  State<PayoutHistoryScreen> createState() => _PayoutHistoryScreenState();
}

class _PayoutHistoryScreenState extends State<PayoutHistoryScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<RiderProvider>(context, listen: false).fetchPayoutHistory();
    });
  }

  @override
  Widget build(BuildContext context) {
    final riderProvider = Provider.of<RiderProvider>(context);
    final payouts = riderProvider.payoutHistory;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: AppTheme.primaryColor,
        elevation: 0,
        title: const Text('Payout History', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 18)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: riderProvider.isLoading && payouts.isEmpty
          ? const Center(child: CircularProgressIndicator(color: AppTheme.accentColor))
          : RefreshIndicator(
              onRefresh: () => riderProvider.fetchPayoutHistory(),
              child: payouts.isEmpty
                  ? _buildEmptyState(isDark)
                  : ListView.builder(
                      padding: const EdgeInsets.all(20),
                      itemCount: payouts.length,
                      itemBuilder: (context, index) {
                        final stat = payouts[index];
                        return _buildPayoutCard(stat, riderProvider, isDark);
                      },
                    ),
            ),
    );
  }

  Widget _buildPayoutCard(dynamic stat, RiderProvider provider, bool isDark) {
    final status = stat['status'].toString().toLowerCase();
    final Color statusColor = status == 'paid' ? Colors.green : (status == 'disputed' ? Colors.red : Colors.orange);
    final String weekStr = DateFormat('MMM dd').format(DateTime.parse(stat['week_start']).toLocal());
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.05) : const Color(0xFFF1F5F9)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('WEEK OF $weekStr', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.grey, letterSpacing: 0.5)),
                  Text(stat['store_name'] ?? 'Merchant Payout', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: isDark ? Colors.white : AppTheme.primaryColor)),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(100)),
                child: Text(status.toUpperCase(), style: TextStyle(color: statusColor, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Divider(height: 1),
          ),
          Row(
            children: [
              _buildAmountItem('Base Fare', 'KSh ${stat['total_base_fare']}', isDark),
              _buildAmountItem('Tips', 'KSh ${stat['total_tips']}', isDark),
              _buildAmountItem('Total', 'KSh ${stat['total_amount']}', isDark, isBold: true),
            ],
          ),
          if (status == 'paid') ...[
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.green.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(12)),
              child: Row(
                children: [
                  const Icon(Icons.check_circle_rounded, color: Colors.green, size: 16),
                  const SizedBox(width: 8),
                  Text('Ref: ${stat['mpesa_code']}', style: const TextStyle(color: Colors.green, fontWeight: FontWeight.w900, fontSize: 12)),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => _showDisputeDialog(stat['id'], provider),
                    child: const Text('Not Received?', style: TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.bold, decoration: TextDecoration.underline)),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAmountItem(String label, String value, bool isDark, {bool isBold = false}) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: Colors.grey)),
          Text(value, style: TextStyle(fontSize: 14, fontWeight: isBold ? FontWeight.w900 : FontWeight.w700, color: isDark ? Colors.white : AppTheme.primaryColor)),
        ],
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.account_balance_wallet_outlined, size: 64, color: isDark ? Colors.white10 : Colors.grey.shade200),
          const SizedBox(height: 16),
          const Text('No payouts yet', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: Colors.grey)),
          const Text('Your weekly earnings will appear here.', style: TextStyle(color: Colors.grey, fontSize: 12)),
        ],
      ),
    );
  }

  void _showDisputeDialog(int payoutId, RiderProvider provider) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Report Payment Issue', style: TextStyle(fontWeight: FontWeight.w900)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('If you did not receive this payment or the M-Pesa code is invalid, please let us know.', style: TextStyle(fontSize: 13, color: Colors.grey)),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              decoration: const InputDecoration(hintText: 'Reason for dispute...', border: OutlineInputBorder()),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCEL')),
          ElevatedButton(
            onPressed: () async {
              final success = await provider.disputePayout(payoutId, controller.text);
              if (mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(success ? 'Dispute submitted to Admin' : 'Failed to submit dispute')),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            child: const Text('REPORT ISSUE'),
          ),
        ],
      ),
    );
  }
}
