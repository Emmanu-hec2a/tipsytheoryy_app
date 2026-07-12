import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../core/theme.dart';
import '../customer/customer_shell.dart';
import '../rider/rider_shell.dart';
import 'login_screen.dart';

class SignupScreen extends StatefulWidget {
  final String role; // 'customer' or 'rider'
  const SignupScreen({super.key, required this.role});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _dobController = TextEditingController();
  
  // Silent Sentry Logic
  DateTime? _selectedDob;
  DateTime? _pickerStartTime;
  int _pickerInteractionMs = 0;

  // Controllers for rider-specific fields
  final _regController = TextEditingController();
  final _licenseController = TextEditingController();
  final _bankController = TextEditingController();
  
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  String? _selectedLocation;
  String? _selectedVehicleType;

  final List<String> _locations = ['Westlands', 'Kilimani', 'Karen', 'Lavington', 'Runda'];
  final List<String> _vehicleTypes = ['Motorcycle', 'Bicycle', 'Car'];

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _regController.dispose();
    _licenseController.dispose();
    _bankController.dispose();
    super.dispose();
  }

  Future<void> _handleSignup() async {
    if (!_formKey.currentState!.validate()) return;
    
    if (_passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Passwords do not match')),
      );
      return;
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final success = await authProvider.signup(
      email: _emailController.text.trim(),
      password: _passwordController.text,
      fullName: _nameController.text.trim(),
      phone: _phoneController.text.trim(),
      role: widget.role,
      dob: _selectedDob?.toIso8601String().split('T')[0],
      metadata: {
        'picker_interaction_ms': _pickerInteractionMs,
        'signup_duration_ms': DateTime.now().difference(_pickerStartTime ?? DateTime.now()).inMilliseconds,
      },
    );

    if (success && mounted) {
      if (widget.role == 'rider') {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const RiderShell()),
          (route) => false,
        );
      } else {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const CustomerShell()),
          (route) => false,
        );
      }
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(authProvider.errorMessage ?? 'Signup failed')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isRider = widget.role == 'rider';
    final authProvider = Provider.of<AuthProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header Section
            Container(
              width: double.infinity,
              padding: const EdgeInsets.only(bottom: 30),
              decoration: const BoxDecoration(
                color: AppTheme.primaryColor,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(40),
                  bottomRight: Radius.circular(40),
                ),
              ),
              child: SafeArea(
                child: Column(
                  children: [
                    const SizedBox(height: 10),
                    const Icon(Icons.wine_bar_rounded, size: 50, color: Colors.white),
                    const SizedBox(height: 15),
                    Text(
                      isRider ? 'Become a Rider' : 'Create Your Account',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 5),
                    const Text(
                      'Join thousands enjoying premium\nliquor delivery',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                  ],
                ),
              ),
            ),

            // Form Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 20),
                    _buildLabel('Full Name', isDark),
                    TextFormField(
                      controller: _nameController,
                      style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                      decoration: InputDecoration(
                        hintText: 'Enter your full name',
                        hintStyle: TextStyle(color: isDark ? Colors.white24 : null),
                        fillColor: isDark ? Colors.white.withValues(alpha: 0.05) : null,
                        prefixIcon: Icon(Icons.person_outline, size: 20, color: isDark ? Colors.white38 : null),
                      ),
                      validator: (val) => val == null || val.isEmpty ? 'Required' : null,
                    ),
                    
                    const SizedBox(height: 12),
                    _buildLabel('Email Address', isDark),
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                      decoration: InputDecoration(
                        hintText: 'Enter your email address',
                        hintStyle: TextStyle(color: isDark ? Colors.white24 : null),
                        fillColor: isDark ? Colors.white.withValues(alpha: 0.05) : null,
                        prefixIcon: Icon(Icons.email_outlined, size: 20, color: isDark ? Colors.white38 : null),
                      ),
                      validator: (val) => val == null || val.isEmpty ? 'Required' : null,
                    ),
                    
                    const SizedBox(height: 12),
                    _buildLabel('Phone Number', isDark),
                    TextFormField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                      decoration: InputDecoration(
                        hintText: 'Enter your phone number',
                        hintStyle: TextStyle(color: isDark ? Colors.white24 : null),
                        fillColor: isDark ? Colors.white.withValues(alpha: 0.05) : null,
                        prefixIcon: Icon(Icons.phone_outlined, size: 20, color: isDark ? Colors.white38 : null),
                        prefix: Container(
                          padding: const EdgeInsets.only(right: 8),
                          child: Text('+254', style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.white70 : Colors.black)),
                        ),
                      ),
                      validator: (val) => val == null || val.isEmpty ? 'Required' : null,
                    ),
                    
                    const SizedBox(height: 12),
                    _buildLabel('Password', isDark),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                      decoration: InputDecoration(
                        hintText: 'Create a password',
                        hintStyle: TextStyle(color: isDark ? Colors.white24 : null),
                        fillColor: isDark ? Colors.white.withValues(alpha: 0.05) : null,
                        prefixIcon: Icon(Icons.lock_outline, size: 20, color: isDark ? Colors.white38 : null),
                        suffixIcon: IconButton(
                          icon: Icon(_obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 20, color: isDark ? Colors.white38 : null),
                          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                        ),
                      ),
                      validator: (val) => val == null || val.length < 8 ? 'Min 8 characters' : null,
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 4, left: 4),
                      child: Text(
                        'At least 8 characters with a number and symbol',
                        style: TextStyle(fontSize: 11, color: isDark ? Colors.white24 : Colors.grey),
                      ),
                    ),
                    
                    const SizedBox(height: 12),
                    _buildLabel('Confirm Password', isDark),
                    TextFormField(
                      controller: _confirmPasswordController,
                      obscureText: _obscureConfirmPassword,
                      style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                      decoration: InputDecoration(
                        hintText: 'Confirm your password',
                        hintStyle: TextStyle(color: isDark ? Colors.white24 : null),
                        fillColor: isDark ? Colors.white.withValues(alpha: 0.05) : null,
                        prefixIcon: Icon(Icons.lock_outline, size: 20, color: isDark ? Colors.white38 : null),
                        suffixIcon: IconButton(
                          icon: Icon(_obscureConfirmPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 20, color: isDark ? Colors.white38 : null),
                          onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                        ),
                      ),
                      validator: (val) => val == null || val.isEmpty ? 'Required' : null,
                    ),
                    
                    const SizedBox(height: 12),
                    _buildLabel('Quick check to continue', isDark),
                    GestureDetector(
                      onTap: () => _showDobPicker(context, isDark),
                      child: AbsorbPointer(
                        child: TextFormField(
                          controller: _dobController,
                          style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                          decoration: InputDecoration(
                            hintText: 'Date of Birth',
                            hintStyle: TextStyle(color: isDark ? Colors.white24 : null),
                            fillColor: isDark ? Colors.white.withValues(alpha: 0.05) : null,
                            prefixIcon: Icon(Icons.cake_outlined, size: 20, color: isDark ? Colors.white38 : null),
                          ),
                          validator: (val) {
                            if (val == null || val.isEmpty) return 'Required';
                            if (_selectedDob != null) {
                              final age = DateTime.now().year - _selectedDob!.year;
                              if (age < 18) return 'Must be 18+ to join';
                            }
                            return null;
                          },
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 4, left: 4),
                      child: Text(
                        'Secure & private. Used only for age confirmation.',
                        style: TextStyle(fontSize: 11, color: isDark ? Colors.white24 : Colors.grey),
                      ),
                    ),
                    
                    if (!isRider) ...[
                      const SizedBox(height: 12),
                      _buildLabel('Location', isDark),
                      DropdownButtonFormField<String>(
                        value: _selectedLocation,
                        dropdownColor: isDark ? Theme.of(context).cardColor : Colors.white,
                        style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                        decoration: InputDecoration(
                          prefixIcon: Icon(Icons.location_on_outlined, size: 20, color: isDark ? Colors.white38 : null),
                          hintText: 'Select your area',
                          hintStyle: TextStyle(color: isDark ? Colors.white24 : null),
                          fillColor: isDark ? Colors.white.withValues(alpha: 0.05) : null,
                        ),
                        items: _locations.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                        onChanged: (val) => setState(() => _selectedLocation = val),
                        validator: (val) => val == null ? 'Required' : null,
                      ),
                    ],

                    if (isRider) ...[
                      const SizedBox(height: 12),
                      _buildLabel('Vehicle Type', isDark),
                      DropdownButtonFormField<String>(
                        value: _selectedVehicleType,
                        dropdownColor: isDark ? Theme.of(context).cardColor : Colors.white,
                        style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                        decoration: InputDecoration(
                          prefixIcon: Icon(Icons.motorcycle_outlined, size: 20, color: isDark ? Colors.white38 : null),
                          hintText: 'Select vehicle type',
                          hintStyle: TextStyle(color: isDark ? Colors.white24 : null),
                          fillColor: isDark ? Colors.white.withValues(alpha: 0.05) : null,
                        ),
                        items: _vehicleTypes.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                        onChanged: (val) => setState(() => _selectedVehicleType = val),
                        validator: (val) => val == null ? 'Required' : null,
                      ),
                      
                      const SizedBox(height: 12),
                      _buildLabel('Vehicle Registration', isDark),
                      TextFormField(
                        controller: _regController,
                        style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                        decoration: InputDecoration(
                          hintText: 'Registration number',
                          hintStyle: TextStyle(color: isDark ? Colors.white24 : null),
                          fillColor: isDark ? Colors.white.withValues(alpha: 0.05) : null,
                          prefixIcon: Icon(Icons.app_registration, size: 20, color: isDark ? Colors.white38 : null),
                        ),
                        validator: (val) => val == null || val.isEmpty ? 'Required' : null,
                      ),
                    ],

                    const SizedBox(height: 32),
                    
                    SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: ElevatedButton(
                        onPressed: authProvider.status == AuthStatus.authenticating ? null : _handleSignup,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryColor,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: authProvider.status == AuthStatus.authenticating 
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text(
                              'CREATE ACCOUNT',
                              style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1),
                            ),
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    Center(
                      child: GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: RichText(
                          text: TextSpan(
                            style: TextStyle(color: isDark ? Colors.white38 : Colors.black54, fontSize: 14),
                            children: [
                              const TextSpan(text: 'Already have an account? '),
                              TextSpan(
                                text: 'Sign In',
                                style: TextStyle(
                                  color: isDark ? AppTheme.accentColor : AppTheme.primaryColor,
                                  fontWeight: FontWeight.bold,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String text, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(text, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: isDark ? Colors.white70 : Colors.black87)),
    );
  }

  void _showDobPicker(BuildContext context, bool isDark) async {
    _pickerStartTime = DateTime.now();
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime(2000),
      firstDate: DateTime(1920),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.dark(
              primary: AppTheme.accentColor,
              onPrimary: Colors.white,
              surface: isDark ? const Color(0xFF1E293B) : Colors.white,
              onSurface: isDark ? Colors.white : Colors.black,
            ),
            dialogBackgroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _selectedDob) {
      setState(() {
        _selectedDob = picked;
        _dobController.text = "${picked.day}/${picked.month}/${picked.year}";
        _pickerInteractionMs = DateTime.now().difference(_pickerStartTime!).inMilliseconds;
      });
    }
  }
}
