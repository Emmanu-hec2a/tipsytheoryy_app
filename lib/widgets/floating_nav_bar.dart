import 'package:flutter/material.dart';
import '../core/theme.dart';

class FloatingPillNavBar extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onTap;
  final List<FloatingNavBarItem> items;

  const FloatingPillNavBar({
    super.key,
    required this.selectedIndex,
    required this.onTap,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    // 🛡️ SYSTEM OVERLAY GUARD: Calculate bottom padding to avoid 3-button navigation obstruction
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final displayPadding = bottomPadding > 0 ? bottomPadding : 16.0;

    return Container(
      padding: EdgeInsets.fromLTRB(20, 0, 20, displayPadding),
      child: Container(
        height: 70,
        decoration: BoxDecoration(
          color: AppTheme.primaryColor,
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.14),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: items.asMap().entries.map((entry) {
            final index = entry.key;
            final item = entry.value;
            final isSelected = selectedIndex == index;

            return Expanded(
              child: Semantics(
                label: "${item.label} tab",
                selected: isSelected,
                button: true,
                child: GestureDetector(
                  onTap: () => onTap(index),
                  behavior: HitTestBehavior.opaque,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.white.withValues(alpha: 0.12) : Colors.transparent,
                      borderRadius: BorderRadius.circular(22),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: Colors.white.withValues(alpha: 0.16),
                                blurRadius: 10,
                                spreadRadius: 1,
                              ),
                            ]
                          : null,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          isSelected ? item.activeIcon : item.icon,
                          color: isSelected ? Colors.white : Colors.white70,
                          size: isSelected ? 24 : 22,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          item.label,
                          style: TextStyle(
                            color: isSelected ? Colors.white : Colors.white70,
                            fontSize: 9,
                            fontWeight: isSelected ? FontWeight.w900 : FontWeight.w600,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

class FloatingNavBarItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;

  FloatingNavBarItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
  });
}
