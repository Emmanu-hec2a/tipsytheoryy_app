import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';
import '../../providers/product_provider.dart';
import '../../widgets/product_card.dart';

class FeaturedProductsScreen extends StatelessWidget {
  const FeaturedProductsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final productProvider = Provider.of<ProductProvider>(context);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: AppTheme.primaryColor,
        title: const Text(
          'Featured Deals',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: productProvider.featuredProducts.isEmpty
          ? const Center(child: Text('No featured products available.'))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: productProvider.featuredProducts.length,
              itemBuilder: (context, index) {
                return ProductCard(
                  product: productProvider.featuredProducts[index],
                );
              },
            ),
    );
  }
}
