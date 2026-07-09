import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';
import '../../providers/product_provider.dart';
import '../../providers/location_provider.dart';
import '../../widgets/store_card.dart';
import 'store_detail_screen.dart';

class StoresListScreen extends StatelessWidget {
  const StoresListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final productProvider = Provider.of<ProductProvider>(context);
    final locProvider = Provider.of<LocationProvider>(context);
    final stores = productProvider.popularStores;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: AppTheme.primaryColor,
        elevation: 0,
        centerTitle: false,
        iconTheme: const IconThemeData(color: Colors.white),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Stores Near You',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.white),
            ),
            const SizedBox(height: 2),
            Row(
              children: [
                const Icon(Icons.location_on, size: 12, color: Colors.white70),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    locProvider.currentAddress?.name ?? 'Detecting...',
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.white70),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: () => productProvider.fetchHomeData(
              lat: locProvider.currentAddress?.latitude,
              lng: locProvider.currentAddress?.longitude,
            ),
            icon: const Icon(Icons.refresh_rounded, color: Colors.white),
          ),
        ],
      ),
      body: Column(
        children: [
          const SizedBox(height: 8),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => productProvider.fetchHomeData(
                lat: locProvider.currentAddress?.latitude,
                lng: locProvider.currentAddress?.longitude,
              ),
              child: stores.isEmpty
                ? const Center(child: Text('No stores found near your location.'))
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    physics: const BouncingScrollPhysics(),
                    itemCount: stores.length,
                    itemBuilder: (context, index) {
                      final store = stores[index];
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
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
