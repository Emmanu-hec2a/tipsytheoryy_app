import 'package:flutter/material.dart';
import '../core/api_client.dart';
import '../models/store_model.dart';

class FavouriteProvider with ChangeNotifier {
  final ApiClient _apiClient = ApiClient();
  List<StoreModel> _favouriteStores = [];
  bool _isLoading = false;
  String? _error;

  List<StoreModel> get favouriteStores => _favouriteStores;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchFavourites() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiClient.get('customer/stores/favourites/');
      if (response.statusCode == 200) {
        final List data = response.data;
        _favouriteStores = data.map((json) => StoreModel.fromJson(json)).toList();
      }
    } catch (e) {
      _error = "Failed to load favourites";
      debugPrint("Favourites Fetch Error: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> toggleFavourite(int storeId) async {
    try {
      final response = await _apiClient.post('customer/stores/$storeId/favourite/');
      if (response.statusCode == 200) {
        // Refresh local list if we are on the favourites screen
        await fetchFavourites();
        return true;
      }
    } catch (e) {
      debugPrint("Toggle Favourite Error: $e");
    }
    return false;
  }

  bool isStoreFavourite(int storeId) {
    return _favouriteStores.any((s) => s.id == storeId);
  }
}
