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
import '../../services/notification_service.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class CustomerShell extends StatefulWidget {
  const CustomerShell({super.key});

  @override
  State<CustomerShell> createState() => _CustomerShellState();
}

class _CustomerShellState extends State<CustomerShell> with WidgetsBindingObserver {
  int _selectedIndex = 0;
  late final PageController _pageController;
  
  // Walk-and-Watch state
  StreamSubscription? _userAccelerometerSubscription;
  StreamSubscription? _notificationTapSubscription;
  DateTime _lastSafetyNotice = DateTime.now().subtract(const Duration(minutes: 5));
  
  // 🛡️ Pro-Tier Safety Logic
  static const double _walkingThreshold = 1.8; // User acceleration (m/s²)
  int _sustainedMotionCount = 0;
  static const int _requiredSustainedEvents = 6; // ~3 seconds of continuous motion

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _selectedIndex);
    WidgetsBinding.instance.addObserver(this);
    _initSafetyDetection();
    _initNotificationDeepLinking();
  }

  @override
  void dispose() {
    _pageController.dispose();
    WidgetsBinding.instance.removeObserver(this);
    _userAccelerometerSubscription?.cancel();
    _notificationTapSubscription?.cancel();
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
        // 🛡️ REPAIR: Increased offset from topPadding to 210 to ensure it clears deep notches/status bars
        margin: EdgeInsets.only(
          bottom: MediaQuery.of(context).size.height - (max(topPadding, 44.0) + 160),
          left: 16, 
          right: 16
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        duration: const Duration(seconds: 5),
        dismissDirection: DismissDirection.horizontal,
      ),
    );
  }

  void _initNotificationDeepLinking() {
    _notificationTapSubscription = NotificationService().onNotificationTap.listen((message) {
      final type = message.data['type'];
      
      if (type == 'daily_digest' || type == 'marketing_blast') {
        // Redirect to STORES tab
        _onTabTap(1);
      } else if (type == 'stk_initiated' || type == 'order_status_update') {
        // Redirect to ORDERS tab
        _onTabTap(2);
      }
    });
  }

  void _onTabTap(int index) {
    if (_selectedIndex == index) return;
    setState(() => _selectedIndex = index);
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 400),
      curve: Curves.decelerate,
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
      body: PageView(
        controller: _pageController,
        physics: const BouncingScrollPhysics(), // 🛡️ Restored & Improved: Smooth physics-based swiping
        onPageChanged: (index) {
          setState(() => _selectedIndex = index);
        },
        children: _screens,
      ),
      // floatingActionButton: const TheoryAIFab(), // Temporarily hidden
      bottomNavigationBar: FloatingPillNavBar(
        selectedIndex: _selectedIndex,
        onTap: _onTabTap,
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
