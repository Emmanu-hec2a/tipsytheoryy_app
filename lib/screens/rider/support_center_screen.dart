import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/services.dart';
import '../../core/theme.dart';
import '../../providers/rider_provider.dart';
import 'payout_history_screen.dart';

class SupportCenterScreen extends StatefulWidget {
  const SupportCenterScreen({super.key});

  @override
  State<SupportCenterScreen> createState() => _SupportCenterScreenState();
}

class _SupportCenterScreenState extends State<SupportCenterScreen> {
  double _panicProgress = 0.0;
  bool _isPanicTriggered = false;

  void _onPanicLongPressStart(LongPressStartDetails details) async {
    if (_isPanicTriggered) return;
    HapticFeedback.heavyImpact();
  }

  void _onPanicLongPressEnd(LongPressEndDetails details) {
    if (_isPanicTriggered) return;
    setState(() => _panicProgress = 0.0);
  }

  @override
  Widget build(BuildContext context) {
    final riderProvider = Provider.of<RiderProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: AppTheme.primaryColor,
        elevation: 0,
        centerTitle: true,
        title: const Text('Support Center', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 18)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildPanicSection(riderProvider, isDark),
            const SizedBox(height: 32),
            const Text('QUICK HELP', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.grey, letterSpacing: 1.2)),
            const SizedBox(height: 12),
            _buildHelpGrid(isDark),
            const SizedBox(height: 32),
            const Text('FINANCIALS', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.grey, letterSpacing: 1.2)),
            const SizedBox(height: 12),
            _buildFinancialCard(isDark),
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  Widget _buildPanicSection(RiderProvider provider, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: Colors.red.withValues(alpha: 0.1)),
      ),
      child: Column(
        children: [
          const Icon(Icons.warning_amber_rounded, color: Colors.red, size: 48),
          const SizedBox(height: 16),
          const Text('Emergency? Trigger Panic Alert', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.red)),
          const SizedBox(height: 8),
          const Text(
            'This will send your live coordinates to Tipsy Theoryy HQ and your Store Manager instantly.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 24),
          GestureDetector(
            onLongPressStart: _onPanicLongPressStart,
            onLongPressEnd: _onPanicLongPressEnd,
            onLongPress: () async {
              if (_isPanicTriggered) return;
              setState(() => _isPanicTriggered = true);
              final success = await provider.triggerPanic();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(success ? '🚨 ALERTS SENT! HELP IS ON THE WAY.' : 'Failed to send alert. Try calling support.'),
                    backgroundColor: success ? Colors.red : Colors.orange,
                  ),
                );
              }
              Future.delayed(const Duration(seconds: 10), () {
                if (mounted) setState(() => _isPanicTriggered = false);
              });
            },
            child: Container(
              height: 70,
              width: double.infinity,
              decoration: BoxDecoration(
                color: _isPanicTriggered ? Colors.black : Colors.red,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(color: Colors.red.withValues(alpha: 0.3), blurRadius: 15, offset: const Offset(0, 8))
                ],
              ),
              child: Center(
                child: Text(
                  _isPanicTriggered ? 'ALERTING...' : 'LONG PRESS TO PANIC',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, letterSpacing: 1),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHelpGrid(bool isDark) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.4,
      children: [
        _buildHelpTile(Icons.chat_bubble_rounded, 'Live Chat', 'Talk to Concierge', Colors.blue, () => _launchWhatsApp()),
        _buildHelpTile(Icons.help_center_rounded, 'FAQs', 'Read Guidebook', Colors.purple, () {}),
        _buildHelpTile(Icons.report_problem_rounded, 'Report Issue', 'Store/Customer', Colors.orange, () {}),
        _buildHelpTile(Icons.phone_in_talk_rounded, 'Hotline', 'Direct Call', Colors.green, () => launchUrl(Uri.parse('tel:+254700000000'))),
      ],
    );
  }

  Widget _buildHelpTile(IconData icon, String title, String sub, Color color, VoidCallback onTap) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? AppTheme.darkSurface : Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.05) : const Color(0xFFF1F5F9)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(title, style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: isDark ? Colors.white : AppTheme.primaryColor)),
            Text(sub, style: const TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildFinancialCard(bool isDark) {
    return InkWell(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PayoutHistoryScreen())),
      borderRadius: BorderRadius.circular(24),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppTheme.primaryColor.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppTheme.primaryColor.withValues(alpha: 0.1)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: AppTheme.primaryColor, borderRadius: BorderRadius.circular(16)),
              child: const Icon(Icons.payments_rounded, color: Colors.white),
            ),
            const SizedBox(width: 16),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Payout History', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                  Text('View weekly earnings & settlements', style: TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded, color: AppTheme.primaryColor, size: 16),
          ],
        ),
      ),
    );
  }

  void _launchWhatsApp() async {
    const phone = "+254700000000";
    final url = Uri.parse("https://wa.me/$phone?text=Rider Support Request");
    if (await canLaunchUrl(url)) await launchUrl(url);
  }
}
