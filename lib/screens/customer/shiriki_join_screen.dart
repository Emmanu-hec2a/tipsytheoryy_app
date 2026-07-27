import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';
import '../../providers/shiriki_provider.dart';
import 'shiriki_lobby_screen.dart';

class ShirikiJoinScreen extends StatefulWidget {
  const ShirikiJoinScreen({super.key});

  @override
  State<ShirikiJoinScreen> createState() => _ShirikiJoinScreenState();
}

class _ShirikiJoinScreenState extends State<ShirikiJoinScreen> {
  final TextEditingController _codeController = TextEditingController();
  bool _isLoading = false;

  Future<void> _joinSession() async {
    final code = _codeController.text.trim().toUpperCase();
    if (code.isEmpty) return;

    setState(() => _isLoading = true);
    
    await Provider.of<ShirikiProvider>(context, listen: false).fetchSession(code);
    final provider = Provider.of<ShirikiProvider>(context, listen: false);

    setState(() => _isLoading = false);

    if (provider.currentSession != null && mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => ShirikiLobbyScreen(inviteCode: code)),
      );
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(provider.error ?? 'Invalid Invite Code'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: AppTheme.primaryColor,
        elevation: 0,
        title: const Text('Join Shiriki Pay', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.people_alt_rounded, size: 64, color: AppTheme.primaryColor),
            ),
            const SizedBox(height: 32),
            const Text(
              'Enter Invite Code',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 8),
            const Text(
              'Your friend should have provided a 6-digit code or a link.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 32),
            TextField(
              controller: _codeController,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 24, 
                fontWeight: FontWeight.w900, 
                letterSpacing: 8, 
                color: isDark ? Colors.white : AppTheme.primaryColor
              ),
              decoration: InputDecoration(
                hintText: 'TT-XXXX',
                hintStyle: TextStyle(color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.grey.shade300, letterSpacing: 2),
                filled: true,
                fillColor: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade50,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
              ),
              onSubmitted: (_) => _joinSession(),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _isLoading ? null : _joinSession,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                minimumSize: const Size(double.infinity, 60),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: _isLoading 
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('JOIN POT', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }
}
