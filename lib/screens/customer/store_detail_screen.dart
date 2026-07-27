import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shimmer/shimmer.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/theme.dart';
import '../../models/store_model.dart';
import '../../models/product_model.dart';
import '../../providers/cart_provider.dart';
import '../../providers/product_provider.dart';
import '../../providers/location_provider.dart';
import '../../providers/favourite_provider.dart';
import '../../providers/promotion_provider.dart';
import '../../widgets/pro_badge.dart';
import '../../widgets/product_card.dart';
import '../../widgets/category_chip.dart';
import '../../models/promotion_model.dart';

class StoreDetailScreen extends StatefulWidget {
  final StoreModel store;
  const StoreDetailScreen({super.key, required this.store});

  @override
  State<StoreDetailScreen> createState() => _StoreDetailScreenState();
}

class _StoreDetailScreenState extends State<StoreDetailScreen> {
  double? _liveDistance;
  String _selectedCategory = 'All';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ProductProvider>(context, listen: false).fetchStoreProducts(widget.store.id);
      Provider.of<PromotionProvider>(context, listen: false).fetchPromotions(widget.store.id);
      Provider.of<FavouriteProvider>(context, listen: false).fetchFavourites();
      _calculateLiveDistance();

      // Update cart delivery fee for this merchant
      final fee = widget.store.dynamicDeliveryFee > 0 
          ? widget.store.dynamicDeliveryFee 
          : widget.store.deliveryFee;
      Provider.of<CartProvider>(context, listen: false).setDeliveryFee(fee);
    });
  }

  void _calculateLiveDistance() {
    final locProvider = Provider.of<LocationProvider>(context, listen: false);
    final userPos = locProvider.currentAddress;

    if (userPos != null && widget.store.latitude != 0) {
      double distanceInMeters = Geolocator.distanceBetween(
        userPos.latitude, 
        userPos.longitude, 
        widget.store.latitude,
        widget.store.longitude
      );
      setState(() {
        _liveDistance = distanceInMeters / 1000; // Convert to km
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final productProvider = Provider.of<ProductProvider>(context);
    final cart = Provider.of<CartProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final filteredProducts = _selectedCategory == 'All'
        ? productProvider.storeProducts
        : productProvider.storeProducts.where((p) => p.category == _selectedCategory).toList();

    final categories = ['All', ...productProvider.storeProducts.map((p) => p.category).whereType<String>().toSet().toList()];

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: isDark ? Colors.white : const Color(0xFF0F172A), size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          _buildFavoriteButton(),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildStoreCover(),
              const SizedBox(height: 16),
              _buildStoreIdentity(),
              const SizedBox(height: 16),
              _buildActionChips(),
              const SizedBox(height: 20),
              _buildOffersCarousel(),
              if (productProvider.isLoading)
                _buildSkeletonLoading()
              else if (productProvider.storeProducts.isEmpty)
                _buildEmptyState()
              else ...[
                _buildStoreFeaturedDeals(productProvider),
                _buildCategoryFilter(categories),
                const SizedBox(height: 20),
                _buildProductGrid(filteredProducts),
              ],
              const SizedBox(height: 120),
            ],
          ),
        ),
      ),
      floatingActionButton: _buildCartFAB(context, cart),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget _buildOffersCarousel() {
    final promoProvider = Provider.of<PromotionProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (promoProvider.isLoading) {
      return Shimmer.fromColors(
        baseColor: isDark ? AppTheme.darkShimmerBase : Colors.grey.shade100,
        highlightColor: isDark ? AppTheme.darkShimmerHighlight : Colors.white,
        child: Container(
          height: 100,
          margin: const EdgeInsets.only(bottom: 20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
          ),
        ),
      );
    }

    if (promoProvider.availablePromotions.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "Active Offers",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFFF5722).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(100),
              ),
              child: const Row(
                children: [
                  Icon(Icons.flash_on_rounded, color: Color(0xFFFF5722), size: 12),
                  SizedBox(width: 4),
                  Text(
                    "LIMITED",
                    style: TextStyle(
                      color: Color(0xFFFF5722),
                      fontSize: 9,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 110,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: promoProvider.availablePromotions.length,
            itemBuilder: (context, index) {
              final promo = promoProvider.availablePromotions[index];
              final expiresSoon = promo.endDate.difference(DateTime.now()).inDays < 3;
              
              return Container(
                width: 280,
                margin: const EdgeInsets.only(right: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? Theme.of(context).cardColor : Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: isDark ? Colors.white.withValues(alpha: 0.05) : const Color(0xFFF1F5F9),
                  ),
                  boxShadow: isDark ? [] : [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    )
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFF5722), Color(0xFFFF9800)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(Icons.confirmation_num_rounded, color: Colors.white, size: 24),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            promo.title,
                            style: TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 15,
                              color: isDark ? Colors.white : const Color(0xFF0D3B30),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Text(
                                promo.code,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w900,
                                  fontSize: 12,
                                  color: Color(0xFFFF5722),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                width: 4,
                                height: 4,
                                decoration: BoxDecoration(
                                  color: isDark ? Colors.white24 : Colors.grey.shade300,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Min order: KSh ${promo.minOrderAmount.toInt()}',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: isDark ? Colors.white38 : Colors.blueGrey.shade400,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          if (expiresSoon) ...[
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                Icon(Icons.timer_outlined, size: 10, color: Colors.amber.shade700),
                                const SizedBox(width: 4),
                                Text(
                                  'Expires soon',
                                  style: TextStyle(
                                    fontSize: 9,
                                    color: Colors.amber.shade700,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildActionChips() {
    return Row(
      children: [
        _buildChip(
          icon: Icons.call_outlined,
          label: 'Call',
          onTap: _makeCall,
        ),
        const SizedBox(width: 12),
        _buildChip(
          icon: Icons.info_outline_rounded,
          label: 'Info',
          onTap: _showStoreInfo,
        ),
        const SizedBox(width: 12),
        _buildChip(
          icon: Icons.ios_share_rounded,
          label: 'Share',
          onTap: _shareStore,
        ),
      ],
    );
  }

  Widget _buildChip({required IconData icon, required String label, required VoidCallback onTap}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
          decoration: BoxDecoration(
            color: isDark ? Theme.of(context).cardColor : const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: isDark ? Colors.white10 : const Color(0xFFF1F5F9)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: isDark ? Colors.white70 : const Color(0xFF0D3B30), size: 16),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white70 : const Color(0xFF0D3B30),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryFilter(List<String> categories) {
    if (categories.length <= 1) return const SizedBox.shrink();
    return SizedBox(
      height: 42,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final category = categories[index];
          final isSelected = _selectedCategory == category;
          return CategoryChip(
            name: category,
            isSelected: isSelected,
            onTap: () => setState(() => _selectedCategory = category),
          );
        },
      ),
    );
  }

  void _makeCall() async {
    final phone = widget.store.phone;
    if (phone == null || phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Store phone number not available')),
      );
      return;
    }
    final url = Uri.parse('tel:$phone');
    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not initiate call. Please dial manually.')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  void _shareStore() {
    final shareText = 'Check out ${widget.store.name} on TipsyTheoryy! 🥂\n\n'
        '${widget.store.tagline ?? "Quality drinks delivered."}\n'
        'Location: ${widget.store.addressString ?? "Available on the app"}';
    Share.share(shareText);
  }

  void _showStoreInfo() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(40)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white10 : const Color(0xFFE2E8F0),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 32),
            Text(
              'Store Information',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w900,
                color: isDark ? Colors.white : const Color(0xFF0D3B30),
              ),
            ),
            const SizedBox(height: 24),
            _buildInfoItem(
              icon: Icons.location_on_rounded,
              title: 'Address',
              subtitle: widget.store.addressString ?? 'Location data not available',
              isDark: isDark,
            ),
            const SizedBox(height: 20),
            _buildInfoItem(
              icon: Icons.access_time_filled_rounded,
              title: 'Operating Hours',
              subtitle: widget.store.openingTime != null && widget.store.closingTime != null
                  ? '${widget.store.openingTime} - ${widget.store.closingTime}'
                  : 'Hours not specified',
              isDark: isDark,
            ),
            const SizedBox(height: 20),
            _buildInfoItem(
              icon: Icons.description_rounded,
              title: 'About',
              subtitle: widget.store.tagline ?? 'No additional information available.',
              isDark: isDark,
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem({required IconData icon, required String title, required String subtitle, required bool isDark}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withValues(alpha: 0.05) : const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: isDark ? Colors.white70 : const Color(0xFF0D3B30), size: 20),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: isDark ? Colors.white38 : const Color(0xFF64748B),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                  color: isDark ? Colors.white : const Color(0xFF0D3B30),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFavoriteButton() {
    final favProvider = Provider.of<FavouriteProvider>(context);
    final isFav = favProvider.isStoreFavourite(widget.store.id);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return IconButton(
      onPressed: () => favProvider.toggleFavourite(widget.store.id),
      icon: Icon(
        isFav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
        color: isFav 
          ? (isDark ? AppTheme.accentColor : const Color(0xFF0D3B30)) 
          : (isDark ? Colors.white38 : const Color(0xFF0F172A)),
      ),
    );
  }

  Widget _buildStoreCover() {
    return Container(
      height: 200,
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFFE2E8F0),
        borderRadius: BorderRadius.circular(32),
        image: widget.store.coverImage != null
          ? DecorationImage(image: NetworkImage(widget.store.coverImage!), fit: BoxFit.cover)
          : (widget.store.logo != null 
              ? DecorationImage(image: NetworkImage(widget.store.logo!), fit: BoxFit.cover)
              : null),
      ),
      child: Stack(
        children: [
          if (widget.store.coverImage == null && widget.store.logo == null)
            Center(
              child: Icon(Icons.image_outlined, size: 48, color: Colors.blueGrey.shade400),
            ),
          if (widget.store.isPro)
            Positioned(
              top: 20,
              left: 20,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFF97316),
                  borderRadius: BorderRadius.circular(100),
                ),
                child: const Text(
                  'PRO',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStoreIdentity() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Flexible(
              child: Text(
                widget.store.name,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: isDark ? Colors.white : const Color(0xFF0D3B30),
                  letterSpacing: -0.5,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (widget.store.isPro) ...[
              const SizedBox(width: 8),
              Icon(
                Icons.verified_rounded,
                color: isDark ? AppTheme.accentColor : const Color(0xFF0D3B30),
                size: 22,
              ),
            ],
          ],
        ),
        const SizedBox(height: 4),
        Text(
          widget.store.tagline ?? 'Premium spirits',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: isDark ? Colors.white38 : Colors.blueGrey.shade400,
            fontStyle: FontStyle.italic,
          ),
        ),
      ],
    );
  }

  Widget _buildSkeletonLoading() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor = isDark ? AppTheme.darkShimmerBase : Colors.grey.shade100;
    final highlightColor = isDark ? AppTheme.darkShimmerHighlight : Colors.white;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Shimmer.fromColors(
          baseColor: baseColor,
          highlightColor: highlightColor,
          child: Container(
            width: 120,
            height: 24,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        const SizedBox(height: 24),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 0.8,
          ),
          itemCount: 4,
          itemBuilder: (context, index) {
            return Shimmer.fromColors(
              baseColor: baseColor,
              highlightColor: highlightColor,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(32),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 60),
        child: Column(
          children: [
            Icon(Icons.inventory_2_outlined, size: 64, color: Colors.blueGrey.shade200),
            const SizedBox(height: 16),
            Text(
              'No products available.',
              style: TextStyle(
                color: Colors.blueGrey.shade400,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductGrid(List<ProductModel> products) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final standardProducts = products.where((p) => !p.isFeatured).toList();
    if (standardProducts.isEmpty && products.any((p) => p.isFeatured)) {
      return const SizedBox.shrink(); // Handled by featured section
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Available Menu",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w900,
            color: isDark ? Colors.white : const Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: EdgeInsets.zero,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 0.75,
          ),
          itemCount: products.length,
          itemBuilder: (context, index) {
            return _buildProductCard(context, products[index]);
          },
        ),
      ],
    );
  }

  Widget _buildProductCard(BuildContext context, ProductModel product) {
    final cart = Provider.of<CartProvider>(context, listen: false);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      onTap: () {
        // Product detail navigation if needed
      },
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? Theme.of(context).cardColor : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(32),
          border: Border.all(color: isDark ? Colors.white10 : const Color(0xFFF1F5F9)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                children: [
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(31)),
                      image: product.image != null
                        ? DecorationImage(image: NetworkImage(product.image!), fit: BoxFit.cover)
                        : null,
                    ),
                    child: product.image == null
                      ? Center(child: Icon(Icons.wine_bar_rounded, color: isDark ? Colors.white10 : AppTheme.primaryColor.withValues(alpha: 0.1), size: 40))
                      : null,
                  ),
                  Positioned(
                    bottom: 8,
                    right: 8,
                    child: InkWell(
                      onTap: () {
                        if (cart.isFromDifferentStore(product.storeId)) {
                          _showClearCartDialog(context, cart, product);
                          return;
                        }
                        final fee = widget.store.dynamicDeliveryFee > 0 
                            ? widget.store.dynamicDeliveryFee 
                            : widget.store.deliveryFee;
                        cart.addToCart(
                          product, 
                          deliveryFee: fee, 
                          storeName: widget.store.name,
                          storeLat: widget.store.latitude,
                          storeLng: widget.store.longitude,
                          storeRadius: widget.store.deliveryRadiusKm,
                        );
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('${product.name} added'),
                            duration: const Duration(seconds: 1),
                          ),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: const BoxDecoration(
                          color: AppTheme.primaryColor,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.add, color: Colors.white, size: 20),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: isDark ? Colors.white : const Color(0xFF1E293B)),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'KSh ${product.price.toStringAsFixed(0)}',
                    style: TextStyle(
                      color: isDark ? Colors.white70 : AppTheme.primaryColor,
                      fontWeight: FontWeight.w900,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCartFAB(BuildContext context, CartProvider cart) {
    if (cart.items.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: InkWell(
        onTap: () => Navigator.pushNamed(context, '/cart'),
        child: Container(
          height: 65,
          width: double.infinity,
          decoration: BoxDecoration(
            color: AppTheme.primaryColor,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [BoxShadow(color: AppTheme.primaryColor.withValues(alpha: 0.3), blurRadius: 20, offset: const Offset(0, 10))],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
                  child: Text('${cart.itemCount}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16)),
                ),
                const SizedBox(width: 16),
                const Text('VIEW CART', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 15, letterSpacing: 1)),
                const Spacer(),
                Text('KSh ${cart.total.toStringAsFixed(0)}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 18)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStoreFeaturedDeals(ProductProvider provider) {
    final deals = provider.storeProducts.where((p) => p.isFeatured).toList();
    if (deals.isEmpty) return const SizedBox.shrink();

    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Featured Deals",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w900,
            color: isDark ? Colors.white : const Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 140,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: deals.length,
            itemBuilder: (context, index) {
              final product = deals[index];
              return Container(
                width: 280,
                margin: const EdgeInsets.only(right: 12),
                child: ProductCard(
                  product: product,
                  isVertical: false,
                  onAdd: () {
                    final cart = Provider.of<CartProvider>(context, listen: false);
                    if (cart.isFromDifferentStore(product.storeId)) {
                      _showClearCartDialog(context, cart, product);
                      return;
                    }
                    final fee = widget.store.dynamicDeliveryFee > 0 
                        ? widget.store.dynamicDeliveryFee 
                        : widget.store.deliveryFee;
                    cart.addToCart(
                      product, 
                      deliveryFee: fee, 
                      storeName: widget.store.name,
                      storeLat: widget.store.latitude,
                      storeLng: widget.store.longitude,
                      storeRadius: widget.store.deliveryRadiusKm,
                    );
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('${product.name} added'),
                        duration: const Duration(seconds: 1),
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  void _showClearCartDialog(BuildContext context, CartProvider cart, ProductModel product) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear cart?', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text('Your cart contains items from ${cart.activeStoreName ?? "another store"}. Clear it to start a new order?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCEL', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
          ),
          TextButton(
            onPressed: () {
              cart.clearCart();
              final fee = widget.store.dynamicDeliveryFee > 0 
                  ? widget.store.dynamicDeliveryFee 
                  : widget.store.deliveryFee;
              cart.addToCart(
                product, 
                deliveryFee: fee, 
                storeName: widget.store.name,
                storeLat: widget.store.latitude,
                storeLng: widget.store.longitude,
                storeRadius: widget.store.deliveryRadiusKm,
              );
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Cart cleared and item added')),
              );
            },
            child: const Text('CLEAR & ADD', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
