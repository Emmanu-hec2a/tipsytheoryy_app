import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../core/api_client.dart';
import '../models/product_model.dart';
import '../models/store_model.dart';
import '../models/category_model.dart';

class ProductProvider with ChangeNotifier {
  BuildContext? _context;

  void updateContext(BuildContext context) {
    _context = context;
  }
  final ApiClient _apiClient = ApiClient();

  List<ProductModel> _featuredProducts = [];
  List<StoreModel> _popularStores = [];
  List<ProductModel> _searchResults = [];
  List<ProductModel> _storeProducts = [];
  List<CategoryModel> _categories = [];

  String _selectedCategory = 'All';
  bool _isLoading = false;
  bool _isSearching = false;
  bool _isProOnly = false;
  String? _error;

  List<ProductModel> get featuredProducts => _featuredProducts;
  List<StoreModel> get popularStores => _popularStores;
  List<ProductModel> get searchResults => _searchResults;
  List<ProductModel> get storeProducts => _storeProducts;
  List<CategoryModel> get categories => _categories;

  String get selectedCategory => _selectedCategory;
  bool get isLoading => _isLoading;
  bool get isSearching => _isSearching;
  bool get isProOnly => _isProOnly;
  String? get error => _error;

  void toggleProOnly(double? lat, double? lng) {
    _isProOnly = !_isProOnly;
    fetchHomeData(lat: lat, lng: lng);
  }

  Future<void> fetchHomeData({double? lat, double? lng}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      String storesPath = 'customer/stores/';
      List<String> queryParams = [];
      if (lat != null && lng != null) {
        queryParams.add("lat=$lat");
        queryParams.add("lng=$lng");
      }
      if (_isProOnly) {
        queryParams.add("is_pro_only=true");
      }

      if (queryParams.isNotEmpty) {
        storesPath += "?${queryParams.join('&')}";
      }

      final responses = await Future.wait([
        _apiClient.get('customer/products/?is_featured=true'),
        _apiClient.get(storesPath),
        _apiClient.get('customer/categories/'),
      ]);

      if (responses[0].statusCode == 200) {
        final List data = responses[0].data;
        _featuredProducts = data.map((json) => ProductModel.fromJson(json)).toList();
        _prefetchImages(_featuredProducts.map((p) => p.image).whereType<String>().toList());
      }

      if (responses[1].statusCode == 200) {
        final List data = responses[1].data;
        _popularStores = data.map((json) => StoreModel.fromJson(json)).toList();
        _prefetchImages(_popularStores.map((s) => s.logo).whereType<String>().toList());
      }

      if (responses[2].statusCode == 200) {
        final List data = responses[2].data;
        _categories = data.map((json) => CategoryModel.fromJson(json)).toList();
      }
    } catch (e) {
      _error = "Failed to load home data.";
      print("Home data error: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void _prefetchImages(List<String> urls) {
    if (_context == null) return;
    for (final url in urls) {
      precacheImage(CachedNetworkImageProvider(url), _context!);
    }
  }

  Future<void> fetchStoreProducts(int storeId) async {
    _isLoading = true;
    _storeProducts = [];
    notifyListeners();

    try {
      final response = await _apiClient.get('customer/products/?store_id=$storeId');
      if (response.statusCode == 200) {
        final List data = response.data;
        _storeProducts = data.map((json) => ProductModel.fromJson(json)).toList();
      }
    } catch (e) {
      print("Store products fetch error: $e");
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
