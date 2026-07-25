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

class _CustomerShellState extends State<CustomerShell> with WidgetsBindingObserver {
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
    WidgetsBinding.instance.addObserver(this);
    _initSafetyDetection();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _userAccelerometerSubscription?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // 🔋 Battery Optimization: Stop sensors if app is in background
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      _userAccelerometerSubscription?.pause();
      debugPrint("🔋 Battery Guard: Paused motion sensors");
    } else if (state == AppLifecycleState.resumed) {
      _userAccelerometerSubscription?.resume();
      debugPrint("🔋 Battery Guard: Resumed motion sensors");
    }
  }

  void _initSafetyDetection() {
    _userAccelerometerSubscription = userAccelerometerEventStream(
      samplingPeriod: const Duration(milliseconds: 500)
    ).listen((event) {
      if (!mounted) return;

      double magnitude = sqrt(event.x * event.x + event.y * event.y + event.z * event.z);

      if (magnitude > _walkingThreshold) {
        _sustainedMotionCount++;
      } else {
        _sustainedMotionCount = 0;
      }

      if (_sustainedMotionCount >= _requiredSustainedEvents && 
          DateTime.now().difference(_lastSafetyNotice).inSeconds > 90) {
        _showSafetyNotice();
        _sustainedMotionCount = 0;
      }
    });
  }

  void _showSafetyNotice() {
    _lastSafetyNotice = DateTime.now();
    
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    scaffoldMessenger.hideCurrentSnackBar();
    
    // 🛡️ UI HARDENING: Adjusted margin to account for Status Bar / SafeArea
    final topPadding = MediaQuery.of(context).padding.top;
    
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
        backgroundColor: AppTheme.accentColor,
        behavior: SnackBarBehavior.floating,
        // 📍 DYNAMIC POSITIONING: Calculated based on screen height and status bar
        margin: EdgeInsets.only(
          bottom: MediaQuery.of(context).size.height - (topPadding + 140), 
          left: 16, 
          right: 16
        ),
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
      extendBody: true,
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
