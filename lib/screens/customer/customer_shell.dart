import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../widgets/floating_nav_bar.dart';
import '../../widgets/theory_ai_fab.dart';
import 'home_screen.dart';
import 'stores_list_screen.dart';
import 'orders_screen.dart';
import 'profile_screen.dart';

class CustomerShell extends StatefulWidget {
  const CustomerShell({super.key});

  @override
  State<CustomerShell> createState() => _CustomerShellState();
}

class _CustomerShellState extends State<CustomerShell> {
  int _selectedIndex = 0;

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
