import 'package:flutter/material.dart';
import '../core/theme.dart';

class CategoryChip extends StatelessWidget {
  final String name;
  final String? icon;
  final bool isSelected;
  final VoidCallback? onTap;

  const CategoryChip({
    super.key,
    required this.name,
    this.icon,
    this.isSelected = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.accentColor : (isDark ? Theme.of(context).cardColor : const Color(0xFFF1F5F9)),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              name,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w900 : FontWeight.w600,
                color: isSelected ? Colors.white : (isDark ? Colors.white38 : Colors.grey.shade600),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getEmoji(String iconName) {
    switch (iconName.toLowerCase()) {
      case 'whiskey': return '🥃';
      case 'wine': return '🍷';
      case 'beer': return '🍺';
      case 'gin': return '🍸';
      case 'spirits': return '🍹';
      case 'champagne': return '🍾';
      default: return iconName.length <= 2 ? iconName : '🥂';
    }
  }
}
