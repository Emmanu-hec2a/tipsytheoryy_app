import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter/services.dart';
import '../../core/theme.dart';
import '../../providers/rider_provider.dart';
import '../../models/order_model.dart';
import '../../services/map_service.dart';
import '../customer/chat_screen.dart';
import 'delivery_complete_screen.dart';

class ActiveDeliveryScreen extends StatefulWidget {
  const ActiveDeliveryScreen({super.key});

  @override
  State<ActiveDeliveryScreen> createState() => _ActiveDeliveryScreenState();
}

class _ActiveDeliveryScreenState extends State<ActiveDeliveryScreen> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;
  GoogleMapController? _mapController;
  final MapService _mapService = MapService();
  Position? _currentRiderPosition;
  List<LatLng> _polylinePoints = [];
  StreamSubscription<Position>? _positionStream;
  bool _isFollowing = true; // 🛡️ UBER/BOLT Style: Persistent Follow State

  @override
  void initState() {
    super.initState();
    _initRiderData();
    _startPositionTracking();
  }

  @override
  void dispose() {
    _positionStream?.cancel();
    super.dispose();
  }

  void _startPositionTracking() {
    const locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 10,
    );
    _positionStream = Geolocator.getPositionStream(locationSettings: locationSettings).listen((Position position) {
      if (mounted) {
        setState(() => _currentRiderPosition = position);
        _updateInAppNavigation(position);
      }
    });
  }

  void _updateInAppNavigation(Position position) {
    if (_mapController == null || !_isFollowing) return;
    
    // Auto-rotate and tilt the camera to face the direction of travel
    // This creates an "in-app navigation" feel
    try {
      _mapController!.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: LatLng(position.latitude, position.longitude),
            zoom: 17,
            tilt: 45,
            bearing: position.heading,
          ),
        ),
      );
    } catch (e) {
      debugPrint("Map animation failed: $e");
    }
    
    // Refresh route occasionally
    _fetchRoute();
  }

  Future<void> _initRiderData() async {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<RiderProvider>(context, listen: false).fetchRiderData();
    });
    
    try {
      final pos = await Geolocator.getCurrentPosition();
      setState(() => _currentRiderPosition = pos);
      _fetchRoute();
    } catch (e) {
      debugPrint("Couldn't get current position: $e");
    }
  }

  Future<void> _fetchRoute() async {
    final riderProvider = Provider.of<RiderProvider>(context, listen: false);
    final order = riderProvider.activeOrder;
    if (order == null || _currentRiderPosition == null) return;

    // 🛡️ Logic Check: Destination depends on delivery phase
    // 'assigned' = Heading to Store
    // 'picked_up' or 'arrived' = Heading to Customer
    final bool isHeadingToPickup = order.status.toLowerCase() == 'assigned';
    final double destLat = isHeadingToPickup ? (order.storeLatitude ?? 0) : (order.latitude ?? 0);
    final double destLng = isHeadingToPickup ? (order.storeLongitude ?? 0) : (order.longitude ?? 0);

    if (destLat == 0 || destLat < -90 || destLat > 90) {
      debugPrint("📍 Navigation: Destination coordinates are invalid ($destLat, $destLng)");
      return;
    }

    try {
      final points = await _mapService.getRoutePolylines(
        LatLng(_currentRiderPosition!.latitude, _currentRiderPosition!.longitude),
        LatLng(destLat, destLng),
      );
      if (mounted && points.isNotEmpty) {
        setState(() {
          _polylinePoints = points;
        });
      }
    } catch (e) {
      debugPrint("Error fetching route from MapService: $e");
    }
  }

  Future<void> _openMaps(double lat, double lng) async {
    final url = Uri.parse("google.navigation:q=$lat,$lng&mode=d");
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      final webUrl = Uri.parse("https://www.google.com/maps/dir/?api=1&destination=$lat,$lng&travelmode=driving");
      if (await canLaunchUrl(webUrl)) {
        await launchUrl(webUrl);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final riderProvider = Provider.of<RiderProvider>(context);
    final isOnline = riderProvider.isOnline;
    final activeOrder = riderProvider.activeOrder;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: AppTheme.primaryColor,
        elevation: 0,
        centerTitle: true,
        title: const Text('Active Navigation', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 18)),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: Row(
              children: [
                Text(isOnline ? 'ONLINE' : 'OFFLINE', style: TextStyle(color: isOnline ? Colors.greenAccent : Colors.white60, fontSize: 10, fontWeight: FontWeight.w900)),
                const SizedBox(width: 4),
                Switch(
                  value: isOnline,
                  onChanged: (val) => riderProvider.toggleAvailability(val),
                  activeColor: Colors.greenAccent,
                ),
              ],
            ),
          ),
        ],
      ),
      body: activeOrder == null
        ? _buildNoActiveTask(context)
        : Stack(
            children: [
              _buildMapView(activeOrder, isDark),
              _buildFloatingHeader(activeOrder),
              _buildDraggableDetails(activeOrder, riderProvider, isDark),
              _buildQuickPanicButton(riderProvider),
              if (!_isFollowing)
                _buildRecenterButton(),
            ],
          ),
    );
  }

  Widget _buildRecenterButton() {
    return Positioned(
      bottom: MediaQuery.of(context).size.height * 0.4 - 75,
      right: 16,
      child: FloatingActionButton.extended(
        onPressed: () {
          setState(() => _isFollowing = true);
          if (_currentRiderPosition != null) {
            _updateInAppNavigation(_currentRiderPosition!);
          }
        },
        backgroundColor: AppTheme.primaryColor,
        icon: const Icon(Icons.navigation_rounded, color: Colors.white, size: 20),
        label: const Text('RECENTER', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 11)),
      ),
    );
  }

  Widget _buildQuickPanicButton(RiderProvider provider) {
    return Positioned(
      bottom: MediaQuery.of(context).size.height * 0.4,
      right: 16,
      child: GestureDetector(
        onLongPressStart: (_) => HapticFeedback.mediumImpact(),
        onLongPress: () async {
          HapticFeedback.heavyImpact();
          final success = await provider.triggerPanic();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(success ? '🚨 EMERGENCY ALERTS SENT!' : 'Failed to send panic alert.'),
                backgroundColor: success ? Colors.red : Colors.orange,
              ),
            );
          }
        },
        child: Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: Colors.red,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(color: Colors.red.withValues(alpha: 0.3), blurRadius: 15, offset: const Offset(0, 5))
            ],
            border: Border.all(color: Colors.white, width: 3),
          ),
          child: const Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.white, size: 24),
              Text('SOS', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w900)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMapView(OrderModel order, bool isDark) {
    final bool isHeadingToPickup = order.status.toLowerCase() == 'assigned';
    
    LatLng? storePos = (order.storeLatitude != null && order.storeLatitude != 0 && order.storeLatitude! >= -90 && order.storeLatitude! <= 90) 
        ? LatLng(order.storeLatitude!, order.storeLongitude!) : null;
    LatLng? customerPos = (order.latitude != null && order.latitude != 0 && order.latitude! >= -90 && order.latitude! <= 90) 
        ? LatLng(order.latitude!, order.longitude!) : null;
    LatLng? riderPos = _currentRiderPosition != null 
        ? LatLng(_currentRiderPosition!.latitude, _currentRiderPosition!.longitude) : null;

    LatLng cameraTarget;
    if (isHeadingToPickup && storePos != null) {
      cameraTarget = storePos;
    } else if (customerPos != null) {
      cameraTarget = customerPos;
    } else if (riderPos != null) {
      cameraTarget = riderPos;
    } else {
      cameraTarget = const LatLng(-1.286389, 36.817223); // Nairobi fallback
    }

    final markers = <Marker>{
      if (storePos != null)
        Marker(
          markerId: const MarkerId('store'),
          position: storePos,
          infoWindow: InfoWindow(
            title: order.storeName ?? 'Pickup Store',
            snippet: isHeadingToPickup ? 'Head here for pickup' : 'Store Location',
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
        ),
      if (customerPos != null)
        Marker(
          markerId: const MarkerId('customer'),
          position: customerPos,
          infoWindow: InfoWindow(
            title: order.customerName ?? 'Customer',
            snippet: isHeadingToPickup ? 'Delivery Destination' : 'Drop-off here',
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
        ),
      if (riderPos != null)
        Marker(
          markerId: const MarkerId('rider'),
          position: riderPos,
          infoWindow: const InfoWindow(
            title: 'You',
            snippet: 'Rider Location',
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
        ),
    };

    return Listener(
      onPointerDown: (_) {
        // 🛡️ UBER/BOLT Logic: If user touches the map, pause following
        if (_isFollowing) setState(() => _isFollowing = false);
      },
      child: GoogleMap(
        initialCameraPosition: CameraPosition(
          target: cameraTarget,
          zoom: 15,
        ),
        myLocationEnabled: true,
        myLocationButtonEnabled: false, 
        zoomControlsEnabled: true,
        mapType: MapType.normal,
        padding: const EdgeInsets.only(bottom: 250), // 🛡️ Offset logical center so rider icon is above bottom sheet
        style: isDark ? AppTheme.midnightMapStyle : null,
        onCameraMoveStarted: () {
          // Keep empty if not needed, or add logic here
        },
        onMapCreated: (controller) {
          _mapController = controller;
          if (_isFollowing) {
            _updateCameraBounds(storePos, customerPos, riderPos, isHeadingToPickup);
          }
        },
        markers: markers,
        polylines: {
          if (_polylinePoints.isNotEmpty)
            Polyline(
              polylineId: const PolylineId('route'),
              points: _polylinePoints,
              color: isDark ? AppTheme.accentColor : AppTheme.primaryColor,
              width: 5,
              jointType: JointType.round,
              startCap: Cap.roundCap,
              endCap: Cap.roundCap,
            ),
        },
      ),
    );
  }

  void _updateCameraBounds(LatLng? store, LatLng? customer, LatLng? rider, bool isHeadingToPickup) {
    if (_mapController == null) return;

    List<LatLng> points = [];
    if (rider != null) points.add(rider);
    
    if (isHeadingToPickup) {
      if (store != null) points.add(store);
    } else {
      if (customer != null) points.add(customer);
    }

    if (points.length < 2) return;

    double minLat = points.first.latitude;
    double maxLat = points.first.latitude;
    double minLng = points.first.longitude;
    double maxLng = points.first.longitude;

    for (var p in points) {
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
      _mapController?.animateCamera(CameraUpdate.newLatLngBounds(bounds, 100));
    });
  }

  Widget _buildFloatingHeader(OrderModel order) {
    final bool isHeadingToPickup = order.status.toLowerCase() == 'assigned';
    final double? targetLat = isHeadingToPickup ? order.storeLatitude : order.latitude;
    final double? targetLng = isHeadingToPickup ? order.storeLongitude : order.longitude;

    return Positioned(
      top: 16,
      left: 16,
      right: 16,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 10)],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.navigation_rounded, color: Colors.white, size: 18),
                const SizedBox(width: 10),
                Text(
                  '#${order.orderNumber}',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 0.5),
                ),
              ],
            ),
          ),
          if (targetLat != null && targetLng != null && targetLat != 0)
            FloatingActionButton.small(
              onPressed: () => _openMaps(targetLat, targetLng),
              backgroundColor: Colors.white,
              child: const Icon(Icons.directions_rounded, color: AppTheme.primaryColor),
            ),
        ],
      ),
    );
  }

  Widget _buildDraggableDetails(OrderModel order, RiderProvider provider, bool isDark) {
    final bool isHeadingToPickup = order.status.toLowerCase() == 'assigned';

    return DraggableScrollableSheet(
      initialChildSize: 0.35,
      minChildSize: 0.15,
      maxChildSize: 0.8,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: isDark ? Theme.of(context).cardColor : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
            boxShadow: isDark ? [] : [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 20)],
            border: isDark ? Border.all(color: Colors.white10) : null,
          ),
          child: ListView(
            controller: scrollController,
            padding: const EdgeInsets.symmetric(horizontal: 24),
            children: [
              Center(
                child: Container(
                  margin: const EdgeInsets.only(top: 12, bottom: 20),
                  width: 40, height: 4,
                  decoration: BoxDecoration(color: isDark ? Colors.white10 : Colors.grey.shade200, borderRadius: BorderRadius.circular(2)),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                   Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isHeadingToPickup ? 'NEXT STEP: PICKUP' : 'NEXT STEP: DELIVERY', 
                        style: TextStyle(color: isDark ? Colors.white38 : Colors.grey, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 0.5)
                      ),
                      Text(
                        order.status.replaceAll('_', ' ').toUpperCase(), 
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: isDark ? Colors.white : AppTheme.primaryColor)
                      ),
                    ],
                  ),
                  if (order.requiresRiderVerification)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.red.withValues(alpha: 0.2)),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.verified_user_rounded, color: Colors.red, size: 14),
                          SizedBox(width: 6),
                          Text('ID CHECK REQ.', style: TextStyle(color: Colors.red, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
                        ],
                      ),
                    ),
                  if (order.customerPhone != null)
                    Row(
                      children: [
                        Stack(
                          children: [
                            GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => ChatScreen(
                                      orderId: order.id,
                                      orderNumber: order.orderNumber,
                                      recipientName: order.customerName ?? 'Customer',
                                      recipientImage: order.customerImage,
                                      recipientRole: 'Customer',
                                    ),
                                  ),
                                );
                              },
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(color: AppTheme.primaryColor.withValues(alpha: 0.1), shape: BoxShape.circle),
                                child: const Icon(Icons.chat_bubble_rounded, color: AppTheme.primaryColor),
                              ),
                            ),
                            if (order.hasUnreadMessages)
                              Positioned(
                                top: 0,
                                right: 0,
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
                        const SizedBox(width: 12),
                        GestureDetector(
                          onTap: () => launchUrl(Uri.parse('tel:${order.customerPhone}')),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(color: AppTheme.accentColor.withValues(alpha: 0.1), shape: BoxShape.circle),
                            child: const Icon(Icons.phone_in_talk_rounded, color: AppTheme.accentColor),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
              const SizedBox(height: 24),
              _buildAddressRow(
                context,
                Icons.storefront_rounded, 
                'PICKUP FROM', 
                order.storeName ?? 'Merchant Store', 
                isPickup: true,
                isActive: isHeadingToPickup
              ),
              Padding(
                padding: const EdgeInsets.only(left: 11),
                child: Align(alignment: Alignment.centerLeft, child: Text('⋮', style: TextStyle(color: isDark ? Colors.white10 : Colors.grey, fontSize: 18))),
              ),
              _buildAddressRow(
                context,
                Icons.location_on_rounded, 
                'DELIVER TO', 
                order.addressString ?? 'Customer Address',
                isActive: !isHeadingToPickup
              ),
              if (order.requiresRiderVerification && !isHeadingToPickup) ...[
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.amber.withValues(alpha: isDark ? 0.05 : 0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.amber.withValues(alpha: 0.2)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline_rounded, color: Colors.amber),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Age verification required. Please check the recipient\'s National ID or Passport.',
                          style: TextStyle(
                            fontSize: 12, 
                            fontWeight: FontWeight.w600, 
                            color: isDark ? Colors.amber.shade200 : Colors.amber.shade900
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: provider.isLoading ? null : () async {
                    final nextStatus = _getNextStatusValue(order.status);
                    if (nextStatus != null) {
                      if (nextStatus == 'delivered' && order.requiresRiderVerification) {
                        _showVerificationDialog(context, order, provider);
                        return;
                      }

                      final success = await provider.updateOrderStatus(order.id, nextStatus);
                      if (success && mounted) {
                        if (nextStatus == 'delivered') {
                          Navigator.push(context, MaterialPageRoute(builder: (_) => const DeliveryCompleteScreen()));
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Status updated to ${nextStatus.replaceAll('_', ' ').toUpperCase()}'), 
                              backgroundColor: AppTheme.primaryColor,
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        }
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                  ),
                  child: provider.isLoading 
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : Text(
                        _getActionText(order.status),
                        style: const TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1, color: Colors.white),
                      ),
                ),
              ),
              const SizedBox(height: 30),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAddressRow(BuildContext context, IconData icon, String label, String value, {bool isPickup = false, bool isActive = false}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      children: [
        Icon(icon, size: 22, color: isActive ? (isPickup ? AppTheme.primaryColor : AppTheme.accentColor) : (isDark ? Colors.white10 : Colors.grey.shade300)),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(color: isDark ? Colors.white24 : Colors.grey.shade400, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
              Text(
                value, 
                style: TextStyle(
                  fontSize: 14, 
                  fontWeight: FontWeight.w800, 
                  color: isActive ? (isDark ? Colors.white70 : const Color(0xFF1E293B)) : (isDark ? Colors.white10 : Colors.grey.shade400)
                ), 
                maxLines: 1, 
                overflow: TextOverflow.ellipsis
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNoActiveTask(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(30),
            decoration: BoxDecoration(color: isDark ? Colors.white.withValues(alpha: 0.05) : AppTheme.primaryColor.withValues(alpha: 0.05), shape: BoxShape.circle),
            child: Icon(Icons.navigation_outlined, size: 80, color: isDark ? Colors.white24 : AppTheme.primaryColor.withValues(alpha: 0.2)),
          ),
          const SizedBox(height: 30),
          Text('No Active Tasks', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: isDark ? Colors.white70 : AppTheme.primaryColor)),
          const SizedBox(height: 10),
          Text('Accepted orders will appear here for navigation.', style: TextStyle(color: isDark ? Colors.white38 : Colors.grey, fontWeight: FontWeight.w600)),
          const SizedBox(height: 30),
          ElevatedButton.icon(
            onPressed: () => Provider.of<RiderProvider>(context, listen: false).fetchRiderData(),
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('REFRESH QUEUE'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }

  String _getActionText(String status) {
    switch (status.toLowerCase()) {
      case 'assigned': return 'MARK AS PICKED UP';
      case 'picked_up': return 'MARK AS ARRIVED';
      case 'arrived': return 'COMPLETE DELIVERY';
      default: return 'GO TO NEXT TASK';
    }
  }

  String? _getNextStatusValue(String status) {
    switch (status.toLowerCase()) {
      case 'assigned': return 'picked_up';
      case 'picked_up': return 'arrived';
      case 'arrived': return 'delivered';
      default: return null;
    }
  }

  void _showVerificationDialog(BuildContext context, OrderModel order, RiderProvider provider) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.verified_user_rounded, color: AppTheme.accentColor, size: 28),
                SizedBox(width: 12),
                Text('Age Verification', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Please confirm the identity of the recipient for compliance.',
              style: TextStyle(color: isDark ? Colors.white38 : Colors.grey, fontSize: 14),
            ),
            const SizedBox(height: 24),
            _buildVerificationOption(
              context,
              'ID Matches Recipient',
              'Confirmed Face and ID Name',
              Icons.face_rounded,
              () => _completeWithVerification(context, order, provider, 'face_id_match'),
            ),
            const SizedBox(height: 12),
            _buildVerificationOption(
              context,
              'National ID Checked',
              'Verified DOB on Gov. Document',
              Icons.badge_rounded,
              () => _completeWithVerification(context, order, provider, 'national_id_check'),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildVerificationOption(BuildContext context, String title, String subtitle, IconData icon, VoidCallback onTap) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: isDark ? Colors.white10 : Colors.grey.shade200),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: AppTheme.primaryColor.withValues(alpha: 0.1), shape: BoxShape.circle),
              child: Icon(icon, color: AppTheme.primaryColor),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15)),
                  Text(subtitle, style: TextStyle(color: isDark ? Colors.white38 : Colors.grey, fontSize: 12)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  void _completeWithVerification(BuildContext context, OrderModel order, RiderProvider provider, String method) async {
    Navigator.pop(context); // Close sheet
    final success = await provider.updateOrderStatus(order.id, 'delivered', verificationMethod: method);
    if (success && mounted) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => const DeliveryCompleteScreen()));
    }
  }
}
