import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import '../../core/api_client.dart';
import '../../core/theme.dart';
import '../../models/order_model.dart';

class OrderTrackingScreen extends StatefulWidget {
  final int orderId;
  const OrderTrackingScreen({super.key, required this.orderId});

  @override
  State<OrderTrackingScreen> createState() => _OrderTrackingScreenState();
}

class _OrderTrackingScreenState extends State<OrderTrackingScreen> {
  final ApiClient _apiClient = ApiClient();
  OrderModel? _order;
  bool _isLoading = true;
  String? _errorMessage;
  Timer? _pollTimer;
  GoogleMapController? _mapController;
  LatLng? _lastRiderPos;
  bool _isAutoCameraEnabled = true;
  List<LatLng> _polylinePoints = [];

  @override
  void initState() {
    super.initState();
    _loadOrder();
    _pollTimer = Timer.periodic(const Duration(seconds: 5), (_) => _loadOrder());
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  Future<void> _fetchRoute() async {
    final order = _order;
    if (order == null) return;

    LatLng? riderPos = (order.riderLatitude != null && order.riderLatitude != 0) 
        ? LatLng(order.riderLatitude!, order.riderLongitude!) : null;
    LatLng? customerPos = (order.latitude != null && order.latitude != 0) 
        ? LatLng(order.latitude!, order.longitude!) : null;

    if (riderPos == null || customerPos == null) return;

    final url = "https://router.project-osrm.org/route/v1/driving/${riderPos.longitude},${riderPos.latitude};${customerPos.longitude},${customerPos.latitude}?geometries=geojson";
    
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['routes'] != null && data['routes'].isNotEmpty) {
          final List coords = data['routes'][0]['geometry']['coordinates'];
          setState(() {
            _polylinePoints = coords.map((c) => LatLng(c[1], c[0])).toList();
          });
        }
      }
    } catch (e) {
      debugPrint("Error fetching customer route: $e");
    }
  }

  Future<void> _loadOrder() async {
    try {
      final response = await _apiClient.get('customer/orders/${widget.orderId}/');
      if (response.statusCode == 200 && mounted) {
        setState(() {
          _order = OrderModel.fromJson(response.data);
          _isLoading = false;
          _errorMessage = null;
        });

        _fetchRoute();

        if (_mapController != null && _order != null) {
          _updateMapCamera();
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Unable to load order status right now.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('Track Order #${widget.orderId}'),
        centerTitle: true,
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryColor))
          : _errorMessage != null
              ? Center(child: Text(_errorMessage!))
              : Column(
                  children: [
                    _buildMap(),
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          children: [
                            _buildOrderSummary(),
                            const SizedBox(height: 20),
                            _buildStatusStepper(),
                            const SizedBox(height: 30),
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton.icon(
                                onPressed: () {},
                                icon: const Icon(Icons.headset_mic_outlined, size: 18),
                                label: const Text('Contact Support'),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }

  Widget _buildMap() {
    final order = _order;
    if (order == null) return _buildMapPlaceholder();

    LatLng? riderPos = (order.riderLatitude != null && order.riderLatitude != 0) 
        ? LatLng(order.riderLatitude!, order.riderLongitude!) : null;
    LatLng? storePos = (order.storeLatitude != null && order.storeLatitude != 0) 
        ? LatLng(order.storeLatitude!, order.storeLongitude!) : null;
    LatLng? customerPos = (order.latitude != null && order.latitude != 0) 
        ? LatLng(order.latitude!, order.longitude!) : null;

    final markers = <Marker>{
      if (storePos != null)
        Marker(
          markerId: const MarkerId('store'),
          position: storePos,
          infoWindow: const InfoWindow(title: 'Pickup Store'),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
        ),
      if (customerPos != null)
        Marker(
          markerId: const MarkerId('customer'),
          position: customerPos,
          infoWindow: const InfoWindow(title: 'Delivery Address'),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
        ),
      if (riderPos != null)
        Marker(
          markerId: const MarkerId('rider'),
          position: riderPos,
          infoWindow: InfoWindow(title: order.riderName ?? 'Rider'),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
        ),
    };

    LatLng cameraTarget;
    if (riderPos != null) {
      cameraTarget = riderPos;
    } else if (storePos != null) {
      cameraTarget = storePos;
    } else if (customerPos != null) {
      cameraTarget = customerPos;
    } else {
      cameraTarget = const LatLng(-1.286389, 36.817223); // Nairobi
    }

    return SizedBox(
      height: 250,
      width: double.infinity,
      child: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(target: cameraTarget, zoom: 14),
            markers: markers,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            onCameraMoveStarted: () {
              // If user starts moving the map manually, disable auto-camera
              if (_isAutoCameraEnabled) {
                setState(() => _isAutoCameraEnabled = false);
              }
            },
            onMapCreated: (controller) {
              _mapController = controller;
              if (riderPos != null && customerPos != null) {
                _fitBounds(controller, [riderPos, customerPos, if (storePos != null) storePos]);
              }
            },
            polylines: {
              if (_polylinePoints.isNotEmpty)
                Polyline(
                  polylineId: const PolylineId('route'),
                  points: _polylinePoints,
                  color: AppTheme.accentColor,
                  width: 5,
                  jointType: JointType.round,
                  startCap: Cap.roundCap,
                  endCap: Cap.roundCap,
                ),
            },
          ),
          if (!_isAutoCameraEnabled)
            Positioned(
              bottom: 16,
              right: 16,
              child: FloatingActionButton.small(
                onPressed: () {
                  setState(() {
                    _isAutoCameraEnabled = true;
                    _lastRiderPos = null; // Force update
                  });
                  _updateMapCamera();
                },
                backgroundColor: AppTheme.primaryColor,
                child: const Icon(Icons.center_focus_strong, color: Colors.white, size: 18),
              ),
            ),
          Positioned(
            top: 12,
            left: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 5)],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 8, height: 8,
                    decoration: const BoxDecoration(color: Colors.green, shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 6),
                  const Text('Live Tracking', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.primaryColor)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _updateMapCamera() {
    final order = _order;
    if (order == null || _mapController == null || !_isAutoCameraEnabled) return;

    LatLng? riderPos = (order.riderLatitude != null && order.riderLatitude != 0)
        ? LatLng(order.riderLatitude!, order.riderLongitude!)
        : null;
    LatLng? customerPos = (order.latitude != null && order.latitude != 0)
        ? LatLng(order.latitude!, order.longitude!)
        : null;

    if (riderPos != null && customerPos != null) {
      if (_lastRiderPos == null || _hasMovedSignificantly(_lastRiderPos!, riderPos)) {
        _fitBounds(_mapController!, [riderPos, customerPos]);
        _lastRiderPos = riderPos;
      }
    }
  }

  bool _hasMovedSignificantly(LatLng p1, LatLng p2) {
    // Simple degree-based check (~80-100m)
    return (p1.latitude - p2.latitude).abs() > 0.0007 || 
           (p1.longitude - p2.longitude).abs() > 0.0007;
  }

  void _fitBounds(GoogleMapController controller, List<LatLng> points) {
    if (points.isEmpty) return;
    
    double minLat = points.first.latitude;
    double maxLat = points.first.latitude;
    double minLng = points.first.longitude;
    double maxLng = points.first.longitude;
    
    for (final p in points) {
      if (p.latitude < minLat) minLat = p.latitude;
      if (p.latitude > maxLat) maxLat = p.latitude;
      if (p.longitude < minLng) minLng = p.longitude;
      if (p.longitude > maxLng) maxLng = p.longitude;
    }
    
    final bounds = LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );
    
    Future.delayed(const Duration(milliseconds: 500), () {
      controller.animateCamera(CameraUpdate.newLatLngBounds(bounds, 50));
    });
  }

  Widget _buildMapPlaceholder() {
    return Container(
      height: 250,
      width: double.infinity,
      color: Colors.grey.shade100,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.map_outlined, size: 50, color: Colors.grey.shade300),
            const SizedBox(height: 8),
            Text('Live Tracking Map', style: TextStyle(color: Colors.grey.shade400)),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderSummary() {
    final order = _order;
    if (order == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFE6F2F0),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(order.orderNumber, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
          const SizedBox(height: 6),
          Text('Payment: ${_formatPaymentStatus(order.paymentStatus)}', style: const TextStyle(fontSize: 13, color: Colors.black87)),
          const SizedBox(height: 6),
          Text('Status: ${_formatStatus(order.status)}', style: const TextStyle(fontSize: 13, color: Colors.black87)),
          const SizedBox(height: 6),
          Text('Total: KSh ${order.total.toStringAsFixed(0)}', style: const TextStyle(fontSize: 13, color: AppTheme.primaryColor, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildStatusStepper() {
    final status = _order?.status ?? 'pending';
    final steps = [
      _buildStep('Order Confirmed', 'We have received your order', status != 'pending'),
      _buildStep('Rider Assigned', 'A rider will be assigned shortly', status == 'assigned' || status == 'picked_up' || status == 'arrived' || status == 'delivered'),
      _buildStep('Picked Up', 'Your order is on the way to you', status == 'picked_up' || status == 'arrived' || status == 'delivered'),
      _buildStep('Arrived', 'Rider is at your location', status == 'arrived' || status == 'delivered'),
      _buildStep('Delivered', 'Enjoy your drinks!', status == 'delivered', isLast: true),
    ];

    return Column(children: steps);
  }

  Widget _buildStep(String title, String subtitle, bool isCompleted, {bool isLast = false}) {
    return IntrinsicHeight(
      child: Row(
        children: [
          Column(
            children: [
              Icon(isCompleted ? Icons.check_circle : Icons.radio_button_unchecked, color: isCompleted ? AppTheme.accentColor : Colors.grey.shade300, size: 24),
              if (!isLast)
                Expanded(child: VerticalDivider(color: isCompleted ? AppTheme.accentColor : Colors.grey.shade300, thickness: 2)),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: isCompleted ? Colors.black : Colors.grey)),
                  Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.grey)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatStatus(String status) {
    switch (status) {
      case 'assigned':
        return 'Assigned to rider';
      case 'picked_up':
        return 'Picked up';
      case 'arrived':
        return 'Arrived';
      case 'delivered':
        return 'Delivered';
      default:
        return 'Pending confirmation';
    }
  }

  String _formatPaymentStatus(String status) {
    switch (status) {
      case 'paid':
        return 'Paid';
      case 'failed':
        return 'Failed';
      default:
        return 'Pending';
    }
  }
}
