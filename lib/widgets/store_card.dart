import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import '../core/theme.dart';
import '../models/store_model.dart';
import 'pro_badge.dart';

class StoreCard extends StatelessWidget {
  final StoreModel store;
  final bool showViewButton;
  final VoidCallback? onTap;

  const StoreCard({
    super.key,
    required this.store,
    this.showViewButton = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return RepaintBoundary(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? Theme.of(context).cardColor : Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: store.isPro 
            ? Border.all(color: const Color(0xFFC5A059).withValues(alpha: isDark ? 0.5 : 0.3), width: 1.5) 
            : null,
          boxShadow: isDark ? [] : [
            BoxShadow(
              color: store.isPro 
                ? const Color(0xFFC5A059).withValues(alpha: 0.08)
                : Colors.black.withValues(alpha: 0.04),
              blurRadius: 20,
              offset: const Offset(0, 10),
            )
          ],
        ),
        child: Row(
          children: [
            // Store Logo
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white.withValues(alpha: 0.05) : AppTheme.primaryColor.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: store.logo != null
                      ? CachedNetworkImage(
                          imageUrl: store.logo!,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Shimmer.fromColors(
                            baseColor: isDark ? Colors.white10 : Colors.grey.shade100,
                            highlightColor: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white,
                            child: Container(color: Colors.white),
                          ),
                          errorWidget: (context, url, error) => Icon(Icons.storefront, color: isDark ? Colors.white10 : AppTheme.primaryColor.withValues(alpha: 0.3), size: 32),
                        )
                      : Center(
                          child: Icon(Icons.storefront, color: isDark ? Colors.white10 : AppTheme.primaryColor.withValues(alpha: 0.3), size: 32),
                        ),
                  ),
                ),
                if (store.hasActivePromotions && store.maxPromoDiscount != null && store.isOpen)
                  Positioned(
                    top: -8,
                    left: -8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFF5722), Color(0xFFFF9800)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFFF5722).withValues(alpha: 0.4),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          )
                        ],
                      ),
                      child: Text(
                        store.maxPromoDiscount!,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 16),

            // Store Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Flexible(
                              child: Text(
                                store.name,
                                style: TextStyle(
                                  fontWeight: FontWeight.w900,
                                  fontSize: 17,
                                  color: store.isOpen 
                                    ? (isDark ? Colors.white : AppTheme.primaryColor) 
                                    : (isDark ? Colors.white24 : Colors.grey),
                                  overflow: TextOverflow.ellipsis
                                ),
                              ),
                            ),
                            if (store.isPro) ...[
                              const SizedBox(width: 6),
                              ProBadge(color: store.isOpen ? null : Colors.grey),
                              const SizedBox(width: 4),
                              // Express Delivery Badge if delivery < 25 mins
                              if (store.isOpen && int.tryParse(store.deliveryTime.split(' ')[0]) != null &&
                                  int.parse(store.deliveryTime.split(' ')[0]) <= 25)
                                const Icon(Icons.bolt_rounded, color: Colors.amber, size: 18),
                            ],
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: (store.isOpen ? Colors.green : Colors.red).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          store.isOpen ? 'OPEN' : 'CLOSED',
                          style: TextStyle(
                            color: store.isOpen ? Colors.green : Colors.red, 
                            fontSize: 9, 
                            fontWeight: FontWeight.w900, 
                            letterSpacing: 0.5
                          )
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.star, color: Color(0xFFFFB800), size: 16),
                      const SizedBox(width: 4),
                      Text(
                        store.rating.toStringAsFixed(1),
                        style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: isDark ? Colors.white : AppTheme.primaryColor)
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '(${store.reviewsCount})',
                        style: TextStyle(color: isDark ? Colors.white38 : Colors.grey.shade500, fontSize: 13, fontWeight: FontWeight.bold)
                      ),
                      const SizedBox(width: 12),
                      const Icon(Icons.delivery_dining, color: AppTheme.accentColor, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        store.deliveryFee == 0 ? 'Free' : 'KSh ${store.deliveryFee.toInt()}',
                        style: const TextStyle(color: AppTheme.accentColor, fontSize: 12, fontWeight: FontWeight.w900)
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      _buildMiniInfo(Icons.access_time_filled_rounded, store.deliveryTime, isDark),
                      const SizedBox(width: 12),
                      _buildMiniInfo(Icons.location_on_rounded, '${store.distance.toStringAsFixed(1)} km', isDark),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
    );
  }

  Widget _buildMiniInfo(IconData icon, String text, bool isDark) {
    return Row(
      children: [
        Icon(icon, size: 14, color: isDark ? Colors.white24 : Colors.grey.shade400),
        const SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(color: isDark ? Colors.white38 : Colors.grey.shade500, fontSize: 12, fontWeight: FontWeight.bold)
        ),
      ],
    );
  }
}
