import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'dart:async';
import '../core/api_client.dart';
import '../models/product_model.dart';
import '../models/store_model.dart';
import '../models/category_model.dart';

class ProductProvider with ChangeNotifier {
  BuildContext? _context;
  final ApiClient _apiClient = ApiClient();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  List<ProductModel> _featuredProducts = [];
  List<StoreModel> _popularStores = [];
  List<ProductModel> _searchResults = [];
  List<ProductModel> _storeProducts = [];
  List<CategoryModel> _categories = [];

  String _selectedCategory = 'All';
  bool _isLoading = false;
  bool _isFeaturedLoading = false;
  bool _isStoresLoading = false;
  bool _isCategoriesLoading = false;
  bool _isSearching = false;
  bool _isProOnly = false;
  String? _error;

  StreamSubscription? _locationSubscription;

  void updateContext(BuildContext context) {
    _context = context;
  }

  void listenToLocationChanges(dynamic locProvider) {
    _locationSubscription?.cancel();
    _locationSubscription = locProvider.onLocationChanged.listen((address) {
      debugPrint("🛰️ Store Sync: Location changed to ${address.name}. Re-fetching stores...");
      fetchHomeData(lat: address.latitude, lng: address.longitude, limit: 10);
    });
  }

  @override
  void dispose() {
    _locationSubscription?.cancel();
    super.dispose();
  }

  List<ProductModel> get featuredProducts => _featuredProducts;
  List<StoreModel> get popularStores => _popularStores;
  List<ProductModel> get searchResults => _searchResults;
  List<ProductModel> get storeProducts => _storeProducts;
  List<CategoryModel> get categories => _categories;

  String get selectedCategory => _selectedCategory;
  bool get isLoading => _isLoading;
  bool get isFeaturedLoading => _isFeaturedLoading;
  bool get isStoresLoading => _isStoresLoading;
  bool get isCategoriesLoading => _isCategoriesLoading;
  bool get isSearching => _isSearching;
  bool get isProOnly => _isProOnly;
  String? get error => _error;

  bool get isHomeLoading => _isFeaturedLoading || _isStoresLoading || _isCategoriesLoading;

  // --- 📦 OFFLINE PERSISTENCE ---

  Future<void> loadCachedHomeData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Load Featured Products
      final String? featuredJson = prefs.getString('cached_featured_products');
      if (featuredJson != null) {
        final List data = json.decode(featuredJson);
        _featuredProducts = data.map((j) => ProductModel.fromJson(j)).toList();
      }

      // Load Popular Stores
      final String? storesJson = prefs.getString('cached_popular_stores');
      if (storesJson != null) {
        final List data = json.decode(storesJson);
        _popularStores = data.map((j) => StoreModel.fromJson(j)).toList();
      }

      // Load Categories
      final String? categoriesJson = prefs.getString('cached_categories');
      if (categoriesJson != null) {
        final List data = json.decode(categoriesJson);
        _categories = data.map((j) => CategoryModel.fromJson(j)).toList();
      }

