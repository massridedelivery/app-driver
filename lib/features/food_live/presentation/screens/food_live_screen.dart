import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:massdrive/core/constants/app_colors.dart';
import 'package:massdrive/core/constants/app_typography.dart';
import 'package:massdrive/core/services/directions_service.dart';
import 'package:massdrive/core/services/socket_service.dart';
import 'package:massdrive/features/incoming_job/data/sources/food_delivery_api_service.dart';
import 'package:massdrive/features/incoming_job/presentation/controllers/incoming_job_controller.dart';
import 'package:massdrive/features/dependency_injection.dart';
import 'package:massdrive/core/navigation/app_navigator.dart';
import 'package:massdrive/features/chat/domain/entities/chat_vertical.dart';
import 'package:massdrive/features/chat/presentation/screens/chat_screen.dart';

/// Driver's active food delivery screen using REST API for state transitions.
///
/// Flow:
///   1. heading_to_restaurant → "ถึงร้านแล้ว" → arrive API
///   2. at_restaurant → "รับอาหารแล้ว" → POST /api/food/driver/orders/:id/picked-up
///   3. delivering → "ส่งอาหารสำเร็จ" → POST /api/food/driver/orders/:id/delivered

enum FoodLiveState { headingToRestaurant, atRestaurant, delivering }

class FoodLiveScreen extends ConsumerStatefulWidget {
  const FoodLiveScreen({super.key});

  @override
  ConsumerState<FoodLiveScreen> createState() => _FoodLiveScreenState();
}

class _FoodLiveScreenState extends ConsumerState<FoodLiveScreen> {
  StreamSubscription? _socketSub;
  FoodLiveState _currentState = FoodLiveState.headingToRestaurant;
  bool _isLoading = false;
  final DirectionsService _directionsService = DirectionsService();
  Set<Polyline> _polylines = {};

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadRoute();

