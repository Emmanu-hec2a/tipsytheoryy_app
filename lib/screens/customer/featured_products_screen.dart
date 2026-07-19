import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';
import '../../providers/product_provider.dart';
import '../../widgets/product_card.dart';
import 'store_detail_screen.dart';

class FeaturedProductsScreen extends StatelessWidget {
  const FeaturedProductsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final productProvider = Provider.of<ProductProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: AppTheme.primaryColor,
        elevation: 0,
        centerTitle: true,
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
          ? Center(child: Text('No featured products available.', style: TextStyle(color: isDark ? Colors.white38 : Colors.grey)))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: productProvider.featuredProducts.length,
              itemBuilder: (context, index) {
                final product = productProvider.featuredProducts[index];
                return ProductCard(
                  product: product,
                  showAddButton: false, // 🛡️ Force Store Context
                  onView: () {
                    // Find the store from the popular stores list or navigate with basic info
                    final store = productProvider.popularStores.firstWhere(
                      (s) => s.id == product.storeId,
                      orElse: () => productProvider.popularStores.first,
                    );
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => StoreDetailScreen(store: store),
                      ),
                    );
                  },
                );
              },
            ),
    );
  }
}
