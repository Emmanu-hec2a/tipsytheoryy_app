import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import '../../core/theme.dart';
import '../../providers/shiriki_provider.dart';
import '../../providers/user_provider.dart';
import '../../models/shiriki_session_model.dart';
import '../../services/notification_service.dart';
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
  bool _isWaitingForConfirmation = false;
  int _confirmationSecondsRemaining = 0;
  Timer? _confirmationCountdownTimer;
  StreamSubscription? _fcmSubscription;

  @override
  void initState() {
    super.initState();
    _fetchSession();
    _timer = Timer.periodic(const Duration(seconds: 30), (timer) { // 🛡️ Task 3: Low-frequency fallback
      _fetchSession();
    });
    
    // 🛡️ Task 3: Listen for FCM progress updates
    _fcmSubscription = NotificationService().onMessageReceived.listen((message) {
      final type = message.data['type'];
      if (type == 'shiriki_progress' || type == 'stk_confirmed') {
        debugPrint('Shiriki progress/confirmation FCM received, refreshing...');
        _fetchSession();
        // If it was my confirmation, the _fetchSession logic will handle calling _stopWaiting()
      } else if (type == 'phone_format_error' || type == 'stk_failed') {
        // 🛡️ Task: Handle failure/cancellation specifically
        _stopWaiting();
        if (mounted) {
          final reason = message.data['reason'] ?? message.data['error'] ?? "Payment could not be completed.";
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(reason),
              backgroundColor: Colors.red,
            ),
          );
        }
        _fetchSession(); // Refresh to show 'failed' status in list
      }
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
    _confirmationCountdownTimer?.cancel();
    _fcmSubscription?.cancel();
    _amountController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _fetchSession() async {
    await Provider.of<ShirikiProvider>(context, listen: false).fetchSession(widget.inviteCode);
    final session = Provider.of<ShirikiProvider>(context, listen: false).currentSession;
    if (session?.status == 'active' && _isWaitingForConfirmation) {
      // Check if user's contribution confirmed OR failed
      final user = Provider.of<UserProvider>(context, listen: false).user;
      
      final myContribution = session?.contributions.firstWhere(
        (c) => c.userId == user?.id && (c.status == 'confirmed' || c.status == 'failed'),
        orElse: () => ShirikiContributionModel(id: -1, userId: -1, username: '', amount: 0, status: '', createdAt: DateTime.now())
      );

      if (myContribution != null && myContribution.id != -1) {
        _stopWaiting();
        
        if (myContribution.status == 'confirmed') {
          // Task 4: Surface wallet credits
          if (myContribution.walletCreditAmount > 0) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'The pot was already full! KSh ${myContribution.walletCreditAmount.toStringAsFixed(0)} was added to your Tipsy Wallet. 🥂',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                backgroundColor: AppTheme.accentColor,
                duration: const Duration(seconds: 8),
              ),
            );
          }
          // Refresh wallet balance
          Provider.of<UserProvider>(context, listen: false).fetchProfile();
        } else if (myContribution.status == 'failed') {
           ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Payment confirmation failed. Please try again.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }

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

  void _startWaiting() {
    setState(() {
      _isWaitingForConfirmation = true;
      _confirmationSecondsRemaining = 120; // 🛡️ Task 2: 120s timeout
    });
    
    _confirmationCountdownTimer?.cancel();
    _confirmationCountdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_confirmationSecondsRemaining > 0) {
        setState(() => _confirmationSecondsRemaining--);
      } else {
        _stopWaiting(timeout: true);
      }
    });
  }

  void _stopWaiting({bool timeout = false}) {
    _confirmationCountdownTimer?.cancel();
    setState(() {
      _isWaitingForConfirmation = false;
    });

    if (timeout && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Confirmation is taking longer than expected. We'll notify you once it's complete! 🥂"),
          backgroundColor: AppTheme.primaryColor,
        ),
      );
    }
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
            // 🛡️ Fix: Add dynamic padding at the bottom of the scroll view 
            // to ensure content isn't hidden behind the persistent BottomSheet.
            SizedBox(height: session.remainingAmount > 0 ? 250 : 120),
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
            physics: const ClampingScrollPhysics(), // 🛡️ Fix: Ensure it works inside SingleChildScrollView
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
                          Text(
                            contribution.username, 
                            style: TextStyle(
                              fontWeight: FontWeight.bold, 
                              fontSize: 13,
                              color: contribution.status == 'confirmed' ? (isDark ? Colors.white : Colors.black87) : Colors.grey,
                            )
                          ),
                          Text(
                            contribution.status == 'confirmed' ? 'CONFIRMED' : 'CONFIRMING...',
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
                      style: TextStyle(
                        fontWeight: FontWeight.w900, 
                        fontSize: 14,
                        color: contribution.status == 'confirmed' ? (isDark ? Colors.white : Colors.black87) : Colors.grey,
                      ),
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
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10)],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_isWaitingForConfirmation)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Column(
                children: [
                  const SizedBox(
                    width: 24, height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.accentColor),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Waiting for confirmation...', 
                    style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13)
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _confirmationSecondsRemaining > 60 
                      ? 'This can take a minute' 
                      : 'Finalizing your contribution...',
                    style: const TextStyle(color: Colors.grey, fontSize: 11),
                  ),
                ],
              ),
            )
          else if (session.remainingAmount > 0) ...[
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
      _startWaiting(); // 🛡️ Task 2: Start waiting state
      _fetchSession();
    } else {
      final String errorMsg = result['error'] ?? 'Payment failed';
      final double? remaining = result['remaining']?.toDouble();

      if (remaining != null && remaining > 0) {
        // Task 1: Handle remaining balance error
        _amountController.text = remaining.toStringAsFixed(0);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Amount adjusted to remaining balance: KSh ${remaining.toStringAsFixed(0)}'),
            backgroundColor: Colors.orange,
            action: SnackBarAction(
              label: 'CONFIRM',
              textColor: Colors.white,
              onPressed: _submitContribution,
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMsg), backgroundColor: Colors.red),
        );
      }
    }
  }
}
