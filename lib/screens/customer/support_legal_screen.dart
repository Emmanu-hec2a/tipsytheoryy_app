import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme.dart';
import '../../core/legal_texts.dart';
import 'legal_content_screen.dart';

class SupportLegalScreen extends StatelessWidget {
  const SupportLegalScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
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
            _buildSection(context, 'GET IN TOUCH', [
              _buildLegalItem(context, Icons.chat_bubble_outline_rounded, 'WhatsApp Support', 'Instant help via WhatsApp', () => _launchWhatsApp()),
              _buildLegalItem(context, Icons.headset_mic_outlined, 'Help Center', 'Speak with our support team', () => _launchPhone()),
              _buildLegalItem(context, Icons.mail_outline_rounded, 'Email Support', 'support@s.tipsytheoryy.com', () => _launchEmail()),
              _buildLegalItem(context, Icons.phone_outlined, 'Call Us', '+254 718 2588 21', () => _launchPhone()),
            ]),
            _buildSection(context, 'LEGAL & POLICIES', [
              _buildLegalItem(context, Icons.description_outlined, 'Terms of Service', 'Read our user agreement', () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const LegalContentScreen(
                  title: 'Terms of Service',
                  content: LegalTexts.customerTerms,
                )));
              }),
              _buildLegalItem(context, Icons.privacy_tip_outlined, 'Privacy Policy', 'How we handle your data', () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const LegalContentScreen(
                  title: 'Privacy Policy',
                  content: LegalTexts.privacyPolicy,
                )));
              }),
              _buildLegalItem(context, Icons.info_outline_rounded, 'About TipsyTheoryy', 'Our mission and story', () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const LegalContentScreen(
                  title: 'About TipsyTheoryy',
                  content: LegalTexts.aboutUs,
                )));
              }),
              _buildLegalItem(context, Icons.verified_user_outlined, 'Liquor Licenses', 'Verified merchant network', () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const LegalContentScreen(
                  title: 'About Our Licenses',
                  content: 'All merchants on TipsyTheoryy are fully licensed by the relevant authorities to sell and distribute alcoholic beverages. We verify business registrations and liquor licenses for every partner store on our platform.',
                )));
              }),
            ]),
            const SizedBox(height: 40),
            const Text('App Version 1.0.0 (Production)', style: TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.bold)),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(BuildContext context, String title, List<Widget> items) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 12),
          child: Text(title, style: TextStyle(color: isDark ? Colors.white38 : Colors.grey.shade500, fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
        ),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 20),
          decoration: BoxDecoration(
            color: isDark ? Theme.of(context).cardColor : Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: isDark ? Border.all(color: Colors.white10) : null,
          ),
          child: Column(children: items),
        ),
      ],
    );
  }

  Widget _buildLegalItem(BuildContext context, IconData icon, String title, String subtitle, VoidCallback onTap) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: AppTheme.primaryColor.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(10)),
        child: Icon(icon, color: AppTheme.primaryColor, size: 22),
      ),
      title: Text(title, style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: isDark ? Colors.white : Colors.black87)),
      subtitle: Text(subtitle, style: TextStyle(color: isDark ? Colors.white38 : Colors.grey.shade500, fontSize: 12, fontWeight: FontWeight.bold)),
      trailing: Icon(Icons.chevron_right_rounded, color: isDark ? Colors.white24 : Colors.grey),
    );
  }

  void _launchEmail() async {
    final Uri url = Uri.parse('mailto:support@s.tipsytheoryy.com?subject=Support%20Request');
    _launchUrl(url);
  }

  void _launchPhone() async {
    final Uri url = Uri.parse('tel:+254718258821');
    _launchUrl(url);
  }

  void _launchWhatsApp() async {
    // 🛡️ Optimized for both WhatsApp and WhatsApp Business
    final Uri url = Uri.parse("https://wa.me/254718258821?text=Hello%20TipsyTheoryy%20Support");
    _launchUrl(url);
  }

  Future<void> _launchUrl(Uri url) async {
    try {
      // 🚀 Direct launch is more reliable than canLaunch on modern Android/iOS
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } catch (e) {
      debugPrint('Could not launch $url: $e');
    }
  }
}
