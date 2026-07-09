import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../auth/login_screen.dart';
import '../auth/signup_screen.dart';

class LandingScreen extends StatelessWidget {
  const LandingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // We use LayoutBuilder to ensure we adapt to the screen height without scrolling
    return Scaffold(
      backgroundColor: Colors.white,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final double screenHeight = constraints.maxHeight;
          final bool isSmallScreen = screenHeight < 700;

          return SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: IntrinsicHeight(
                child: Column(
                  children: [
                    _buildCurvedHeader(context, isSmallScreen),
                    Padding(
                      padding: EdgeInsets.fromLTRB(24, isSmallScreen ? 12 : 20, 24, 0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildCustomerCard(context, isSmallScreen),
                          const SizedBox(height: 12),
                          _buildRiderCard(context, isSmallScreen),
                          const SizedBox(height: 12),
                          _buildTrustIndicators(isSmallScreen),
                          const SizedBox(height: 16),
                          _buildFooter(context),
                          SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCurvedHeader(BuildContext context, bool isSmall) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF0D3B30), Color(0xFF06211B)],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.elliptical(200, 40),
          bottomRight: Radius.elliptical(200, 40),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            SizedBox(height: isSmall ? 10 : 20),
            Icon(Icons.wine_bar_rounded, size: isSmall ? 40 : 50, color: Colors.white),
            const SizedBox(height: 8),
            RichText(
              text: const TextSpan(
                style: TextStyle(fontSize: 30, letterSpacing: -1),
                children: [
                  TextSpan(text: 'Tipsy', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w400)),
                  TextSpan(text: 'Theoryy', style: TextStyle(color: AppTheme.accentColor, fontWeight: FontWeight.w900)),
                ],
              ),
            ),
            const Text(
              'Premium Liquor Delivered Fast',
              style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 50, vertical: isSmall ? 12 : 16),
              child: const Text(
                'Get your favorite drinks delivered in minutes or earn money as a rider',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white54, fontSize: 12, fontWeight: FontWeight.w500, height: 1.4),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(width: 30, height: 3, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2))),
                const SizedBox(width: 8),
                Container(width: 8, height: 3, decoration: BoxDecoration(color: AppTheme.accentColor, borderRadius: BorderRadius.circular(2))),
                const SizedBox(width: 8),
                Container(width: 30, height: 3, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2))),
              ],
            ),
            SizedBox(height: isSmall ? 20 : 30),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomerCard(BuildContext context, bool isSmall) {
    return Container(
      padding: EdgeInsets.all(isSmall ? 16 : 20),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFAF5),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFFFF1E6)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 15)],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: const Color(0xFFFFEBD6), borderRadius: BorderRadius.circular(16)),
                child: const Icon(Icons.shopping_bag_rounded, color: Color(0xFFF97316), size: 32),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Order Drink', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF0D3B30))),
                    Text('Get premium liquor delivered to your door', style: TextStyle(color: Colors.black54, fontSize: 12, fontWeight: FontWeight.w500)),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: isSmall ? 12 : 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildBadge(Icons.bolt_rounded, 'Fast Delivery'),
              _buildBadge(Icons.verified_user_rounded, '100% Secure'),
              _buildBadge(Icons.workspace_premium_rounded, 'Top Quality'),
            ],
          ),
          SizedBox(height: isSmall ? 16 : 20),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SignupScreen(role: 'customer'))),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF97316),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Sign Up as Customer', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14)),
                  SizedBox(width: 8),
                  Icon(Icons.arrow_forward_rounded, size: 18),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRiderCard(BuildContext context, bool isSmall) {
    return Container(
      padding: EdgeInsets.all(isSmall ? 16 : 20),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F9F8),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE8F3F1)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 15)],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: const Color(0xFFDCECE9), borderRadius: BorderRadius.circular(16)),
                child: const Icon(Icons.motorcycle_rounded, color: Color(0xFF0D3B30), size: 32),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Deliver & Earn', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF0D3B30))),
                    Text('Earn money delivering premium liquor', style: TextStyle(color: Colors.black54, fontSize: 12, fontWeight: FontWeight.w500)),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: isSmall ? 12 : 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildBadge(Icons.payments_rounded, 'Great Earnings', color: Color(0xFF0D3B30)),
              _buildBadge(Icons.access_time_filled_rounded, 'Flexible Hours', color: Color(0xFF0D3B30)),
              _buildBadge(Icons.card_giftcard_rounded, 'Weekly Payouts', color: Color(0xFF0D3B30)),
            ],
          ),
          SizedBox(height: isSmall ? 16 : 20),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SignupScreen(role: 'rider'))),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0D3B30),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Apply as Rider', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14)),
                  SizedBox(width: 8),
                  Icon(Icons.arrow_forward_rounded, size: 18),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBadge(IconData icon, String text, {Color color = const Color(0xFFF97316)}) {
    return Row(
      children: [
        Icon(icon, size: 12, color: color),
        const SizedBox(width: 4),
        Text(text, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: Colors.black87)),
      ],
    );
  }

  Widget _buildTrustIndicators(bool isSmall) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildTrustItem(Icons.verified_rounded, 'Safe & Secure', isSmall),
        _buildTrustItem(Icons.headset_mic_rounded, '24/7 Support', isSmall),
        _buildTrustItem(Icons.workspace_premium_rounded, 'Trusted Service', isSmall),
      ],
    );
  }

  Widget _buildTrustItem(IconData icon, String title, bool isSmall) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: const Color(0xFFF1F5F9), shape: BoxShape.circle),
          child: Icon(icon, size: 16, color: const Color(0xFF0D3B30)),
        ),
        const SizedBox(height: 6),
        Text(title, textAlign: TextAlign.center, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Color(0xFF0D3B30))),
      ],
    );
  }

  Widget _buildFooter(BuildContext context) {
    return Column(
      children: [
        const Text(
          'Already have an account?',
          style: TextStyle(color: Colors.grey, fontSize: 13, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 4),
        GestureDetector(
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LoginScreen())),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Sign In',
                style: TextStyle(color: Color(0xFF0D3B30), fontSize: 15, fontWeight: FontWeight.w900, decoration: TextDecoration.underline),
              ),
              SizedBox(width: 4),
              Icon(Icons.arrow_forward_rounded, color: Color(0xFF0D3B30), size: 16),
            ],
          ),
        ),
      ],
    );
  }
}
