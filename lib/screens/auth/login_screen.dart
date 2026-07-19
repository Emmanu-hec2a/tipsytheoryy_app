import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../core/theme.dart';
import '../../providers/auth_provider.dart';
import '../customer/customer_shell.dart';
import '../rider/rider_shell.dart';
import 'signup_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _rememberMe = false;

  final String googleSvg = '''
<svg xmlns="http://www.w3.org/2000/svg" height="24" viewBox="0 0 24 24" width="24"><path d="M22.56 12.25c0-.78-.07-1.53-.2-2.25H12v4.26h5.92c-.26 1.37-1.04 2.53-2.21 3.31v2.77h3.57c2.08-1.92 3.28-4.74 3.28-8.09z" fill="#4285F4"/><path d="M12 23c2.97 0 5.46-.98 7.28-2.66l-3.57-2.77c-.98.66-2.23 1.06-3.71 1.06-2.86 0-5.29-1.93-6.16-4.53H2.18v2.84C3.99 20.53 7.7 23 12 23z" fill="#34A853"/><path d="M5.84 14.09c-.22-.66-.35-1.36-.35-2.09s.13-1.43.35-2.09V7.07H2.18C1.43 8.55 1 10.22 1 12s.43 3.45 1.18 4.93l2.85-2.22.81-.62z" fill="#FBBC05"/><path d="M12 5.38c1.62 0 3.06.56 4.21 1.66l3.15-3.15C17.45 2.09 14.97 1 12 1 7.7 1 3.99 3.47 2.18 7.07l3.66 2.84c.87-2.6 3.3-4.53 6.16-4.53z" fill="#EA4335"/><path d="M1 1h22v22H1z" fill="none"/></svg>
''';

  Future<void> _handleLogin() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    final success = await authProvider.login(
      _phoneController.text, 
      _passwordController.text,
    );

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
        SnackBar(content: Text(authProvider.errorMessage ?? 'Login Failed')),
      );
    }
  }

  Future<void> _handleGoogleSignIn() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final success = await authProvider.signInWithGoogle();
    _handleSocialResult(success);
  }

  Future<void> _handleAppleSignIn() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final success = await authProvider.signInWithApple();
    _handleSocialResult(success);
  }

  void _handleSocialResult(bool success) {
    if (success && mounted) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      Widget nextShell = authProvider.role == 'rider' 
        ? const RiderShell() 
        : const CustomerShell();
        
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => nextShell),
        (route) => false,
      );
    } else if (mounted) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      if (authProvider.status == AuthStatus.failed) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(authProvider.errorMessage ?? 'Authentication Failed')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Curved Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.only(bottom: 40),
              decoration: const BoxDecoration(
                color: AppTheme.primaryColor,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(40),
                  bottomRight: Radius.circular(40),
                ),
              ),
              child: const SafeArea(
                child: Column(
                  children: [
                    SizedBox(height: 20),
                    Icon(Icons.wine_bar_rounded, size: 60, color: Colors.white),
                    SizedBox(height: 15),
                    Text(
                      'Welcome Back',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Sign in to continue your journey',
                      style: TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildLabel('Phone Number', isDark),
                  TextField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                    decoration: InputDecoration(
                      prefixIcon: Icon(Icons.phone_outlined, size: 20, color: isDark ? Colors.white38 : null),
                      hintText: 'Enter your phone number',
                      hintStyle: TextStyle(color: isDark ? Colors.white24 : null),
                      fillColor: isDark ? Colors.white.withValues(alpha: 0.05) : null,
                      prefix: Container(
                        padding: const EdgeInsets.only(right: 8),
                        child: Text('+254', style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.white70 : Colors.black)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildLabel('Password', isDark),
                  TextField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                    decoration: InputDecoration(
                      hintText: 'Enter your password',
                      hintStyle: TextStyle(color: isDark ? Colors.white24 : null),
                      fillColor: isDark ? Colors.white.withValues(alpha: 0.05) : null,
                      prefixIcon: Icon(Icons.lock_outline, size: 20, color: isDark ? Colors.white38 : null),
                      suffixIcon: IconButton(
                        icon: Icon(_obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 20, color: isDark ? Colors.white38 : null),
                        onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          SizedBox(
                            height: 24,
                            width: 24,
                            child: Checkbox(
                              value: _rememberMe,
                              onChanged: (val) => setState(() => _rememberMe = val!),
                              activeColor: AppTheme.accentColor,
                              side: isDark ? const BorderSide(color: Colors.white24) : null,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text('Remember Me', style: TextStyle(fontSize: 13, color: isDark ? Colors.white38 : Colors.black54)),
                        ],
                      ),
                      TextButton(
                        onPressed: () {},
                        child: Text('Forgot Password?', 
                          style: TextStyle(color: isDark ? AppTheme.accentColor : AppTheme.primaryColor, fontWeight: FontWeight.bold, fontSize: 13)
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: Consumer<AuthProvider>(
                      builder: (context, auth, _) {
                        return ElevatedButton(
                          onPressed: auth.status == AuthStatus.authenticating ? null : _handleLogin,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryColor,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: auth.status == AuthStatus.authenticating
                              ? const CircularProgressIndicator(color: Colors.white)
                              : const Text('SIGN IN', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1)),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Don\'t have an account? ', style: TextStyle(color: isDark ? Colors.white38 : Colors.black54)),
                      GestureDetector(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const SignupScreen(role: 'customer')),
                        ),
                        child: const Text(
                          'Sign Up',
                          style: TextStyle(
                            color: AppTheme.accentColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  Row(
                    children: [
                      Expanded(child: Divider(color: isDark ? Colors.white10 : null)),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text('OR', style: TextStyle(color: isDark ? Colors.white10 : Colors.grey, fontWeight: FontWeight.bold)),
                      ),
                      Expanded(child: Divider(color: isDark ? Colors.white10 : null)),
                    ],
                  ),
                  const SizedBox(height: 32),
                  _buildSocialButton(
                    'Continue with Google',
                    SvgPicture.string(googleSvg, height: 22),
                    isDark ? Colors.white70 : Colors.black87,
                    isDark,
                    _handleGoogleSignIn,
                  ),
                  const SizedBox(height: 12),
                  _buildSocialButton(
                    'Continue with Apple',
                    Icon(Icons.apple, size: 24, color: isDark ? Colors.white70 : Colors.black),
                    isDark ? Colors.white70 : Colors.black87,
                    isDark,
                    _handleAppleSignIn,
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String text, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(text, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: isDark ? Colors.white70 : Colors.black87)),
    );
  }

  Widget _buildSocialButton(String text, Widget icon, Color color, bool isDark, VoidCallback onPressed) {
    return SizedBox(
      width: double.infinity,
      height: 55,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: icon,
        label: Text(text, style: TextStyle(color: color, fontWeight: FontWeight.bold)),
        style: OutlinedButton.styleFrom(
          backgroundColor: isDark ? Colors.white.withValues(alpha: 0.05) : null,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          side: BorderSide(color: isDark ? Colors.white10 : Colors.grey.shade300),
        ),
      ),
    );
  }
}