      if (featuredJson != null || storesJson != null || categoriesJson != null) {
        notifyListeners();
      }
    } catch (e) {
      debugPrint("Error loading cached data: $e");
    }
  }

  Future<void> loadCachedStoreProducts(int storeId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? cachedJson = prefs.getString('cached_products_store_$storeId');
      if (cachedJson != null) {
        final List data = json.decode(cachedJson);
        _storeProducts = data.map((j) => ProductModel.fromJson(j)).toList();
        notifyListeners();
      }
    } catch (e) {
      debugPrint("Error loading cached store products: $e");
    }
  }

  Future<void> _cacheData(String key, List<dynamic> list) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String jsonString = json.encode(list.map((item) => item.toJson()).toList());
      await prefs.setString(key, jsonString);
    } catch (e) {
      debugPrint("Error caching data ($key): $e");
    }
  }

  // --- 🌐 API FETCHING ---

  void toggleProOnly(double? lat, double? lng) {
    _isProOnly = !_isProOnly;
    fetchHomeData(lat: lat, lng: lng);
  }

  Future<void> fetchHomeData({double? lat, double? lng, int? limit}) async {
    // 🛡️ Guard: Only fetch if the user is a customer
    final role = await _storage.read(key: 'role');
    if (role != 'customer') return;

    _isLoading = true; 
    _isFeaturedLoading = true;
    _isStoresLoading = true;
    _isCategoriesLoading = true;
    _error = null;
    notifyListeners();

    try {
      // 🚀 Parallel Execution: Fetch all home data concurrently for speed
      final results = await Future.wait([
        _apiClient.get('customer/products/?is_featured=true'),
        _fetchStoresList(lat, lng, limit),
        _apiClient.get('customer/categories/'),
      ]);

      // 1. Process Featured Products
      final featuredResponse = results[0];
      if (featuredResponse.statusCode == 200) {
        final List data = featuredResponse.data;
        _featuredProducts = data.map((json) => ProductModel.fromJson(json)).toList();
        _prefetchImages(_featuredProducts.map((p) => p.image).whereType<String>().toList());
        _cacheData('cached_featured_products', _featuredProducts);
      }
      _isFeaturedLoading = false;

      // 2. Process Stores (Note: results[1] is the response from _fetchStoresList)
      // Actually _fetchStoresList returns Response
      final storesResponse = results[1];
      if (storesResponse.statusCode == 200) {
        final List data = storesResponse.data;
        _popularStores = data.map((json) => StoreModel.fromJson(json)).toList();
        _prefetchImages(_popularStores.map((s) => s.logo).whereType<String>().toList());
        _cacheData('cached_popular_stores', _popularStores);
      }
      _isStoresLoading = false;

      // 3. Process Categories
      final categoriesResponse = results[2];
      if (categoriesResponse.statusCode == 200) {
        final List data = categoriesResponse.data;
        _categories = data.map((json) => CategoryModel.fromJson(json)).toList();
        _cacheData('cached_categories', _categories);
      }
      _isCategoriesLoading = false;

    } catch (e) {
      debugPrint("Home Data Fetch Error: $e");
      _error = "Failed to update home data. Check your connection.";
      _isFeaturedLoading = false;
      _isStoresLoading = false;
      _isCategoriesLoading = false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<Response> _fetchStoresList(double? lat, double? lng, int? limit) async {
    String storesPath = 'customer/stores/';
    List<String> queryParams = [];
    if (lat != null && lng != null) {
      queryParams.add("lat=$lat");
      queryParams.add("lng=$lng");
    }
    if (_isProOnly) {
      queryParams.add("is_pro_only=true");
    }
    if (limit != null) {
      queryParams.add("limit=$limit");
    }
    if (queryParams.isNotEmpty) {
      storesPath += "?${queryParams.join('&')}";
    }
    return await _apiClient.get(storesPath);
  }


  void _prefetchImages(List<String> urls) {
    if (_context == null) return;
    for (final url in urls) {
      precacheImage(CachedNetworkImageProvider(url), _context!);
    }
  }

  Future<void> fetchStoreProducts(int storeId) async {
    // 🛡️ Pre-load from cache for instant UI in offline mode
    await loadCachedStoreProducts(storeId);

    _isLoading = _storeProducts.isEmpty; // Only show spinner if we have nothing cached
    notifyListeners();

    try {
      final response = await _apiClient.get('customer/products/?store_id=$storeId');
      if (response.statusCode == 200) {
        final List data = response.data;
        _storeProducts = data.map((json) => ProductModel.fromJson(json)).toList();
        
        // 💾 Update cache for next time
        _cacheData('cached_products_store_$storeId', _storeProducts);
      }
    } catch (e) {
      print("Store products fetch error: $e");
      _error = "Could not update menu. Showing offline version.";
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void setCategory(String category) {
    _selectedCategory = category;
    if (category == 'All') {
      _searchResults = [];
    } else {
      _fetchByCategory(category);
    }
    notifyListeners();
  }

  Future<void> _fetchByCategory(String category) async {
    _isSearching = true;
    notifyListeners();

    try {
      final response = await _apiClient.get('customer/products/?category_name=$category');
      if (response.statusCode == 200) {
        final List data = response.data;
        _searchResults = data.map((json) => ProductModel.fromJson(json)).toList();
      }
    } catch (e) {
      print("Category fetch error: $e");
    } finally {
      _isSearching = false;
      notifyListeners();
    }
  }

  Future<void> search(String query) async {
    if (query.isEmpty) {
      _searchResults = [];
      _isSearching = false;
      notifyListeners();
      return;
    }

    _isSearching = true;
    notifyListeners();

    try {
      final response = await _apiClient.get('customer/products/?search=$query');
      if (response.statusCode == 200) {
        final List data = response.data;
        _searchResults = data.map((json) => ProductModel.fromJson(json)).toList();
      }
    } catch (e) {
      print("Search error: $e");
    } finally {
      _isSearching = false;
      notifyListeners();
    }
  }
}
