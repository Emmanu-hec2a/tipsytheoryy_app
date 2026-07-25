import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../widgets/floating_nav_bar.dart';
import '../../widgets/theory_ai_fab.dart';
import 'home_screen.dart';
import 'stores_list_screen.dart';
import 'orders_screen.dart';
import 'profile_screen.dart';
import 'dart:async';
import 'dart:math';
import 'package:sensors_plus/sensors_plus.dart';

class CustomerShell extends StatefulWidget {
  const CustomerShell({super.key});

  @override
  State<CustomerShell> createState() => _CustomerShellState();
}

class _CustomerShellState extends State<CustomerShell> {
  int _selectedIndex = 0;
  
  // Walk-and-Watch state
  StreamSubscription? _userAccelerometerSubscription;
  DateTime _lastSafetyNotice = DateTime.now().subtract(const Duration(minutes: 5));
  
  // 🛡️ Pro-Tier Safety Logic
  static const double _walkingThreshold = 1.8; // User acceleration (m/s²)
  int _sustainedMotionCount = 0;
  static const int _requiredSustainedEvents = 6; // ~3 seconds of continuous motion

  @override
  void initState() {
    super.initState();
    _initSafetyDetection();
  }

  @override
  void dispose() {
    _userAccelerometerSubscription?.cancel();
    super.dispose();
  }

  void _initSafetyDetection() {
    // 🛡️ Use UserAccelerometer (automatically removes gravity)
    // Sampling at 500ms intervals to reduce CPU jitter
    _userAccelerometerSubscription = userAccelerometerEventStream(
      samplingPeriod: const Duration(milliseconds: 500)
    ).listen((event) {
      if (!mounted) return;

      // Calculate pure linear acceleration magnitude
      double magnitude = sqrt(event.x * event.x + event.y * event.y + event.z * event.z);

      // Check if motion is significant (ignoring minor hand jitter)
      if (magnitude > _walkingThreshold) {
        _sustainedMotionCount++;
      } else {
        _sustainedMotionCount = 0; // Reset if they stop moving
      }

      // Trigger ONLY if motion is sustained (prevents accidental shakes/sitting movements)
      if (_sustainedMotionCount >= _requiredSustainedEvents && 
          DateTime.now().difference(_lastSafetyNotice).inSeconds > 90) { // CD: 90s
        _showSafetyNotice();
        _sustainedMotionCount = 0; // Reset after warning
      }
    });
  }

  void _showSafetyNotice() {
    _lastSafetyNotice = DateTime.now();
    
    // 🛡️ UI Hardening: Using a custom Overlay instead of a blocking Dialog
    // This ensures it doesn't interrupt shopping but stays visible.
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    scaffoldMessenger.hideCurrentSnackBar();
    scaffoldMessenger.showSnackBar(
      SnackBar(
        content: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.directions_walk_rounded, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'WALK-AND-WATCH ALERT',
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.white70, letterSpacing: 1),
                    ),
                    Text(
                      'For your safety, please watch the road while walking.',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        backgroundColor: AppTheme.accentColor, // Consistent with Premium UI
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.fromLTRB(16, 16, 16, 100), // Pushed up above NavBar
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        duration: const Duration(seconds: 5),
        dismissDirection: DismissDirection.horizontal,
      ),
    );
  }

  final List<Widget> _screens = [
    const CustomerHomeScreen(),
    const StoresListScreen(),
    const OrdersScreen(),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true, // Crucial for floating navbar to show screen content behind it
      body: _screens[_selectedIndex],
      floatingActionButton: const TheoryAIFab(),
      bottomNavigationBar: FloatingPillNavBar(
        selectedIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        items: [
          FloatingNavBarItem(icon: Icons.home_outlined, activeIcon: Icons.home_rounded, label: 'HOME'),
          FloatingNavBarItem(icon: Icons.storefront_outlined, activeIcon: Icons.storefront_rounded, label: 'STORES'),
          FloatingNavBarItem(icon: Icons.shopping_bag_outlined, activeIcon: Icons.shopping_bag_rounded, label: 'ORDERS'),
          FloatingNavBarItem(icon: Icons.person_outline_rounded, activeIcon: Icons.person_rounded, label: 'PROFILE'),
        ],
      ),
    );
  }
}
