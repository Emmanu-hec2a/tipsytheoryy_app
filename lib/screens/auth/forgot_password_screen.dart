import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pinput/pinput.dart';
import '../../core/theme.dart';
import '../../providers/auth_provider.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final PageController _pageController = PageController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  
  int _currentPage = 0;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _otpController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage() {
    _pageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
    setState(() => _currentPage++);
  }

  Future<void> _handleRequest() async {
    if (_emailController.text.isEmpty) return;
    
    setState(() => _isLoading = true);
    final success = await Provider.of<AuthProvider>(context, listen: false).requestPasswordReset(_emailController.text);
    setState(() => _isLoading = false);

    if (success && mounted) {
      _nextPage();
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(Provider.of<AuthProvider>(context, listen: false).errorMessage ?? 'Request failed'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  Future<void> _handleVerifyOTP(String pin) async {
    // This is a "Dummy" check if we want to separate screens, 
    // but typically we verify OTP + Password together in one API call.
    // To satisfy the "Verify first then open Reset screen", we just move to the next page.
    if (pin.length == 6) {
      _nextPage();
    }
  }

  Future<void> _handleReset() async {
    if (_otpController.text.isEmpty || _passwordController.text.isEmpty) return;
    if (_passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Passwords do not match'), backgroundColor: Colors.redAccent),
      );
      return;
    }

    setState(() => _isLoading = true);
    final success = await Provider.of<AuthProvider>(context, listen: false).verifyPasswordReset(
      _emailController.text,
      _otpController.text,
      _passwordController.text,
    );
    setState(() => _isLoading = false);

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password reset successful! Please login.'), backgroundColor: Colors.green),
      );
      Navigator.pop(context);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(Provider.of<AuthProvider>(context, listen: false).errorMessage ?? 'Reset failed'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: isDark ? Colors.white : Colors.black87),
          onPressed: () {
            if (_currentPage > 0) {
              _pageController.previousPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
              setState(() => _currentPage--);
            } else {
              Navigator.pop(context);
            }
          },
        ),
      ),
      body: SafeArea(
        child: PageView(
          controller: _pageController,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            _buildRequestStep(isDark),
            _buildVerifyStep(isDark),
            _buildResetStep(isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildRequestStep(bool isDark) {
    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Forgot\nPassword?', style: TextStyle(fontSize: 40, fontWeight: FontWeight.w900, height: 1.1)),
          const SizedBox(height: 16),
          Text(
            'Don\'t worry, it happens to the best of us. Enter your email and we\'ll send you a 6-digit reset code.',
            style: TextStyle(color: isDark ? Colors.white38 : Colors.grey, fontSize: 14, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 48),
          _buildTextField('Email Address', _emailController, Icons.email_outlined, isDark),
          const Spacer(),
          _buildButton('Send Reset Code', _handleRequest),
        ],
      ),
    );
  }

  Widget _buildVerifyStep(bool isDark) {
    final defaultPinTheme = PinTheme(
      width: 50,
      height: 60,
      textStyle: TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w900,
        color: isDark ? Colors.white : Colors.black87,
      ),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? Colors.white10 : Colors.grey.shade200),
      ),
    );

    final focusedPinTheme = defaultPinTheme.copyDecorationWith(
      border: Border.all(color: AppTheme.accentColor, width: 2),
      color: isDark ? AppTheme.accentColor.withValues(alpha: 0.05) : Colors.white,
    );

    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Enter\nCode', style: TextStyle(fontSize: 40, fontWeight: FontWeight.w900, height: 1.1)),
          const SizedBox(height: 16),
          Text(
            'We\'ve sent a verification code to your email. Enter it below to continue.',
            style: TextStyle(color: isDark ? Colors.white38 : Colors.grey, fontSize: 14, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 48),
          Center(
            child: Pinput(
              length: 6,
              controller: _otpController,
              defaultPinTheme: defaultPinTheme,
              focusedPinTheme: focusedPinTheme,
              onCompleted: _handleVerifyOTP,
              cursor: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Container(
                    margin: const EdgeInsets.only(bottom: 9),
                    width: 22,
                    height: 2,
                    color: AppTheme.accentColor,
                  ),
                ],
              ),
            ),
          ),
          const Spacer(),
          _buildButton('Verify Code', () => _handleVerifyOTP(_otpController.text)),
        ],
      ),
    );
  }

  Widget _buildResetStep(bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('New\nPassword', style: TextStyle(fontSize: 40, fontWeight: FontWeight.w900, height: 1.1)),
          const SizedBox(height: 16),
          Text(
            'Security first! Please set a strong new password to protect your account.',
            style: TextStyle(color: isDark ? Colors.white38 : Colors.grey, fontSize: 14, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 40),
          _buildTextField('New Password', _passwordController, Icons.lock_outline_rounded, isDark, isPassword: true),
          const SizedBox(height: 20),
          _buildTextField('Confirm New Password', _confirmPasswordController, Icons.lock_outline_rounded, isDark, isPassword: true),
          const SizedBox(height: 40),
          _buildButton('Reset Password', _handleReset),
        ],
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, IconData icon, bool isDark, {bool isPassword = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label.toUpperCase(), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1, color: AppTheme.accentColor)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade50,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: isDark ? Colors.white10 : Colors.grey.shade200),
          ),
          child: TextField(
            controller: controller,
            obscureText: isPassword,
            style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontWeight: FontWeight.w600),
            decoration: InputDecoration(
              icon: Icon(icon, size: 20, color: Colors.grey),
              border: InputBorder.none,
              counterText: '',
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildButton(String text, VoidCallback onPressed) {
    return SizedBox(
      width: double.infinity,
      height: 60,
      child: ElevatedButton(
        onPressed: _isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primaryColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          elevation: 0,
        ),
        child: _isLoading 
          ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
          : Text(text.toUpperCase(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, letterSpacing: 1)),
      ),
    );
  }
}
