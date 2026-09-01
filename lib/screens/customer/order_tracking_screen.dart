import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import '../../core/api_client.dart';
import '../../core/theme.dart';
import '../../models/order_model.dart';
import '../../services/map_service.dart';
import 'package:shimmer/shimmer.dart';
import 'chat_screen.dart';

class OrderTrackingScreen extends StatefulWidget {
  final int orderId;
  const OrderTrackingScreen({super.key, required this.orderId});

  @override
  State<OrderTrackingScreen> createState() => _OrderTrackingScreenState();
}

class _OrderTrackingScreenState extends State<OrderTrackingScreen> {
  final ApiClient _apiClient = ApiClient();
  final MapService _mapService = MapService();
  OrderModel? _order;
  bool _isLoading = true;
  String? _errorMessage;
  Timer? _pollTimer;
  GoogleMapController? _mapController;
  LatLng? _lastRiderPos;
  bool _isAutoCameraEnabled = true;
  List<LatLng> _polylinePoints = [];

  static const String _darkMapStyle = '''
[
  {
    "elementType": "geometry",
    "stylers": [
      {
        "color": "#122a22"
      }
    ]
  },
  {
    "elementType": "labels.text.fill",
    "stylers": [
      {
        "color": "#746855"
      }
    ]
  },
  {
    "elementType": "labels.text.stroke",
    "stylers": [
      {
        "color": "#122a22"
      }
    ]
  },
  {
    "featureType": "administrative",
    "elementType": "geometry.stroke",
    "stylers": [
      {
        "color": "#c9b2a6"
      }
    ]
  },
  {
    "featureType": "administrative.land_parcel",
    "elementType": "geometry.stroke",
    "stylers": [
      {
        "color": "#dcd2db"
      }
    ]
  },
  {
    "featureType": "administrative.province",
    "elementType": "geometry.stroke",
    "stylers": [
      {
        "color": "#72a281"
      }
    ]
  },
  {
    "featureType": "landscape.natural",
    "elementType": "geometry",
    "stylers": [
      {
        "color": "#122a22"
      }
    ]
  },
  {
    "featureType": "poi",
    "elementType": "geometry",
    "stylers": [
      {
        "color": "#122a22"
      }
    ]
  },
  {
    "featureType": "poi",
    "elementType": "labels.text.fill",
    "stylers": [
      {
        "color": "#93817c"
      }
    ]
  },
  {
    "featureType": "poi.park",
    "elementType": "geometry.fill",
    "stylers": [
      {
        "color": "#0d3b30"
      }
    ]
  },
  {
    "featureType": "poi.park",
    "elementType": "labels.text.fill",
    "stylers": [
      {
        "color": "#447530"
      }
    ]
  },
  {
    "featureType": "road",
    "elementType": "geometry",
    "stylers": [
      {
        "color": "#1b3d35"
      }
    ]
  },
  {
    "featureType": "road.arterial",
    "elementType": "geometry",
    "stylers": [
      {
        "color": "#1b3d35"
      }
    ]
  },
  {
    "featureType": "road.highway",
    "elementType": "geometry",
    "stylers": [
      {
        "color": "#1b3d35"
      }
    ]
  },
  {
    "featureType": "road.highway",
    "elementType": "geometry.stroke",
    "stylers": [
      {
        "color": "#1b3d35"
      }
    ]
  },
  {
    "featureType": "road.highway.controlled_access",
    "elementType": "geometry",
    "stylers": [
      {
        "color": "#1b3d35"
      }
    ]
  },
  {
    "featureType": "road.highway.controlled_access",
    "elementType": "geometry.stroke",
    "stylers": [
      {
        "color": "#1b3d35"
      }
    ]
  },
  {
    "featureType": "road.local",
    "elementType": "labels.text.fill",
    "stylers": [
      {
        "color": "#806b63"
      }
    ]
  },
  {
    "featureType": "transit.line",
    "elementType": "geometry",
    "stylers": [
      {
        "color": "#dfd2ae"
      }
    ]
  },
  {
    "featureType": "transit.line",
    "elementType": "labels.text.fill",
    "stylers": [
      {
        "color": "#8f7d77"
      }
    ]
  },
  {
    "featureType": "transit.line",
    "elementType": "labels.text.stroke",
    "stylers": [
      {
        "color": "#ebe3cd"
      }
    ]
  },
  {
    "featureType": "transit.station",
    "elementType": "geometry",
    "stylers": [
      {
        "color": "#dfd2ae"
      }
    ]
  },
  {
    "featureType": "water",
    "elementType": "geometry.fill",
    "stylers": [
      {
        "color": "#051410"
      }
    ]
  },
  {
    "featureType": "water",
    "elementType": "labels.text.fill",
    "stylers": [
      {
        "color": "#92998d"
      }
    ]
  }
]
''';

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

