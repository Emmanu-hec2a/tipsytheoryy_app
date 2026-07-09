import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme.dart';

class SupportLegalScreen extends StatelessWidget {
  const SupportLegalScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppTheme.primaryColor,
        title: const Text('Support & Legal', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 24),
            _buildSection('GET IN TOUCH', [
              _buildLegalItem(Icons.headset_mic_rounded, 'Help Center', 'Speak with our support team', () {}),
              _buildLegalItem(Icons.mail_outline_rounded, 'Email Support', 'support@tipsytheoryy.com', () => _launchEmail()),
              _buildLegalItem(Icons.phone_outlined, 'Call Us', '+254 700 000000', () => _launchPhone()),
            ]),
            _buildSection('LEGAL & POLICIES', [
              _buildLegalItem(Icons.description_outlined, 'Terms of Service', 'Read our user agreement', () {}),
              _buildLegalItem(Icons.privacy_tip_outlined, 'Privacy Policy', 'How we handle your data', () {}),
              _buildLegalItem(Icons.info_outline_rounded, 'Liquor Licenses', 'Verified merchant network', () {}),
            ]),
            const SizedBox(height: 40),
            const Text('App Version 1.0.0 (Production)', style: TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.bold)),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 12),
          child: Text(title, style: TextStyle(color: Colors.grey.shade500, fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
        ),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(children: items),
        ),
      ],
    );
  }

  Widget _buildLegalItem(IconData icon, String title, String subtitle, VoidCallback onTap) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: AppTheme.primaryColor.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(10)),
        child: Icon(icon, color: AppTheme.primaryColor, size: 22),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15)),
      subtitle: Text(subtitle, style: TextStyle(color: Colors.grey.shade500, fontSize: 12, fontWeight: FontWeight.bold)),
      trailing: const Icon(Icons.chevron_right_rounded, color: Colors.grey),
    );
  }

  void _launchEmail() async {
    final Uri emailLaunchUri = Uri(scheme: 'mailto', path: 'support@tipsytheoryy.com');
    if (await canLaunchUrl(emailLaunchUri)) await launchUrl(emailLaunchUri);
  }

  void _launchPhone() async {
    final Uri phoneLaunchUri = Uri(scheme: 'tel', path: '+254700000000');
    if (await canLaunchUrl(phoneLaunchUri)) await launchUrl(phoneLaunchUri);
  }
}
