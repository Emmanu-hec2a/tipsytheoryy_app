import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../core/theme.dart';

class RiderOrderSkeleton extends StatelessWidget {
  const RiderOrderSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor = isDark ? AppTheme.darkShimmerBase : AppTheme.shimmerBase;
    final highlightColor = isDark ? AppTheme.darkShimmerHighlight : AppTheme.shimmerHighlight;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? Theme.of(context).cardColor : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: isDark ? Border.all(color: Colors.white10) : null,
      ),
      child: Shimmer.fromColors(
        baseColor: baseColor,
        highlightColor: highlightColor,
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(width: 80, height: 24, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8))),
                Container(width: 60, height: 14, color: Colors.white),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                const CircleAvatar(radius: 11, backgroundColor: Colors.white),
                const SizedBox(width: 16),
                Container(width: 150, height: 14, color: Colors.white),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const CircleAvatar(radius: 11, backgroundColor: Colors.white),
                const SizedBox(width: 16),
                Container(width: 200, height: 14, color: Colors.white),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(width: 100, height: 10, color: Colors.white),
                    const SizedBox(height: 8),
                    Container(width: 120, height: 24, color: Colors.white),
                  ],
                ),
                Container(width: 120, height: 50, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16))),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class RiderStatSkeleton extends StatelessWidget {
  const RiderStatSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor = isDark ? AppTheme.darkShimmerBase : AppTheme.shimmerBase;
    final highlightColor = isDark ? AppTheme.darkShimmerHighlight : AppTheme.shimmerHighlight;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? Theme.of(context).cardColor : Colors.white,
        borderRadius: BorderRadius.circular(30),
        border: isDark ? Border.all(color: Colors.white10) : null,
      ),
      child: Shimmer.fromColors(
        baseColor: baseColor,
        highlightColor: highlightColor,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(3, (index) => Column(
            children: [
              Container(width: 40, height: 10, color: Colors.white),
              const SizedBox(height: 8),
              Container(width: 60, height: 18, color: Colors.white),
            ],
          )),
        ),
      ),
    );
  }
}