    try {
      final points = await _mapService.getRoutePolylines(riderPos, customerPos);
      if (mounted) {
        setState(() {
          _polylinePoints = points;
        });
      }
    } catch (e) {
      debugPrint("Error fetching route from MapService: $e");
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('Track Order #${widget.orderId}'),
        centerTitle: true,
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: _isLoading && _order == null
          ? _buildTrackingSkeleton(isDark)
          : _errorMessage != null
              ? Center(child: Text(_errorMessage!, style: TextStyle(color: isDark ? Colors.white70 : Colors.black87)))
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
                            if (_order?.requiresRiderVerification == true && _order?.status != 'delivered') 
                              _buildVerificationNotice(isDark),
                            const SizedBox(height: 30),
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton.icon(
                                onPressed: () {},
                                icon: const Icon(Icons.headset_mic_outlined, size: 18),
                                label: const Text('Contact Support'),
                                style: OutlinedButton.styleFrom(
                                  side: BorderSide(color: isDark ? Colors.white24 : AppTheme.primaryColor),
                                  foregroundColor: isDark ? Colors.white70 : AppTheme.primaryColor,
                                ),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
          infoWindow: InfoWindow(
            title: order.storeName ?? 'Liquor Store',
            snippet: 'Pickup Point',
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
        ),
      if (customerPos != null)
        Marker(
          markerId: const MarkerId('customer'),
          position: customerPos,
          infoWindow: const InfoWindow(
            title: 'My Location',
            snippet: 'Delivery Destination',
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
        ),
      if (riderPos != null)
        Marker(
          markerId: const MarkerId('rider'),
          position: riderPos,
          infoWindow: InfoWindow(
            title: order.riderName ?? 'Your Rider',
            snippet: 'On the way to you',
          ),
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
            style: isDark ? _darkMapStyle : null,
            onCameraMoveStarted: () {
              // If user starts moving the map manually, disable auto-camera
              if (_isAutoCameraEnabled) {
                setState(() => _isAutoCameraEnabled = false);
              }
            },
            onMapCreated: (controller) {
              _mapController = controller;
              _updateMapCamera();
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
                color: isDark ? Theme.of(context).cardColor : Colors.white.withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(20),
                boxShadow: isDark ? [] : [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 5)],
                border: isDark ? Border.all(color: Colors.white10) : null,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 8, height: 8,
                    decoration: const BoxDecoration(color: Colors.green, shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 6),
                  Text('Live Tracking', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: isDark ? Colors.white70 : AppTheme.primaryColor)),
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
    LatLng? storePos = (order.storeLatitude != null && order.storeLatitude != 0)
        ? LatLng(order.storeLatitude!, order.storeLongitude!)
        : null;
    LatLng? customerPos = (order.latitude != null && order.latitude != 0)
        ? LatLng(order.latitude!, order.longitude!)
        : null;

    if (riderPos != null && customerPos != null) {
      if (_lastRiderPos == null || _hasMovedSignificantly(_lastRiderPos!, riderPos)) {
        _fitBounds(_mapController!, [riderPos, customerPos]);
        _lastRiderPos = riderPos;
      }
    } else if (storePos != null && customerPos != null && _lastRiderPos == null) {
      // First time load with no rider yet
      _fitBounds(_mapController!, [storePos, customerPos]);
      _lastRiderPos = const LatLng(0, 0); // Sentinel to prevent repeated fits if no rider
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Theme.of(context).cardColor : const Color(0xFFE6F2F0),
        borderRadius: BorderRadius.circular(16),
        border: isDark ? Border.all(color: Colors.white10) : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(order.orderNumber, style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: isDark ? Colors.white : Colors.black87)),
                  const SizedBox(height: 6),
                  Text('Payment: ${_formatPaymentStatus(order.paymentStatus)}', style: TextStyle(fontSize: 13, color: isDark ? Colors.white70 : Colors.black87)),
                ],
              ),
              if (order.status != 'delivered' && order.status != 'cancelled')
                Stack(
                  children: [
                    IconButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ChatScreen(
                              orderId: order.id,
                              orderNumber: order.orderNumber,
                              recipientName: order.riderName ?? 'Rider',
                              recipientImage: order.riderImage,
                              recipientRating: order.riderRating,
                              recipientRole: 'Assigned Rider',
                            ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.chat_bubble_rounded, color: AppTheme.accentColor, size: 28),
                      style: IconButton.styleFrom(
                        backgroundColor: AppTheme.accentColor.withValues(alpha: 0.1),
                        padding: const EdgeInsets.all(12),
                      ),
                    ),
                    if (order.hasUnreadMessages)
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                        ),
                      ),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 6),
          Text('Status: ${_formatStatus(order.status)}', style: TextStyle(fontSize: 13, color: isDark ? Colors.white70 : Colors.black87)),
          const SizedBox(height: 6),
          Text('Total: KSh ${order.total.toStringAsFixed(0)}', style: TextStyle(fontSize: 13, color: isDark ? Colors.white : AppTheme.primaryColor, fontWeight: FontWeight.bold)),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return IntrinsicHeight(
      child: Row(
        children: [
          Column(
            children: [
              Icon(isCompleted ? Icons.check_circle : Icons.radio_button_unchecked, color: isCompleted ? AppTheme.accentColor : (isDark ? Colors.white10 : Colors.grey.shade300), size: 24),
              if (!isLast)
                Expanded(child: VerticalDivider(color: isCompleted ? AppTheme.accentColor : (isDark ? Colors.white10 : Colors.grey.shade300), thickness: 2)),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: isCompleted ? (isDark ? Colors.white : Colors.black) : (isDark ? Colors.white24 : Colors.grey))),
                  Text(subtitle, style: TextStyle(fontSize: 12, color: isDark ? Colors.white38 : Colors.grey)),
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

  Widget _buildVerificationNotice(bool isDark) {
    return Container(
      margin: const EdgeInsets.only(top: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.accentColor.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.accentColor.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          const Icon(Icons.badge_rounded, color: AppTheme.accentColor),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ID Verification Required',
                  style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: isDark ? Colors.white : AppTheme.primaryColor),
                ),
                const SizedBox(height: 4),
                Text(
                  'Please have your National ID or Passport ready for the rider upon arrival.',
                  style: TextStyle(fontSize: 12, color: isDark ? Colors.white38 : Colors.grey.shade600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrackingSkeleton(bool isDark) {
    final baseColor = isDark ? AppTheme.darkShimmerBase : Colors.grey.shade100;
    final highlightColor = isDark ? AppTheme.darkShimmerHighlight : Colors.white;

    return Column(
      children: [
        Shimmer.fromColors(
          baseColor: baseColor,
          highlightColor: highlightColor,
          child: Container(height: 250, color: Colors.white),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Shimmer.fromColors(
              baseColor: baseColor,
              highlightColor: highlightColor,
              child: Column(
                children: [
                  Container(height: 100, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16))),
                  const SizedBox(height: 32),
                  ...List.generate(4, (i) => Padding(
                    padding: const EdgeInsets.only(bottom: 20),
                    child: Row(
                      children: [
                        const CircleAvatar(radius: 12, backgroundColor: Colors.white),
                        const SizedBox(width: 16),
                        Container(width: 200, height: 14, color: Colors.white),
                      ],
                    ),
                  )),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
