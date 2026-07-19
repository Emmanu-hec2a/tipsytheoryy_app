import 'dart:math';
import 'package:flutter/material.dart';

class ProBadge extends StatelessWidget {
  final double size;
  final Color? color;
  final Color? iconColor;

  const ProBadge({
    super.key, 
    this.size = 18, 
    this.color,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // Light Theme: Original Forest Green (#0D3B30)
    // Dark Theme: Meta Verified Blue (#0081FB) - Recognizable & Professional
    final defaultBadgeColor = isDark ? const Color(0xFF0081FB) : const Color(0xFF0D3B30);
    
    final badgeColor = color ?? defaultBadgeColor;
    final checkColor = iconColor ?? Colors.white;

    return CustomPaint(
      size: Size(size, size),
      painter: VerifiedSealPainter(color: badgeColor),
      child: SizedBox(
        width: size,
        height: size,
        child: Center(
          child: Icon(
            Icons.check,
            color: checkColor,
            size: size * 0.6,
          ),
        ),
      ),
    );
  }
}

class VerifiedSealPainter extends CustomPainter {
  final Color color;

  VerifiedSealPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final double centerX = size.width / 2;
    final double centerY = size.height / 2;
    final double outerRadius = size.width / 2;
    final double innerRadius = outerRadius * 0.85; // Slight zigzag depth
    final int points = 12; // 12-point jagged star

    final path = Path();
    final double angleStep = pi / points;

    for (int i = 0; i < points * 2; i++) {
      final double radius = (i % 2 == 0) ? outerRadius : innerRadius;
      final double angle = i * angleStep - (pi / 2); // Start at top
      final double x = centerX + radius * cos(angle);
      final double y = centerY + radius * sin(angle);

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
