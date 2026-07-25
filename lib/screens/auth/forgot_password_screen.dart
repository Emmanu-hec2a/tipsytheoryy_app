import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pinput/pinput.dart';
import 'dart:async';
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
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  
  // Resend Timer State
  int _resendSeconds = 60;
  Timer? _timer;

  @override
  void dispose() {
    _emailController.dispose();
    _otpController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _pageController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    setState(() => _resendSeconds = 60);
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_resendSeconds > 0) {
        setState(() => _resendSeconds--);
      } else {
        _timer?.cancel();
      }
    });
  }

  void _nextPage() {
    _pageController.nextPage(duration: const Duration(milliseconds: 500), curve: Curves.easeInOut);
    setState(() => _currentPage++);
  }

  void _prevPage() {
    _pageController.previousPage(duration: const Duration(milliseconds: 500), curve: Curves.easeInOut);
    setState(() => _currentPage--);
  }

  Future<void> _handleRequest() async {
    if (_emailController.text.isEmpty) return;
    
    setState(() => _isLoading = true);
    final success = await Provider.of<AuthProvider>(context, listen: false).requestPasswordReset(_emailController.text);
    setState(() => _isLoading = false);

    if (success && mounted) {
      _startTimer();
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
    if (pin.length == 6) {
      // For UX flow according to mocks, verification leads to new password screen
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
      _nextPage(); // Move to Success Screen
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(Provider.of<AuthProvider>(context, listen: false).errorMessage ?? 'Reset failed'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  // Password Validation Logic
  bool get _hasMinLength => _passwordController.text.length >= 8;
  bool get _hasUppercase => _passwordController.text.contains(RegExp(r'[A-Z]'));
  bool get _hasNumber => _passwordController.text.contains(RegExp(r'[0-9]'));
  bool get _hasSpecial => _passwordController.text.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'));

  double get _passwordStrength {
    double strength = 0;
    if (_hasMinLength) strength += 0.25;
    if (_hasUppercase) strength += 0.25;
    if (_hasNumber) strength += 0.25;
    if (_hasSpecial) strength += 0.25;
    return strength;
  }

  String get _strengthText {
    if (_passwordStrength == 0) return 'Very Weak';
    if (_passwordStrength <= 0.25) return 'Weak';
    if (_passwordStrength <= 0.5) return 'Fair';
    if (_passwordStrength <= 0.75) return 'Good';
    return 'Strong';
  }

  Color get _strengthColor {
    if (_passwordStrength <= 0.25) return Colors.red;
    if (_passwordStrength <= 0.5) return Colors.orange;
    if (_passwordStrength <= 0.75) return Colors.yellow.shade700;
    return Colors.green;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: AppTheme.primaryColor,
      body: Column(
        children: [
          // Header Section
          Container(
            width: double.infinity,
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 20,
              bottom: 40,
              left: 24,
              right: 24,
            ),
            child: Column(
              children: [
                if (_currentPage > 0 && _currentPage < 3) 
                  Align(
                    alignment: Alignment.centerLeft,
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
                      onPressed: _prevPage,
                    ),
                  ),
                const SizedBox(height: 10),
                Text(
                  _getHeaderTitle(),
                  style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 10),
                Text(
                  _getHeaderSubtitle(),
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 14, fontWeight: FontWeight.w500),
                ),
                if (_currentPage == 1) ...[
                   const SizedBox(height: 15),
                   Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _maskEmail(_emailController.text),
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: _prevPage,
                        child: const Icon(Icons.edit_outlined, color: Colors.white, size: 16),
                      ),
                    ],
                   ),
                ],
              ],
            ),
          ),
          
          // White Body Content
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: isDark ? AppTheme.darkBackground : Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(40)),
              ),
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _buildRequestStep(isDark),
                  _buildVerifyStep(isDark),
                  _buildResetStep(isDark),
                  _buildSuccessStep(isDark),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getHeaderTitle() {
    switch (_currentPage) {
      case 0: return 'Forgot Password?';
      case 1: return 'Verify Your Email';
      case 2: return 'Create New Password';
      default: return '';
    }
  }

  String _getHeaderSubtitle() {
    switch (_currentPage) {
      case 0: return 'No worries, we\'ll help you regain access to your account.';
      case 1: return 'Enter the 6-digit code we sent to your email';
      case 2: return 'Choose a strong password to secure your account.';
      default: return '';
    }
  }

  String _maskEmail(String email) {
    if (email.isEmpty || !email.contains('@')) return email;
    final parts = email.split('@');
    final name = parts[0];
    if (name.length <= 3) return email;
    return '${name.substring(0, 4)}***@${parts[1]}';
  }

  Widget _buildRequestStep(bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTextField('Email Address', _emailController, Icons.email_outlined, isDark, hint: 'Enter your email address'),
          const SizedBox(height: 10),
          Text(
            'We\'ll send you a verification code to reset your password.',
            style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
          ),
          const SizedBox(height: 40),
          _buildButton('Send Code', _handleRequest),
          const SizedBox(height: 20),
          Center(
            child: TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Back to Login', style: TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.w900)),
            ),
          ),
          const SizedBox(height: 40),
          Center(
            child: Column(
              children: [
                Icon(Icons.mark_email_read_rounded, size: 80, color: Colors.grey.shade200),
                const SizedBox(height: 16),
                Text(
                  'Your account is secure. We never share your information.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey.shade400, fontSize: 11),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVerifyStep(bool isDark) {
    final defaultPinTheme = PinTheme(
      width: 50,
      height: 60,
      textStyle: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: isDark ? Colors.white : AppTheme.primaryColor),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.primaryColor.withValues(alpha: 0.2)),
      ),
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        children: [
          Pinput(
            length: 6,
            controller: _otpController,
            defaultPinTheme: defaultPinTheme,
            focusedPinTheme: defaultPinTheme.copyDecorationWith(
              border: Border.all(color: AppTheme.primaryColor, width: 2),
            ),
            onCompleted: _handleVerifyOTP,
          ),
          const SizedBox(height: 30),
          const Text('Didn\'t receive the code?', style: TextStyle(color: Colors.grey, fontSize: 13, fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          _resendSeconds > 0 
            ? Column(
                children: [
                  Text('Resend Code', style: TextStyle(color: Colors.grey.shade400, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text('Resend available in $_resendSeconds seconds', style: TextStyle(color: Colors.grey.shade400, fontSize: 11)),
                ],
              )
            : TextButton(
                onPressed: _handleRequest,
                child: const Text('Resend Code', style: TextStyle(color: AppTheme.accentColor, fontWeight: FontWeight.w900)),
              ),
          const SizedBox(height: 40),
          const Divider(),
          const SizedBox(height: 20),
          _buildInfoRow(Icons.access_time_rounded, 'Code expires in 15 minutes.'),
          const SizedBox(height: 16),
          _buildInfoRow(Icons.mail_outline_rounded, 'Check your spam folder if you don\'t see the email.'),
          const SizedBox(height: 40),
          _buildButton('Verify Code', () => _handleVerifyOTP(_otpController.text)),
          const SizedBox(height: 20),
          TextButton(
            onPressed: _prevPage,
            child: const Text('Change Email', style: TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.w900)),
          ),
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
          _buildTextField(
            'New Password', 
            _passwordController, 
            Icons.lock_outline_rounded, 
            isDark, 
            isPassword: true,
            obscureText: _obscurePassword,
            onObscureTap: () => setState(() => _obscurePassword = !_obscurePassword),
            onChanged: (val) => setState(() {}),
            hint: 'Enter new password'
          ),
          const SizedBox(height: 12),
          Text('Password Strength', style: TextStyle(color: Colors.grey.shade500, fontSize: 11, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: _passwordStrength,
              backgroundColor: Colors.grey.shade100,
              valueColor: AlwaysStoppedAnimation<Color>(_strengthColor),
              minHeight: 6,
            ),
          ),
          const SizedBox(height: 6),
          Text(_strengthText, style: TextStyle(color: _strengthColor, fontSize: 12, fontWeight: FontWeight.w900)),
          const SizedBox(height: 20),
          _buildCheckItem('At least 8 characters', _hasMinLength),
          _buildCheckItem('Contains uppercase letter', _hasUppercase),
          _buildCheckItem('Contains number', _hasNumber),
          _buildCheckItem('Contains special character', _hasSpecial),
          const SizedBox(height: 30),
          _buildTextField(
            'Confirm Password', 
            _confirmPasswordController, 
            Icons.lock_outline_rounded, 
            isDark, 
            isPassword: true,
            obscureText: _obscureConfirmPassword,
            onObscureTap: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
            hint: 'Confirm new password'
          ),
          const SizedBox(height: 40),
          _buildButton('Reset Password', _handleReset),
          const SizedBox(height: 20),
          Center(
            child: TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Back to Login', style: TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.w900)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessStep(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(32),
      width: double.infinity,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppTheme.accentColor,
              boxShadow: [
                BoxShadow(color: AppTheme.accentColor.withValues(alpha: 0.3), blurRadius: 30, spreadRadius: 10),
              ],
            ),
            child: const Icon(Icons.check_rounded, size: 60, color: Colors.white),
          ),
          const SizedBox(height: 40),
          const Text(
            'Password Reset Successful!',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: AppTheme.primaryColor),
          ),
          const SizedBox(height: 16),
          Text(
            'Your password has been successfully updated.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade500, fontSize: 14, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          Text(
            'You can now log in with your new password.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
          ),
          const SizedBox(height: 60),
          _buildButton('Back to Login', () => Navigator.pop(context)),
          const SizedBox(height: 40),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.verified_user_rounded, color: AppTheme.primaryColor, size: 18),
              const SizedBox(width: 8),
              Text(
                'Keep your password secure and\ndon\'t share it with anyone.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade400, fontSize: 11),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppTheme.accentColor),
        const SizedBox(width: 12),
        Expanded(child: Text(text, style: TextStyle(color: Colors.grey.shade600, fontSize: 12, fontWeight: FontWeight.w500))),
      ],
    );
  }

  Widget _buildCheckItem(String text, bool isDone) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(
            isDone ? Icons.check_circle_rounded : Icons.circle_outlined, 
            size: 18, 
            color: isDone ? Colors.green : Colors.grey.shade300
          ),
          const SizedBox(width: 10),
          Text(
            text, 
            style: TextStyle(
              fontSize: 12, 
              color: isDone ? Colors.green.shade700 : Colors.grey.shade500,
              fontWeight: isDone ? FontWeight.bold : FontWeight.normal
            )
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(
    String label, 
    TextEditingController controller, 
    IconData icon, 
    bool isDark, 
    {
      bool isPassword = false, 
      String? hint, 
      bool obscureText = false, 
      VoidCallback? onObscureTap,
      Function(String)? onChanged,
    }
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(), 
          style: TextStyle(
            fontSize: 10, 
            fontWeight: FontWeight.w900, 
            letterSpacing: 1.5, 
            color: isDark ? AppTheme.accentColor : AppTheme.primaryColor
          )
        ),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.grey.shade200),
            boxShadow: isDark ? [] : [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4))],
          ),
          child: TextField(
            controller: controller,
            obscureText: isPassword && !obscureText,
            onChanged: onChanged,
            style: TextStyle(
              color: isDark ? Colors.white : Colors.black87, 
              fontWeight: FontWeight.w600,
              fontSize: 15,
            ),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(color: isDark ? Colors.white24 : Colors.grey.shade300, fontSize: 14),
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
              border: InputBorder.none,
              prefixIcon: Icon(icon, color: isDark ? Colors.white38 : Colors.grey.shade400, size: 20),
              suffixIcon: isPassword ? IconButton(
                icon: Icon(
                  obscureText ? Icons.visibility_rounded : Icons.visibility_off_rounded, 
                  color: isDark ? Colors.white38 : Colors.grey.shade400, 
                  size: 20
                ),
                onPressed: onObscureTap,
              ) : null,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildButton(String text, VoidCallback onPressed) {
    return SizedBox(
      width: double.infinity,
      height: 55,
      child: ElevatedButton(
        onPressed: _isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.accentColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 0,
        ),
        child: _isLoading 
          ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
          : Text(text, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
      ),
    );
  }
}
