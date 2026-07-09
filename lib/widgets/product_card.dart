import 'package:flutter/material.dart';
import '../core/theme.dart';
import '../models/product_model.dart';

class ProductCard extends StatelessWidget {
  final ProductModel product;
  final VoidCallback? onAdd;
  final bool isVertical;

  const ProductCard({
    super.key, 
    required this.product, 
    this.onAdd,
    this.isVertical = true,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12), // Reduced padding slightly to save space
          margin: EdgeInsets.only(bottom: isVertical ? 12 : 0),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.grey.shade100),
            boxShadow: [
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
              Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(12),
                  image: product.image != null
                    ? DecorationImage(image: NetworkImage(product.image!), fit: BoxFit.cover)
                    : null,
                ),
                child: product.image == null
                  ? Icon(Icons.wine_bar, color: AppTheme.primaryColor.withValues(alpha: 0.2), size: 30)
                  : null,
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
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 15,
                        color: AppTheme.primaryColor,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      product.category ?? 'Beverage',
                      style: TextStyle(
                        color: Colors.grey.shade400,
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
                          style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 16,
                            color: Color(0xFF0D3B30),
                          ),
                        ),

                        // Add Button
                        GestureDetector(
                          onTap: product.isAvailable ? onAdd : null,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: product.isAvailable ? const Color(0xFFF1F5F9) : Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  product.isAvailable ? Icons.add_shopping_cart : Icons.block, 
                                  size: 14, 
                                  color: product.isAvailable ? Colors.grey.shade700 : Colors.grey.shade400
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  product.isAvailable ? 'Add' : 'Sold Out',
                                  style: TextStyle(
                                    color: product.isAvailable ? Colors.grey.shade700 : Colors.grey.shade400,
                                    fontWeight: FontWeight.w900,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
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
        if (!product.isAvailable)
          Positioned.fill(
            child: Container(
              margin: EdgeInsets.only(bottom: isVertical ? 12 : 0),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
      ],
    );
  }
}
