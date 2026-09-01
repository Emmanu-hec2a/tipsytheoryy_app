import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import '../core/theme.dart';
import '../models/product_model.dart';

class ProductCard extends StatelessWidget {
  final ProductModel product;
  final VoidCallback? onAdd;
  final VoidCallback? onView; // 🆕 Added for navigation
  final bool isVertical;
  final bool showAddButton; // 🆕 Added to toggle between Add and View

  const ProductCard({
    super.key, 
    required this.product, 
    this.onAdd,
    this.onView,
    this.isVertical = true,
    this.showAddButton = true,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return MergeSemantics(
      child: RepaintBoundary(
        child: Stack(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              margin: EdgeInsets.only(bottom: isVertical ? 12 : 0),
              decoration: BoxDecoration(
                color: isDark ? Theme.of(context).cardColor : Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: isDark ? [] : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.02),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  )
                ],
              ),
              child: Row(
                children: [
                  // Product Image
                  Semantics(
                    label: "Product image of ${product.name}",
                    child: Container(
                      width: 90,
                      height: 90,
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white.withValues(alpha: 0.05) : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: product.image != null
                          ? CachedNetworkImage(
                              imageUrl: product.image!,
                              fit: BoxFit.cover,
                              placeholder: (context, url) => Shimmer.fromColors(
                                baseColor: isDark ? Colors.white10 : Colors.grey.shade100,
                                highlightColor: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white,
                                child: Container(color: Colors.white),
                              ),
                              errorWidget: (context, url, error) => Icon(Icons.wine_bar, color: isDark ? Colors.white10 : AppTheme.primaryColor.withValues(alpha: 0.2), size: 30),
                            )
                          : Icon(Icons.wine_bar, color: isDark ? Colors.white10 : AppTheme.primaryColor.withValues(alpha: 0.2), size: 30),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Product Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          product.name,
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 15,
                            color: isDark ? Colors.white : AppTheme.primaryColor,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          product.category ?? 'Beverage',
                          style: TextStyle(
                            color: isDark ? Colors.white38 : Colors.grey.shade400,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'KSh ${product.price.toStringAsFixed(0)}',
                              style: TextStyle(
                                fontWeight: FontWeight.w900,
                                fontSize: 16,
                                color: isDark ? Colors.white : const Color(0xFF0D3B30),
                              ),
                            ),

                            // Action Button (Add or View)
                            Semantics(
                              button: true,
                              enabled: product.isAvailable,
                              label: product.isAvailable 
                                ? (showAddButton ? "Add ${product.name} to cart" : "View ${product.name} details")
                                : "${product.name} is currently sold out",
                              child: GestureDetector(
                                onTap: product.isAvailable 
                                  ? (showAddButton ? onAdd : onView) 
                                  : null,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: product.isAvailable 
                                      ? (isDark ? Colors.white.withValues(alpha: 0.05) : const Color(0xFFF1F5F9)) 
                                      : (isDark ? Colors.white.withValues(alpha: 0.02) : Colors.grey.shade100),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        product.isAvailable 
                                          ? (showAddButton ? Icons.add_shopping_cart : Icons.visibility_outlined) 
                                          : Icons.block, 
                                        size: 14, 
                                        color: product.isAvailable 
                                          ? (isDark ? Colors.white70 : Colors.grey.shade700) 
                                          : (isDark ? Colors.white10 : Colors.grey.shade400)
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        product.isAvailable 
                                          ? (showAddButton ? 'Add' : 'View More') 
                                          : 'Sold Out',
                                        style: TextStyle(
                                          color: product.isAvailable 
                                            ? (isDark ? Colors.white70 : Colors.grey.shade700) 
                                            : (isDark ? Colors.white10 : Colors.grey.shade400),
                                          fontWeight: FontWeight.w900,
                                          fontSize: 11,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (product.isNewArrival)
              Positioned(
                top: 6,
                left: 6,
                child: Semantics(
                  label: "New Arrival",
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppTheme.accentColor,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      'NEW',
                      style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.w900, letterSpacing: 0.5),
                    ),
                  ),
                ),
              ),
            if (!product.isAvailable)
              Positioned.fill(
                child: ExcludeSemantics(
                  child: Container(
                    margin: EdgeInsets.only(bottom: isVertical ? 12 : 0),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
