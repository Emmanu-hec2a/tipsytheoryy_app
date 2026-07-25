import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/rider_provider.dart';
import '../../core/theme.dart';
import '../../widgets/floating_nav_bar.dart';
import 'available_orders_screen.dart';
import 'active_delivery_screen.dart';
import 'earnings_screen.dart';
import 'rider_profile_screen.dart';

class RiderShell extends StatefulWidget {
  const RiderShell({super.key});

  @override
  State<RiderShell> createState() => _RiderShellState();
}

class _RiderShellState extends State<RiderShell> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const AvailableOrdersScreen(),
    const ActiveDeliveryScreen(), 
    const RiderEarningsScreen(),
    const RiderProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true, // Crucial for floating effect
      body: Stack(
        children: [
          _screens[_selectedIndex],
          // 🛡️ Global Loader & Error Feedback
          Consumer<RiderProvider>(
            builder: (context, provider, child) {
              if (provider.error != null) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(provider.error!),
                      backgroundColor: Colors.redAccent,
                      behavior: SnackBarBehavior.floating,
                      margin: const EdgeInsets.only(bottom: 100, left: 20, right: 20),
                    ),
                  );
                  provider.clearError();
                });
              }
              return provider.isActionLoading 
                ? Container(
                    color: Colors.black45, // Slightly darker overlay
                    child: const Center(
                      child: Card(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(20))),
                        child: Padding(
                          padding: EdgeInsets.all(24),
                          child: CircularProgressIndicator(color: AppTheme.primaryColor),
                        ),
                      ),
                    ),
                  )
                : const SizedBox.shrink();
            },
          ),
        ],
      ),
      bottomNavigationBar: FloatingPillNavBar(
        selectedIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        items: [
          FloatingNavBarItem(icon: Icons.home_outlined, activeIcon: Icons.home_rounded, label: 'DASHBOARD'),
          FloatingNavBarItem(icon: Icons.navigation_outlined, activeIcon: Icons.navigation_rounded, label: 'ACTIVE'),
          FloatingNavBarItem(icon: Icons.bar_chart_rounded, activeIcon: Icons.bar_chart_rounded, label: 'EARNINGS'),
          FloatingNavBarItem(icon: Icons.person_outline_rounded, activeIcon: Icons.person_rounded, label: 'PROFILE'),
        ],
      ),
    );
  }
}
