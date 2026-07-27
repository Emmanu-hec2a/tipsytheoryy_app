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
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(right: 6),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected 
              ? AppTheme.accentColor 
              : (isDark ? AppTheme.darkSurface.withValues(alpha: 0.6) : const Color(0xFFF1F5F9)),
          borderRadius: BorderRadius.circular(100),
        ),
        child: Center(
          // ⚖️ Alignment Fix: Use a conditional Row only if an icon exists 
          // to ensure text-only chips are perfectly centered.
          child: icon != null 
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(_getEmoji(icon!), style: const TextStyle(fontSize: 14)),
                  const SizedBox(width: 8),
                  Text(
                    name.toUpperCase(),
                    style: _textStyle(isSelected, isDark),
                  ),
                ],
              )
            : Text(
                name.toUpperCase(),
                style: _textStyle(isSelected, isDark),
              ),
        ),
      ),
    );
  }

  TextStyle _textStyle(bool isSelected, bool isDark) {
    return TextStyle(
      fontSize: 11.5, // 📈 Increased slightly for better legibility
      letterSpacing: 0.6,
      fontWeight: isSelected ? FontWeight.w900 : FontWeight.w800, // Made bold to match reference
      color: isSelected ? Colors.white : (isDark ? Colors.white38 : Colors.grey.shade600),
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
