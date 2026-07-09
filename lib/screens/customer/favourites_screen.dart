import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';
import '../../providers/favourite_provider.dart';
import '../../widgets/store_card.dart';
import 'store_detail_screen.dart';

class FavouritesScreen extends StatefulWidget {
  const FavouritesScreen({super.key});

  @override
  State<FavouritesScreen> createState() => _FavouritesScreenState();
}

class _FavouritesScreenState extends State<FavouritesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<FavouriteProvider>(context, listen: false).fetchFavourites();
    });
  }

  @override
  Widget build(BuildContext context) {
    final favProvider = Provider.of<FavouriteProvider>(context);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: AppTheme.primaryColor,
        elevation: 0,
        centerTitle: true,
        title: const Text('My Favourites', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 18)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: favProvider.isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryColor))
          : favProvider.favouriteStores.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  onRefresh: () => favProvider.fetchFavourites(),
                  child: ListView.builder(
                    padding: const EdgeInsets.all(20),
                    itemCount: favProvider.favouriteStores.length,
                    itemBuilder: (context, index) {
                      final store = favProvider.favouriteStores[index];
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
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(30),
            decoration: BoxDecoration(color: Colors.red.withValues(alpha: 0.05), shape: BoxShape.circle),
            child: Icon(Icons.favorite_rounded, size: 80, color: Colors.red.withValues(alpha: 0.2)),
          ),
          const SizedBox(height: 30),
          const Text(
            'Your collection is empty',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: AppTheme.primaryColor),
          ),
          const SizedBox(height: 10),
          const Text(
            'Heart your favourite stores to see them here.',
            style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
            ),
            child: const Text('DISCOVER STORES', style: TextStyle(fontWeight: FontWeight.w900)),
          ),
        ],
      ),
    );
  }
}
