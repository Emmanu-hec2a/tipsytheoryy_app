import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import '../../core/theme.dart';
import '../../providers/product_provider.dart';
import '../../providers/location_provider.dart';
import '../../widgets/store_card.dart';
import 'store_detail_screen.dart';

class StoresListScreen extends StatefulWidget {
  const StoresListScreen({super.key});

  @override
  State<StoresListScreen> createState() => _StoresListScreenState();
}

class _StoresListScreenState extends State<StoresListScreen> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final productProvider = Provider.of<ProductProvider>(context);
    final locProvider = Provider.of<LocationProvider>(context);
    final stores = productProvider.popularStores;

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: AppTheme.primaryColor,
        elevation: 0,
        centerTitle: false,
        iconTheme: const IconThemeData(color: Colors.white),
        automaticallyImplyLeading: false,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('ALL STORES', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 18, letterSpacing: 1)),
            Text(
              locProvider.currentAddress?.name ?? 'Detecting location...',
              style: const TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () => productProvider.fetchHomeData(
          lat: locProvider.currentAddress?.latitude,
          lng: locProvider.currentAddress?.longitude,
        ),
        child: stores.isEmpty
            ? _buildShimmer(isDark)
            : ListView.builder(
                padding: const EdgeInsets.all(20),
                itemCount: stores.length,
                itemBuilder: (context, index) {
                  final store = stores[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 20),
                    child: StoreCard(
                      store: store,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => StoreDetailScreen(store: store),
                        ),
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }

  Widget _buildShimmer(bool isDark) {
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: 5,
      itemBuilder: (context, index) => Shimmer.fromColors(
        baseColor: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade200,
        highlightColor: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.white,
        child: Container(
          height: 200,
          margin: const EdgeInsets.only(bottom: 20),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
        ),
      ),
    );
  }
}
