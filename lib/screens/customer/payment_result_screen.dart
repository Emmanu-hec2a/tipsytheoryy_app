import 'package:flutter/material.dart';
import '../../core/theme.dart';

class PaymentResultScreen extends StatelessWidget {
  final bool isSuccess;
  final String title;
  final String message;
  final VoidCallback? onRetry;
  final VoidCallback? onGoHome;

  const PaymentResultScreen({
    super.key,
    required this.isSuccess,
    required this.title,
    required this.message,
    this.onRetry,
    this.onGoHome,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: isDark ? Theme.of(context).cardColor : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: isDark ? [] : [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 12)],
                ),
                child: Column(
                  children: [
                    Icon(
                      isSuccess ? Icons.check_circle_outline : Icons.error_outline,
                      size: 72,
                      color: isSuccess ? AppTheme.accentColor : Colors.redAccent,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      title,
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: isDark ? Colors.white : Colors.black),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      message,
                      textAlign: TextAlign.center,
                      style: TextStyle(color: isDark ? Colors.white38 : Colors.grey, fontSize: 14, height: 1.5),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              if (onRetry != null && !isSuccess)
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: onRetry,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.accentColor,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('TRY AGAIN', style: TextStyle(fontWeight: FontWeight.w900, color: Colors.white)),
                  ),
                ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: OutlinedButton(
                  onPressed: onGoHome ?? () => Navigator.of(context).popUntil((route) => route.isFirst),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: isDark ? Colors.white24 : Colors.grey.shade300),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text('BACK TO HOME', style: TextStyle(fontWeight: FontWeight.w900, color: isDark ? Colors.white70 : Colors.grey.shade700)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
