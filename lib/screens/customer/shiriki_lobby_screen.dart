import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import '../../core/theme.dart';
import '../../providers/shiriki_provider.dart';
import '../../providers/user_provider.dart';
import 'order_tracking_screen.dart';

class ShirikiLobbyScreen extends StatefulWidget {
  final String inviteCode;
  const ShirikiLobbyScreen({super.key, required this.inviteCode});

  @override
  State<ShirikiLobbyScreen> createState() => _ShirikiLobbyScreenState();
}

class _ShirikiLobbyScreenState extends State<ShirikiLobbyScreen> {
  Timer? _timer;
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _fetchSession();
    _timer = Timer.periodic(const Duration(seconds: 10), (timer) {
      _fetchSession();
    });
    
    // Prefill phone
    final user = Provider.of<UserProvider>(context, listen: false).user;
    if (user?.phone != null) {
      _phoneController.text = user!.phone!;
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _amountController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _fetchSession() async {
    await Provider.of<ShirikiProvider>(context, listen: false).fetchSession(widget.inviteCode);
    final session = Provider.of<ShirikiProvider>(context, listen: false).currentSession;
    
    if (session?.status == 'completed' && mounted) {
      _timer?.cancel();
      // Navigate to tracking if order is finalized
      if (session?.orderDetails != null) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => OrderTrackingScreen(orderId: session!.orderDetails['id'])),
        );
      }
    }
  }

  void _shareInvite() {
    final session = Provider.of<ShirikiProvider>(context, listen: false).currentSession;
    if (session == null) return;

    final text = "I'm ordering drinks on TipsyTheoryy! 🥂 Join the Shiriki pot and contribute your share.\n\n"
        "Invite Code: ${session.inviteCode}\n"
        "Download TipsyTheoryy to join!";
    Share.share(text);
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ShirikiProvider>(context);
    final userProvider = Provider.of<UserProvider>(context);
    final session = provider.currentSession;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (provider.isLoading && session == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (session == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Shiriki Pay')),
        body: Center(child: Text(provider.error ?? 'Session not found')),
      );
    }

    final isHost = session.hostId == userProvider.user?.id;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: AppTheme.primaryColor,
        elevation: 0,
        centerTitle: true,
        title: const Text('Shiriki Lobby', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900)),
        actions: [
          IconButton(onPressed: _fetchSession, icon: const Icon(Icons.refresh, color: Colors.white)),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildPotHeader(session, isDark),
            const SizedBox(height: 24),
            _buildInviteCard(session, isDark),
            const SizedBox(height: 24),
            _buildContributorsList(session, isDark),
            const SizedBox(height: 120),
          ],
        ),
      ),
      bottomSheet: !isHost || session.remainingAmount > 0 ? _buildActionArea(session, isDark) : null,
    );
  }

  Widget _buildPotHeader(dynamic session, bool isDark) {
    final progress = session.progress;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
      decoration: const BoxDecoration(
        color: AppTheme.primaryColor,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
      ),
      child: Column(
        children: [
          const Text('THE POT', style: TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 2)),
          const SizedBox(height: 8),
          Text(
            'KSh ${session.amountCollected.toStringAsFixed(0)} / ${session.totalAmount.toStringAsFixed(0)}',
            style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 16),
          // Progress Bar
          Container(
            height: 12,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: progress.clamp(0.0, 1.0),
              child: Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [AppTheme.accentColor, Colors.orangeAccent]),
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [BoxShadow(color: AppTheme.accentColor.withValues(alpha: 0.4), blurRadius: 10)],
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            '${(progress * 100).toInt()}% Collected',
            style: const TextStyle(color: AppTheme.accentColor, fontWeight: FontWeight.bold, fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _buildInviteCard(dynamic session, bool isDark) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Theme.of(context).cardColor : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: isDark ? Border.all(color: Colors.white.withValues(alpha: 0.05)) : null,
        boxShadow: isDark ? [] : [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 20)],
      ),
      child: Column(
        children: [
          const Text('INVITE FRIENDS', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 1, color: Colors.grey)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withValues(alpha: 0.05) : AppTheme.primaryColor.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.primaryColor.withValues(alpha: 0.1)),
            ),
            child: Text(
              session.inviteCode,
              style: TextStyle(
                fontSize: 20, 
                fontWeight: FontWeight.w900, 
                color: isDark ? Colors.white : AppTheme.primaryColor, 
                letterSpacing: 4
              ),
            ),
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: _shareInvite,
            icon: const Icon(Icons.share_rounded, size: 18),
            label: const Text('SHARE INVITE', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900)),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              minimumSize: const Size(double.infinity, 45),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContributorsList(dynamic session, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 24),
          child: Text('CONTRIBUTORS', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12, color: Colors.grey, letterSpacing: 1.5)),
        ),
        const SizedBox(height: 12),
        if (session.contributions.isEmpty)
          const Padding(
            padding: EdgeInsets.all(40.0),
            child: Center(child: Text('No contributions yet. Be the first!', style: TextStyle(color: Colors.grey))),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: session.contributions.length,
            itemBuilder: (context, index) {
              final contribution = session.contributions[index];
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? Theme.of(context).cardColor : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 16,
                      backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.1),
                      child: Text(contribution.username[0].toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryColor, fontSize: 12)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(contribution.username, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                          Text(
                            contribution.status.toUpperCase(),
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w900,
                              color: contribution.status == 'confirmed' ? Colors.green : Colors.orange,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      'KSh ${contribution.amount.toStringAsFixed(0)}',
                      style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14),
                    ),
                  ],
                ),
              );
            },
          ),
      ],
    );
  }

  Widget _buildActionArea(dynamic session, bool isDark) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    
    return Container(
      padding: EdgeInsets.fromLTRB(20, 16, 20, bottomPadding > 0 ? bottomPadding + 16 : 24),
      decoration: BoxDecoration(
        color: isDark ? Theme.of(context).cardColor : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        border: isDark ? Border.all(color: Colors.white.withValues(alpha: 0.05)) : null,
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10)],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (session.remainingAmount > 0) ...[
             Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _amountController,
                      keyboardType: TextInputType.number,
                      style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontWeight: FontWeight.bold),
                      decoration: InputDecoration(
                        hintText: 'Amount',
                        hintStyle: TextStyle(color: isDark ? Colors.white24 : Colors.grey),
                        prefixText: 'KSh ',
                        prefixStyle: TextStyle(color: isDark ? Colors.white70 : Colors.black87, fontWeight: FontWeight.bold),
                        filled: true,
                        fillColor: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade50,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: () => _amountController.text = session.remainingAmount.toStringAsFixed(0),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.accentColor,
                      minimumSize: const Size(60, 48),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('MAX', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 11)),
                  ),
                ],
             ),
             const SizedBox(height: 12),
             TextField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontWeight: FontWeight.bold),
                decoration: InputDecoration(
                  hintText: 'M-Pesa Phone',
                  hintStyle: TextStyle(color: isDark ? Colors.white24 : Colors.grey),
                  prefixIcon: const Icon(Icons.phone, size: 18),
                  filled: true,
                  fillColor: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade50,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _isProcessing ? null : _submitContribution,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _isProcessing 
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('CONTRIBUTE VIA M-PESA', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 0.5)),
              ),
          ] else
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: const Text('Pot is full! Waiting for order confirmation...', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green, fontSize: 13)),
            ),
        ],
      ),
    );
  }

  Future<void> _submitContribution() async {
    final amountStr = _amountController.text.trim();
    final phone = _phoneController.text.trim();
    
    if (amountStr.isEmpty || phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fill all fields')));
      return;
    }

    final amount = double.tryParse(amountStr);
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Invalid amount')));
      return;
    }

    setState(() => _isProcessing = true);
    
    final result = await Provider.of<ShirikiProvider>(context, listen: false).contribute(
      inviteCode: widget.inviteCode,
      amount: amount,
      phone: phone,
    );

    setState(() => _isProcessing = false);

    if (result['success']) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('STK Push sent! Please confirm on your phone.'), backgroundColor: Colors.green),
      );
      _amountController.clear();
      _fetchSession();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['error'] ?? 'Payment failed'), backgroundColor: Colors.red),
      );
    }
  }
}
