import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:geolocator/geolocator.dart';
import 'package:location/location.dart' as loc;
import 'package:geocoding/geocoding.dart';
import 'dart:async';
import '../core/api_client.dart';
import '../models/address_model.dart';

class LocationProvider with ChangeNotifier {
  final ApiClient _apiClient = ApiClient();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  List<AddressModel> _savedAddresses = [];
  AddressModel? _currentAddress;
  bool _isLoading = false;
  String? _error;

  final StreamController<AddressModel> _locationChangedController = StreamController<AddressModel>.broadcast();
  Stream<AddressModel> get onLocationChanged => _locationChangedController.stream;

  List<AddressModel> get savedAddresses => _savedAddresses;
  AddressModel? get currentAddress => _currentAddress;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchAddresses() async {
    // 🛡️ Guard: Only fetch if the user is a customer
    final role = await _storage.read(key: 'role');
    if (role != 'customer') return;

    _isLoading = true;
    notifyListeners();
    try {
      final response = await _apiClient.get('customer/addresses/');
      if (response.statusCode == 200) {
        _savedAddresses = (response.data as List)
            .map((item) => AddressModel.fromJson(item))
            .toList();

        if (_savedAddresses.isNotEmpty) {
          _currentAddress = _savedAddresses.firstWhere(
            (a) => a.isDefault,
            orElse: () => _savedAddresses.first
          );
        }
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Request permissions and capture location in one flow
  Future<bool> handleLocationPermission() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Test if location services are enabled.
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // 💡 Suggest turning on location services in-app (Android only)
      final location = loc.Location();
      serviceEnabled = await location.requestService();
      
      if (!serviceEnabled) {
        // Fallback for iOS or if in-app request fails/is cancelled
        _error = 'Location services are disabled. Please enable them to continue.';
        notifyListeners();
        return false;
      }
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        _error = 'Location permissions are denied';
        notifyListeners();
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      _error = 'Location permissions are permanently denied, we cannot request permissions.';
      notifyListeners();
      return false;
    }

    return true;
  }

  Future<void> captureCurrentLocation() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      bool hasPermission = await handleLocationPermission();
      if (!hasPermission) {
        _isLoading = false;
        notifyListeners();
        return;
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high
      );

      // Reverse geocoding
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude
      );

      String addressStr = "Unknown Location";
      String areaName = "Current Location";

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        // Building a more descriptive string
        addressStr = "${place.street}, ${place.subLocality}, ${place.locality}";
        areaName = place.subLocality?.isNotEmpty == true ? place.subLocality! : (place.locality ?? "Current");
      }

      final response = await _apiClient.post('customer/addresses/', data: {
        'name': areaName,
        'address_string': addressStr,
        'latitude': position.latitude,
        'longitude': position.longitude,
        'is_default': true,
      });

      if (response.statusCode == 201) {
        final newAddress = AddressModel.fromJson(response.data);
        _currentAddress = newAddress;
        _locationChangedController.add(newAddress);
        await fetchAddresses();
      }
    } catch (e) {
      _error = e.toString();
      print("Location capture error: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void setCurrentAddress(AddressModel address) async {
    // 🛡️ UI INSTANCY: Update local state immediately for instant feedback
    _currentAddress = address;
    
    // Update the isDefault flag on the local list immediately
    _savedAddresses = _savedAddresses.map((a) {
      return a.copyWith(isDefault: a.id == address.id);
    }).toList();
    
    _locationChangedController.add(address);
    notifyListeners();
    
    try {
      await _apiClient.patch('customer/addresses/${address.id}/', data: {'is_default': true});
      // Optionally re-fetch to sync with any server-side logic
      // await fetchAddresses(); 
    } catch (e) {
      _error = "Failed to update default address: $e";
      notifyListeners();
    }
  }

  Future<bool> deleteAddress(int addressId) async {
    _isLoading = true;
    notifyListeners();
    try {
      final response = await _apiClient.delete('customer/addresses/$addressId/');
      if (response.statusCode == 204 || response.statusCode == 200) {
        _savedAddresses.removeWhere((a) => a.id == addressId);
        if (_currentAddress?.id == addressId) {
          _currentAddress = _savedAddresses.isNotEmpty ? _savedAddresses.first : null;
        }
        return true;
      }
      return false;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
