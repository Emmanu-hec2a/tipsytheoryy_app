import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';
import '../../providers/auth_provider.dart';
import '../customer/customer_shell.dart';
import '../rider/rider_shell.dart';

class SocialPhoneLinkScreen extends StatefulWidget {
  const SocialPhoneLinkScreen({super.key});

  @override
  State<SocialPhoneLinkScreen> createState() => _SocialPhoneLinkScreenState();
}

class _SocialPhoneLinkScreenState extends State<SocialPhoneLinkScreen> {
  final _phoneController = TextEditingController();
  bool _isLoading = false;

  Future<void> _handleLink() async {
    if (_phoneController.text.length < 9) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid phone number')),
      );
      return;
    }

    setState(() => _isLoading = true);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    final success = await authProvider.linkSocialPhone(_phoneController.text);

    setState(() => _isLoading = false);

    if (success && mounted) {
      Widget nextShell = authProvider.role == 'rider' 
        ? const RiderShell() 
        : const CustomerShell();
        
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => nextShell),
        (route) => false,
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(authProvider.errorMessage ?? 'Failed to link phone')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.phone_iphone_rounded, size: 60, color: AppTheme.primaryColor),
              const SizedBox(height: 24),
              const Text(
                'One Last Step!',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, letterSpacing: -0.5),
              ),
              const SizedBox(height: 12),
              Text(
                'To coordinate your deliveries and handle M-Pesa payments, we need your phone number.',
                style: TextStyle(color: isDark ? Colors.white38 : Colors.grey.shade600, fontSize: 16, height: 1.5),
              ),
              const SizedBox(height: 40),
              Text('PHONE NUMBER', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12, color: isDark ? Colors.white24 : Colors.grey, letterSpacing: 1)),
              const SizedBox(height: 10),
              TextField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                autofocus: true,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.phone_outlined),
                  prefix: const Padding(
                    padding: EdgeInsets.only(right: 8),
                    child: Text('+254', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                  hintText: '712 345 678',
                  filled: true,
                  fillColor: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade50,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                height: 60,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleLink,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  ),
                  child: _isLoading 
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('COMPLETE SETUP', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1)),
                ),
              ),
              const SizedBox(height: 20),
              Center(
                child: TextButton(
                  onPressed: () => Provider.of<AuthProvider>(context, listen: false).logout(
                    onLogout: () => Navigator.pushReplacementNamed(context, '/'),
                  ),
                  child: Text('Cancel and Logout', style: TextStyle(color: isDark ? Colors.white24 : Colors.grey, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