      _socketSub = ref.read(socketServiceProvider).messages.listen((msg) {
        if (!mounted) return;
        if (msg.type == 'job_status' || msg.type == 'ORDER_STATUS_UPDATED') {
          final jobId = msg.data?['job_id'] ?? msg.data?['orderId'];
          final status = msg.data?['status'];
          final currentJobId = ref
              .read(incomingJobControllerProvider)
              .currentJob
              ?.jobId;

          if (currentJobId == jobId && status == 'CANCELLED') {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('ออเดอร์ถูกยกเลิกแล้ว')),
            );
            context.go('/home');
          }
        }
      });
    });
  }

  /// Fetches the route polyline from Directions API based on current food state.
  /// Uses driver's current GPS location as origin.
  Future<void> _loadRoute() async {
    final currentJob = ref.read(incomingJobControllerProvider).currentJob;
    if (currentJob == null) return;

    final restaurantLatLng = LatLng(currentJob.pickupLat, currentJob.pickupLng);
    final customerLatLng = LatLng(currentJob.dropoffLat, currentJob.dropoffLng);

    LatLng origin;
    LatLng destination;

    if (_currentState == FoodLiveState.delivering) {
      // Route: restaurant → customer
      origin = restaurantLatLng;
      destination = customerLatLng;
    } else {
      // Route: driver location → restaurant
      try {
        final position = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
          ),
        );
        origin = LatLng(position.latitude, position.longitude);
      } catch (_) {
        origin = restaurantLatLng;
      }
      destination = restaurantLatLng;
    }

    final points = await _directionsService.getRoutePolyline(
      origin: origin,
      destination: destination,
    );

    if (!mounted) return;
    setState(() {
      _polylines = {
        if (points.isNotEmpty)
          Polyline(
            polylineId: const PolylineId('route'),
            points: points,
            color: AppColors.foundationOrange600,
            width: 5,
            startCap: Cap.roundCap,
            endCap: Cap.roundCap,
            jointType: JointType.round,
          ),
      };
    });
  }

  @override
  void dispose() {
    _socketSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.semanticGrayNeutralFgWhite,
      body: Stack(
        children: [
          _buildMap(),
          _buildTopStatusBadge(),
          _buildRightFloatingButtons(),
          _buildBottomSheet(),
        ],
      ),
    );
  }

  // =========================================================================
  // MAP
  // =========================================================================
  Widget _buildMap() {
    final currentJob = ref.watch(incomingJobControllerProvider).currentJob;

    final LatLng pickupLatLng = currentJob != null
        ? LatLng(currentJob.pickupLat, currentJob.pickupLng)
        : const LatLng(13.7563, 100.5018);

    final LatLng dropoffLatLng = currentJob != null
        ? LatLng(currentJob.dropoffLat, currentJob.dropoffLng)
        : const LatLng(13.7563, 100.5018);

    Set<Marker> markers = {};
    LatLng target = pickupLatLng;

    if (_currentState == FoodLiveState.headingToRestaurant ||
        _currentState == FoodLiveState.atRestaurant) {
      target = pickupLatLng;
      markers.add(
        Marker(
          markerId: const MarkerId('restaurant'),
          position: pickupLatLng,
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueOrange,
          ),
        ),
      );
    } else {
      target = dropoffLatLng;
      markers.addAll({
        Marker(
          markerId: const MarkerId('restaurant'),
          position: pickupLatLng,
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueOrange,
          ),
        ),
        Marker(
          markerId: const MarkerId('customer'),
          position: dropoffLatLng,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        ),
      });
    }

    return GoogleMap(
      initialCameraPosition: CameraPosition(target: target, zoom: 16),
      markers: markers,
      polylines: _polylines,
      zoomControlsEnabled: false,
      myLocationButtonEnabled: false,
      myLocationEnabled: true,
      compassEnabled: false,
    );
  }

  // =========================================================================
  // BOTTOM SHEET
  // =========================================================================
  Widget _buildBottomSheet() {
    return DraggableScrollableSheet(
      initialChildSize: 0.52,
      minChildSize: 0.15,
      maxChildSize: 0.70,
      snap: true,
      snapSizes: const [0.15, 0.52, 0.70],
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: AppColors.semanticGrayNeutralFgMidOnBlack,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: ListView(
            controller: scrollController,
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
            children: [
              _buildDragIndicator(),
              const SizedBox(height: 16),
              _buildStatusTimeline(),
              const SizedBox(height: 20),
              _buildOrderInfo(),
              const SizedBox(height: 20),
              _buildOrderItemsList(),
              const SizedBox(height: 20),
              _buildContactRow(),
              const SizedBox(height: 24),
              _buildActionButton(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTopStatusBadge() {
    String badgeText;
    Color badgeColor;

    switch (_currentState) {
      case FoodLiveState.headingToRestaurant:
        badgeText = '1. เดินทางไปร้าน';
        badgeColor = AppColors.foundationOrange600;
        break;
      case FoodLiveState.atRestaurant:
        badgeText = '2. ถึงร้านแล้ว';
        badgeColor = AppColors.foundationAmber400;
        break;
      case FoodLiveState.delivering:
        badgeText = '3. กำลังส่ง';
        badgeColor = AppColors.semanticSuccessBgHigh;
        break;
    }

    return Positioned(
      top: 70,
      left: 16,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        decoration: BoxDecoration(
          color: badgeColor.withOpacity(0.95),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.fastfood, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Text(
              badgeText,
              style: AppTypography.heading6.copyWith(
                color: AppColors.semanticGrayNeutralFgWhite,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRightFloatingButtons() {
    return Positioned(
      right: 16,
      top: 160,
      child: Column(
        children: [
          _circleButton(Icons.shield_outlined),
          const SizedBox(height: 12),
          _circleButton(Icons.notifications_none),
        ],
      ),
    );
  }

  Widget _circleButton(IconData icon) {
    return Container(
      width: 52,
      height: 52,
      decoration: const BoxDecoration(
        color: AppColors.semanticGrayNeutralFgHigh,
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: AppColors.semanticGrayNeutralFgWhite),
    );
  }

  Widget _buildDragIndicator() {
    return Center(
      child: Container(
        width: 40,
        height: 4,
        decoration: BoxDecoration(
          color: Colors.white24,
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  // =========================================================================
  // STATUS TIMELINE (inspired by customer app)
  // =========================================================================
  Widget _buildStatusTimeline() {
    final currentJob = ref.watch(incomingJobControllerProvider).currentJob;

    int activeStep = 0;
    if (_currentState == FoodLiveState.atRestaurant) activeStep = 1;
    if (_currentState == FoodLiveState.delivering) activeStep = 2;

    String headerText;
    Color headerColor;

    switch (_currentState) {
      case FoodLiveState.headingToRestaurant:
        headerText = '1. กำลังเดินทางไปร้านอาหาร';
        headerColor = AppColors.foundationOrange500;
        break;
      case FoodLiveState.atRestaurant:
        headerText = '2. รอรับอาหารที่ร้าน';
        headerColor = AppColors.foundationAmber400;
        break;
      case FoodLiveState.delivering:
        headerText = '3. กำลังไปส่งอาหาร';
        headerColor = AppColors.semanticSuccessBgHigh;
        break;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          headerText,
          style: AppTypography.heading5.copyWith(color: headerColor),
        ),
        const SizedBox(height: 4),
        Text(
          currentJob?.serviceType ?? 'MassFood',
          style: AppTypography.body2.copyWith(color: Colors.white70),
        ),
        const SizedBox(height: 12),
        // Timeline bar
        Row(
          children: [
            _timelineIcon(Icons.storefront, 0 <= activeStep),
            _timelineLine(isActive: 0 < activeStep, isAnimating: 0 == activeStep),
            _timelineIcon(Icons.shopping_basket, 1 <= activeStep),
            _timelineLine(isActive: 1 < activeStep, isAnimating: 1 == activeStep),
            _timelineIcon(Icons.moped, 2 <= activeStep),
            _timelineLine(isActive: false, isAnimating: 2 == activeStep),
            _timelineIcon(Icons.location_on, false),
          ],
        ),
      ],
    );
  }

  Widget _timelineIcon(IconData icon, bool isActive) {
    final color = isActive
        ? AppColors.foundationOrange600
        : AppColors.foundationGrayscale600;

    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Icon(icon, size: 14, color: Colors.white),
    );
  }

  Widget _timelineLine({required bool isActive, bool isAnimating = false}) {
    return Expanded(
      child: Container(
        height: 3,
        margin: const EdgeInsets.symmetric(horizontal: 4),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(2),
          child: isAnimating
              ? LinearProgressIndicator(
                  backgroundColor: AppColors.foundationGrayscale800,
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    AppColors.foundationOrange500,
                  ),
                )
              : Container(
                  color: isActive
                      ? AppColors.foundationOrange500
                      : AppColors.foundationGrayscale800,
                ),
        ),
      ),
    );
  }

  // =========================================================================
  // ORDER INFO
  // =========================================================================
  Widget _buildOrderInfo() {
    final currentJob = ref.watch(incomingJobControllerProvider).currentJob;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Restaurant / Customer name
        Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.foundationOrange100.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                _currentState == FoodLiveState.delivering
                    ? Icons.person
                    : Icons.storefront,
                color: AppColors.foundationOrange500,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _currentState == FoodLiveState.delivering
                        ? (currentJob?.passengerName ?? 'Customer')
                        : (currentJob?.restaurantName ?? 'ร้านอาหาร'),
                    style: AppTypography.heading5.copyWith(
                      color: AppColors.semanticGrayNeutralFgWhite,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _currentState == FoodLiveState.delivering
                        ? (currentJob?.dropoffAddress ?? 'ที่อยู่ลูกค้า')
                        : (currentJob?.pickupAddress ?? 'ที่อยู่ร้าน'),
                    style: AppTypography.caption5.copyWith(
                      color: Colors.white54,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Fare info
        Row(
          children: [
            Text(
              '฿${currentJob?.netIncome.toInt() ?? 0}',
              style: AppTypography.heading3.copyWith(
                color: AppColors.semanticGrayNeutralFgWhite,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              currentJob?.paymentMethod ?? 'เงินสด',
              style: AppTypography.heading6.copyWith(
                color: AppColors.semanticGrayNeutralFgWhite,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // =========================================================================
  // ORDER ITEMS LIST
  // =========================================================================
  Widget _buildOrderItemsList() {
    final currentJob = ref.watch(incomingJobControllerProvider).currentJob;
    final items = currentJob?.orderItems ?? [];

    if (items.isEmpty) {
      if (currentJob?.itemSummary != null &&
          currentJob!.itemSummary.isNotEmpty) {
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              const Icon(Icons.receipt_long, color: AppColors.foundationOrange500, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'ออเดอร์: ${currentJob.itemSummary}',
                  style: AppTypography.caption4.copyWith(
                    color: AppColors.foundationOrange500,
                  ),
                ),
              ),
            ],
          ),
        );
      }
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.receipt_long, color: AppColors.foundationOrange500, size: 18),
              const SizedBox(width: 8),
              Text(
                'รายการอาหาร (${items.length} รายการ)',
                style: AppTypography.caption4.copyWith(
                  color: AppColors.foundationOrange500,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...items.map((item) {
            final name = item['name'] ?? '';
            final qty = item['qty'] ?? 1;
            final note = item['note'] as String?;

            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      color: AppColors.foundationOrange600,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '${qty}x',
                      style: AppTypography.support1.copyWith(
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: AppTypography.caption4.copyWith(
                            color: AppColors.semanticGrayNeutralFgWhite,
                          ),
                        ),
                        if (note != null && note.isNotEmpty)
                          Text(
                            note,
                            style: AppTypography.caption5.copyWith(
                              color: Colors.white38,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  // =========================================================================
  // CONTACT ROW
  // =========================================================================
  Widget _buildContactRow() {
    final currentJob = ref.watch(incomingJobControllerProvider).currentJob;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _bottomAction(
          Icons.chat_bubble_outline,
          'แชท',
          onTap: currentJob == null
              ? null
              : () {
                  AppNavigator.push(
                    context,
                    ChatScreen(
                      jobId: currentJob.jobId,
                      passengerName: currentJob.passengerName,
                      vertical: ChatVertical.food,
                    ),
                  );
                },
        ),
        _bottomAction(Icons.phone_outlined, 'โทรฟรี'),
        _bottomAction(Icons.help_outline, 'ช่วยเหลือ'),
        _bottomAction(Icons.more_horiz, 'อื่นๆ'),
      ],
    );
  }

  Widget _bottomAction(IconData icon, String label, {VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          children: [
            Icon(icon, color: Colors.white70),
            const SizedBox(height: 6),
            Text(
              label,
              style: AppTypography.caption4.copyWith(color: Colors.white70),
            ),
          ],
        ),
      ),
    );
  }

  // =========================================================================
  // ACTION BUTTON (uses REST API)
  // =========================================================================
  Widget _buildActionButton() {
    String buttonText;
    Color buttonColor;

    switch (_currentState) {
      case FoodLiveState.headingToRestaurant:
        buttonText = 'ถึงร้านแล้ว';
        buttonColor = AppColors.foundationOrange600;
        break;
      case FoodLiveState.atRestaurant:
        buttonText = 'รับอาหารแล้ว';
        buttonColor = AppColors.semanticSuccessBgHigh;
        break;
      case FoodLiveState.delivering:
        buttonText = 'ส่งอาหารสำเร็จ';
        buttonColor = AppColors.semanticSuccessBgHigh;
        break;
    }

    return GestureDetector(
      onTap: _isLoading ? null : _handleStateTransition,
      child: Container(
        width: double.infinity,
        height: 56,
        decoration: BoxDecoration(
          color: _isLoading ? buttonColor.withOpacity(0.5) : buttonColor,
          borderRadius: BorderRadius.circular(16),
        ),
        alignment: Alignment.center,
        child: _isLoading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Text(
                buttonText,
                style: AppTypography.heading5.copyWith(
                  color: AppColors.semanticGrayNeutralFgWhite,
                ),
              ),
      ),
    );
  }

  /// Handle state transitions using REST API calls
  Future<void> _handleStateTransition() async {
    final jobId = ref.read(incomingJobControllerProvider).currentJob?.jobId;
    if (jobId == null) return;

    setState(() => _isLoading = true);

    try {
      final apiService = getIt<FoodDeliveryApiService>();

      switch (_currentState) {
        case FoodLiveState.headingToRestaurant:
          // Driver arrived at restaurant — no specific food API for this,
          // use the socket to notify or just transition locally
          ref.read(socketServiceProvider).updateJobStatus(
            jobId,
            'ARRIVED_AT_RESTAURANT',
          );
          setState(() {
            _currentState = FoodLiveState.atRestaurant;
          });
          debugPrint('FoodLiveScreen: ✅ Arrived at restaurant');
          // Keep same route (still heading to restaurant area)
          break;

        case FoodLiveState.atRestaurant:
          // Driver picked up food → REST API
          await apiService.pickedUpOrder(jobId);
          setState(() {
            _currentState = FoodLiveState.delivering;
          });
          _loadRoute(); // Reload: restaurant → customer
          debugPrint('FoodLiveScreen: ✅ Food picked up via REST API');
          break;

        case FoodLiveState.delivering:
          // Driver delivered food → REST API
          await apiService.deliveredOrder(jobId);
          debugPrint('FoodLiveScreen: ✅ Food delivered via REST API');
          if (mounted) {
            context.push('/payment');
          }
          break;
      }
    } catch (e) {
      debugPrint('FoodLiveScreen: ❌ State transition error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('เกิดข้อผิดพลาด: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}
