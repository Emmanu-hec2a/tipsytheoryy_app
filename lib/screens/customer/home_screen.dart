import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import '../../core/theme.dart';
import '../../providers/product_provider.dart';
import '../../providers/location_provider.dart';
import '../../providers/cart_provider.dart';
import '../../widgets/category_chip.dart';
import '../../widgets/product_card.dart';
import '../../widgets/store_card.dart';
import '../../models/category_model.dart';
import 'store_detail_screen.dart';
import 'featured_products_screen.dart';
import 'stores_list_screen.dart';

class CustomerHomeScreen extends StatefulWidget {
  const CustomerHomeScreen({super.key});

  @override
  State<CustomerHomeScreen> createState() => _CustomerHomeScreenState();
}

class _CustomerHomeScreenState extends State<CustomerHomeScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadInitialData();
    });
  }

  Future<void> _loadInitialData() async {
    final locProvider = Provider.of<LocationProvider>(context, listen: false);
    final prodProvider = Provider.of<ProductProvider>(context, listen: false);
    
    prodProvider.updateContext(context);
    
    // 📦 Load cached data first for instant offline access
    await prodProvider.loadCachedHomeData();

    await locProvider.fetchAddresses();
    
    final currentLat = locProvider.currentAddress?.latitude;
    final currentLng = locProvider.currentAddress?.longitude;
    
    await prodProvider.fetchHomeData(lat: currentLat, lng: currentLng, limit: 10);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final productProvider = Provider.of<ProductProvider>(context);
    final locationProvider = Provider.of<LocationProvider>(context);
    final isSearching = _searchController.text.isNotEmpty || productProvider.selectedCategory != 'All';

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: RefreshIndicator(
        onRefresh: () => _loadInitialData(),
        displacement: 40, 
        color: AppTheme.accentColor,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            _buildCollapsingHeader(productProvider, locationProvider),
            SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),
                  _buildCategories(productProvider),
                  const SizedBox(height: 12),
                  _buildProFilter(productProvider, locationProvider),
                  const SizedBox(height: 16), 
                  if (productProvider.isHomeLoading && productProvider.featuredProducts.isEmpty && productProvider.popularStores.isEmpty)
                    _buildHomeSkeletons()
                  else if (productProvider.error != null && productProvider.featuredProducts.isEmpty && productProvider.searchResults.isEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 100),
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(productProvider.error!, style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 12),
                            ElevatedButton(
                              onPressed: () => _loadInitialData(),
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      ),
                    )
                  else ...[
                    if (isSearching) ...[
                        _buildSectionHeader(
                          productProvider.isSearching ? 'Searching...' : 'Results in ${productProvider.selectedCategory}',
                          onTap: () {}
                        ),
                        if (!productProvider.isSearching && productProvider.searchResults.isEmpty)
                          const Padding(
                            padding: EdgeInsets.all(40.0),
                            child: Center(child: Text('No products found in this category.', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w600))),
                          )
                        else
                          _buildSearchResults(productProvider),
                    ] else ...[
                        // Featured Deals Section
                        if (productProvider.isFeaturedLoading && productProvider.featuredProducts.isEmpty)
                          _buildFeaturedSkeletons()
                        else if (productProvider.featuredProducts.isNotEmpty) ...[
                          _buildSectionHeader(
                            'Featured Deals', 
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const FeaturedProductsScreen()),
                            ),
                          ),
                          _buildFeaturedDeals(productProvider),
                        ],

                        // Popular Stores Section
                        if (productProvider.isStoresLoading && productProvider.popularStores.isEmpty)
                          _buildStoreSkeletons()
                        else if (productProvider.popularStores.isNotEmpty) ...[
                          _buildSectionHeader(
                            'Popular Stores Near You', 
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const StoresListScreen()),
                            ),
                          ),
                          _buildPopularStores(productProvider),
                        ],
                    ],
                  ],
                  const SizedBox(height: 120),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCollapsingHeader(ProductProvider provider, LocationProvider locProvider) {
    final topPadding = MediaQuery.of(context).padding.top;
    const collapsedHeight = 61.0;
    const searchSectionHeight = 64.0; 
    final expandedHeight = topPadding + collapsedHeight + searchSectionHeight;

    return SliverAppBar(
      pinned: true,
      expandedHeight: expandedHeight,
      collapsedHeight: collapsedHeight,
      backgroundColor: AppTheme.primaryColor,
      elevation: 0,
      automaticallyImplyLeading: false,
      flexibleSpace: LayoutBuilder(
        builder: (context, constraints) {
          final minHeight = collapsedHeight + topPadding;
          final expandRatio = ((constraints.maxHeight - minHeight) / (expandedHeight - minHeight))
              .clamp(0.0, 1.0);

          return ClipRect(
            child: Container(
              decoration: const BoxDecoration(
                color: AppTheme.primaryColor,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(24),
                  bottomRight: Radius.circular(24),
                ),
              ),
              child: Stack(
                fit: StackFit.expand,
                clipBehavior: Clip.hardEdge,
                children: [
                  Positioned(
                    top: -30,
                    right: -30,
                    child: Opacity(
                      opacity: expandRatio * 0.5,
                      child: Container(
                        width: 130,
                        height: 130,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.04),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.fromLTRB(20, topPadding + 6, 20, 12),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'TipsyTheoryy',
                                    style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: -0.5),
                                  ),
                                  Text(
                                    'Sip. Savour. Celebrate.',
                                    style: TextStyle(color: Colors.white60, fontSize: 11, fontWeight: FontWeight.w600),
                                  ),
                                ],
                              ),
                            ),
                            _buildLocationPicker(locProvider),
                          ],
                        ),
                        ClipRect(
                          child: Align(
                            alignment: Alignment.topCenter,
                            heightFactor: expandRatio,
                            child: Padding(
                              padding: const EdgeInsets.only(top: 16),
                              child: _buildSearchBar(provider),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildLocationPicker(LocationProvider locProvider, {bool compact = false}) {
    final currentAddress = locProvider.currentAddress;
    return GestureDetector(
      onTap: () => _showLocationSelection(context, locProvider),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: compact ? 8 : 10, vertical: compact ? 5 : 7),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: compact ? 0.15 : 0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.location_on, color: AppTheme.accentColor, size: 14),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                currentAddress?.name ?? 'Set Location',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: compact ? 10 : 11,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const Icon(Icons.keyboard_arrow_down, color: Colors.white70, size: 14),
          ],
        ),
      ),
    );
  }

  void _showLocationSelection(BuildContext context, LocationProvider locProvider) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).cardColor,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          minChildSize: 0.4,
          maxChildSize: 0.9,
          expand: false,
          builder: (context, scrollController) {
            return Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Delivery Address', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: isDark ? Colors.white : AppTheme.primaryColor)),
                  const SizedBox(height: 20),
                  ListTile(
                    onTap: () async {
                      await locProvider.captureCurrentLocation();
                      if (context.mounted) {
                        Navigator.pop(context);
                        _loadInitialData();
                      }
                    },
                    leading: const Icon(Icons.my_location, color: AppTheme.accentColor),
                    title: Text('Use Current Location', style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black)),
                    subtitle: Text('Locate me using GPS', style: TextStyle(color: isDark ? Colors.white38 : Colors.grey)),
                  ),
                  const Divider(),
                  Expanded(
                    child: locProvider.savedAddresses.isEmpty
                        ? Center(child: Text('No saved addresses yet', style: TextStyle(color: isDark ? Colors.white38 : Colors.grey)))
                        : ListView.builder(
                            controller: scrollController,
                            itemCount: locProvider.savedAddresses.length,
                            itemBuilder: (context, index) {
                              final addr = locProvider.savedAddresses[index];
                              return ListTile(
                                onTap: () {
                                  locProvider.setCurrentAddress(addr);
                                  Navigator.pop(context);
                                  _loadInitialData();
                                },
                                leading: const Icon(Icons.location_on_outlined, color: AppTheme.primaryColor),
                                title: Text(addr.name, style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black)),
                                subtitle: Text(addr.addressString, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: isDark ? Colors.white38 : Colors.grey)),
                                trailing: addr.id == locProvider.currentAddress?.id ? const Icon(Icons.check_circle, color: Colors.green) : null,
                              );
                            },
                          ),
                  ),
                ],
              ),
            );
          },
        );
      }
    );
  }

  Widget _buildSearchBar(ProductProvider provider) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      height: 48, 
      decoration: BoxDecoration(
        color: isDark ? Theme.of(context).cardColor : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: isDark ? [] : [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, 3),
          )
        ],
      ),
      child: TextField(
        controller: _searchController,
        onChanged: (val) => provider.search(val),
        style: TextStyle(color: isDark ? Colors.white : Colors.black87),
        decoration: InputDecoration(
          hintText: 'Search for drinks, brands...',
          hintStyle: TextStyle(color: isDark ? Colors.white24 : Colors.grey.shade400, fontSize: 13),
          prefixIcon: const Icon(Icons.search, color: AppTheme.primaryColor, size: 20),
          suffixIcon: const Padding(
            padding: EdgeInsets.all(10),
            child: Icon(Icons.tune, color: AppTheme.accentColor, size: 18),
          ),
          filled: true,
          fillColor: isDark ? Theme.of(context).cardColor : Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 0),
        ),
      ),
    );
  }

  Widget _buildCategories(ProductProvider provider) {
    final List<dynamic> categories = [
      {'id': 0, 'name': 'All'},
      ...provider.categories
    ];

    return SizedBox(
      height: 42,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final cat = categories[index];
          String catName;
          String? catIcon;

          if (cat is Map) {
            catName = cat['name'];
            catIcon = cat['icon'];
          } else if (cat is CategoryModel) {
            catName = cat.name;
            catIcon = cat.icon;
          } else {
            catName = cat.toString();
          }
          
          final isSelected = provider.selectedCategory == catName;
          return CategoryChip(
            name: catName,
            icon: catIcon,
            isSelected: isSelected,
            onTap: () => provider.setCategory(catName),
          );
        },
      ),
    );
  }

  Widget _buildProFilter(ProductProvider provider, LocationProvider locProvider) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => provider.toggleProOnly(
              locProvider.currentAddress?.latitude, 
              locProvider.currentAddress?.longitude
            ),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: provider.isProOnly ? AppTheme.primaryColor : (isDark ? Theme.of(context).cardColor : Colors.white),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: provider.isProOnly ? AppTheme.primaryColor : (isDark ? Colors.white12 : Colors.grey.shade300),
                  width: 1.5,
                ),
                boxShadow: (provider.isProOnly && !isDark) ? [
                  BoxShadow(color: AppTheme.primaryColor.withValues(alpha: 0.2), blurRadius: 8, offset: const Offset(0, 4))
                ] : [],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.verified_rounded, 
                    size: 16, 
                    color: provider.isProOnly ? Colors.white : (isDark ? Colors.white24 : Colors.grey.shade500)
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'PRO STORES',
                    style: TextStyle(
                      fontSize: 11, 
                      fontWeight: FontWeight.w900, 
                      letterSpacing: 0.5,
                      color: provider.isProOnly ? Colors.white : (isDark ? Colors.white38 : Colors.grey.shade600)
                    ),
                  ),
                  if (provider.isProOnly) ...[
                    const SizedBox(width: 6),
                    const Icon(Icons.close, size: 12, color: Colors.white70),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            provider.isProOnly ? 'Showing verified elite stores' : 'Filter by verified quality',
            style: TextStyle(color: isDark ? Colors.white24 : Colors.grey.shade400, fontSize: 11, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, {required VoidCallback onTap}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: isDark ? Colors.white : AppTheme.primaryColor),
          ),
          if (title != 'Searching...' && !title.startsWith('Results in'))
            GestureDetector(
              onTap: onTap,
              child: const Row(
                children: [
                  Text('View All', style: TextStyle(color: AppTheme.accentColor, fontWeight: FontWeight.bold, fontSize: 13)),
                  Icon(Icons.chevron_right, color: AppTheme.accentColor, size: 18),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFeaturedDeals(ProductProvider provider) {
    final cart = Provider.of<CartProvider>(context, listen: false);
    return SizedBox(
      height: 160, 
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: provider.featuredProducts.length,
        itemBuilder: (context, index) {
          final product = provider.featuredProducts[index];
          return Container(
            width: 300, 
            margin: const EdgeInsets.only(right: 12),
            child: ProductCard(
              product: product,
              isVertical: false,
              showAddButton: false, // 🛡️ Redirect to store context
              onView: () {
                final store = provider.popularStores.firstWhere(
                  (s) => s.id == product.storeId,
                  orElse: () => provider.popularStores.first, // Fallback
                );
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => StoreDetailScreen(store: store),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildSearchResults(ProductProvider provider) {
    final cart = Provider.of<CartProvider>(context, listen: false);
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: provider.searchResults.length,
      itemBuilder: (context, index) {
        final product = provider.searchResults[index];
        return ProductCard(
          product: product,
          showAddButton: false, // 🛡️ Force Store Context for radius/fee validation
          onView: () {
            final store = provider.popularStores.firstWhere(
              (s) => s.id == product.storeId,
              orElse: () => provider.popularStores.first,
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
    );
  }

  void _showClearCartDialog(BuildContext context, CartProvider cart, dynamic product, {double? deliveryFee}) {
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
              cart.addToCart(product, deliveryFee: deliveryFee);
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

  Widget _buildPopularStores(ProductProvider provider) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: provider.popularStores.length,
      itemBuilder: (context, index) {
        final store = provider.popularStores[index];
        return StoreCard(
          store: store,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => StoreDetailScreen(store: store),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHomeSkeletons() {
    return Column(
      children: [
        _buildFeaturedSkeletons(),
        _buildStoreSkeletons(),
      ],
    );
  }

  Widget _buildFeaturedSkeletons() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor = isDark ? AppTheme.darkShimmerBase : AppTheme.shimmerBase;
    final highlightColor = isDark ? AppTheme.darkShimmerHighlight : AppTheme.shimmerHighlight;

    return Column(
      children: [
        _buildSectionHeader('Featured Deals', onTap: () {}),
        SizedBox(
          height: 160,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: 2,
            itemBuilder: (_, __) => Shimmer.fromColors(
              baseColor: baseColor,
              highlightColor: highlightColor,
              child: Container(
                width: 300,
                margin: const EdgeInsets.only(right: 12),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStoreSkeletons() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor = isDark ? AppTheme.darkShimmerBase : AppTheme.shimmerBase;
    final highlightColor = isDark ? AppTheme.darkShimmerHighlight : AppTheme.shimmerHighlight;

    return Column(
      children: [
        _buildSectionHeader('Popular Stores', onTap: () {}),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20),
          itemCount: 3,
          itemBuilder: (_, __) => Shimmer.fromColors(
            baseColor: baseColor,
            highlightColor: highlightColor,
            child: Container(
              height: 100,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
            ),
          ),
        ),
      ],
    );
  }
}
