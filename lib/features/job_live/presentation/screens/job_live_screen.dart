import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:massdrive/core/constants/app_colors.dart';
import 'package:massdrive/core/constants/app_typography.dart';
import 'package:massdrive/core/navigation/app_navigator.dart';
import 'package:massdrive/core/services/directions_service.dart';
import 'package:massdrive/core/services/socket_service.dart';
import 'package:massdrive/features/chat/presentation/screens/chat_screen.dart';
import 'package:massdrive/features/incoming_job/presentation/controllers/incoming_job_controller.dart';

enum JobLiveState { headingToPickup, arrivedAtPickup, headingToDropoff }

/// Maps a RIDE vertical status (SCRUM-45 §4) to the live trip stage so a
/// resumed job continues where it left off instead of restarting at pickup.
/// RIDE uses `ARRIVED_AT_PICK_UP` (middle underscore) — match it exactly.
JobLiveState jobLiveStageFromStatus(String? status) {
  switch (status?.toUpperCase()) {
    case 'ARRIVED_AT_PICK_UP':
      return JobLiveState.arrivedAtPickup;
    case 'PICKED_UP':
      return JobLiveState.headingToDropoff;
    case 'ACCEPTED':
    default:
      return JobLiveState.headingToPickup;
  }
}

class JobLiveScreen extends ConsumerStatefulWidget {
  /// Vertical status to resume from (from the active index). Null → fresh trip.
  final String? initialStatus;

  const JobLiveScreen({super.key, this.initialStatus});

  @override
  ConsumerState<JobLiveScreen> createState() => _JobLiveScreenState();
}

class _JobLiveScreenState extends ConsumerState<JobLiveScreen> {
  final DraggableScrollableController _sheetController =
      DraggableScrollableController();

  StreamSubscription? _socketSub;
  final DirectionsService _directionsService = DirectionsService();

  late JobLiveState _currentState =
      jobLiveStageFromStatus(widget.initialStatus);
  Set<Polyline> _polylines = {};

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadRoute();

      _socketSub = ref.read(socketServiceProvider).messages.listen((msg) {
        if (!mounted) return;
        if (msg.type == 'job_status') {
          final jobId = msg.data?['job_id'];
          final status = msg.data?['status'];
          final currentJobId = ref
              .read(incomingJobControllerProvider)
              .currentJob
              ?.jobId;

          if (currentJobId == jobId && status == 'CANCELLED') {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('ผู้โดยสารยกเลิกงานนี้แล้ว')),
            );
            context.go('/home');
          }
        }
      });
    });
  }

  /// Fetches the route polyline from Directions API based on current job state.
  /// Uses driver's current GPS location as origin.
  Future<void> _loadRoute() async {
    final currentJob = ref.read(incomingJobControllerProvider).currentJob;
    if (currentJob == null) return;

    // Try to get driver's current location as route origin
    LatLng origin;
    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
      origin = LatLng(position.latitude, position.longitude);
    } catch (_) {
      // Fallback to pickup if location unavailable
      origin = LatLng(currentJob.pickupLat, currentJob.pickupLng);
    }

    final pickupLatLng = LatLng(currentJob.pickupLat, currentJob.pickupLng);
    final dropoffLatLng = LatLng(currentJob.dropoffLat, currentJob.dropoffLng);

    // Determine destination based on current state
    final LatLng destination =
        (_currentState == JobLiveState.headingToDropoff)
            ? dropoffLatLng
            : pickupLatLng;

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
            color: AppColors.semanticSuccessBgHigh,
            width: 5,
            startCap: Cap.roundCap,
            endCap: Cap.roundCap,
            jointType: JointType.round,
          ),
      };
    });
  }

  /// Opens the external Google Maps app in turn-by-turn navigation mode,
  /// routing to the current destination (pickup or dropoff) by car.
  Future<void> _openGoogleMapsNavigation() async {
    final currentJob = ref.read(incomingJobControllerProvider).currentJob;

    LatLng? destination;
    if (currentJob != null) {
      destination = (_currentState == JobLiveState.headingToDropoff)
          ? LatLng(currentJob.dropoffLat, currentJob.dropoffLng)
          : LatLng(currentJob.pickupLat, currentJob.pickupLng);
    } else if (kDebugMode) {
      // No active job while testing — use a fixed destination so the
      // Google Maps launch can still be verified. Not used in release.
      destination = const LatLng(13.7563, 100.5018); // Bangkok
      debugPrint('NAV: no active job → using debug test destination');
    }

    if (destination == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ยังไม่มีงานที่กำลังทำอยู่')),
      );
      return;
    }

    final lat = destination.latitude;
    final lng = destination.longitude;

    // Android: launches directly into navigation mode.
    final Uri navUri = Uri.parse('google.navigation:q=$lat,$lng&mode=d');
    // Universal fallback (iOS / no navigation scheme available).
    final Uri fallbackUri = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&destination=$lat,$lng&travelmode=driving',
    );

    final bool canNav = await canLaunchUrl(navUri);
    debugPrint('NAV: dest=$lat,$lng  canLaunch(google.navigation)=$canNav');

    try {
      if (canNav) {
        await launchUrl(navUri, mode: LaunchMode.externalApplication);
      } else {
        final ok =
            await launchUrl(fallbackUri, mode: LaunchMode.externalApplication);
        debugPrint('NAV: fallback https launch result=$ok');
      }
    } catch (e) {
      debugPrint('NAV: launch error: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ไม่สามารถเปิดแอปนำทางได้')),
      );
    }
  }

  @override
  void dispose() {
    _socketSub?.cancel();
    _sheetController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.semanticGrayNeutralFgWhite,
      body: Stack(
        children: [
          _buildMap(),
          _buildTopDistanceBadge(),
          _buildRightFloatingButtons(),
          _buildBottomSheet(),
        ],
      ),
    );
  }

  /// =========================
  /// MAP
  /// =========================
  Widget _buildMap() {
    final currentJob = ref.watch(incomingJobControllerProvider).currentJob;

    // Fallback to Bangkok if no job (shouldn't happen on this screen)
    final LatLng pickupLatLng = currentJob != null
        ? LatLng(currentJob.pickupLat, currentJob.pickupLng)
        : const LatLng(13.7563, 100.5018);

    final LatLng dropoffLatLng = currentJob != null
        ? LatLng(currentJob.dropoffLat, currentJob.dropoffLng)
        : const LatLng(13.7563, 100.5018);

    Set<Marker> markers = {};
    LatLng target = pickupLatLng;

    if (_currentState == JobLiveState.headingToPickup ||
        _currentState == JobLiveState.arrivedAtPickup) {
      target = pickupLatLng;
      markers.add(
        Marker(
          markerId: const MarkerId('pickup'),
          position: pickupLatLng,
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueGreen,
          ),
        ),
      );
    } else {
      target = dropoffLatLng;
      markers.add(
        Marker(
          markerId: const MarkerId('dropoff'),
          position: dropoffLatLng,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        ),
      );
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

  /// =========================
  /// BOTTOM SHEET (PRODUCTION)
  /// =========================
  Widget _buildBottomSheet() {
    return DraggableScrollableSheet(
      initialChildSize: 0.45,
      minChildSize: 0.12,
      maxChildSize: 0.48,
      snap: true,
      snapSizes: const [0.12, 0.45, 0.48],
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
              _buildTripHeader(),
              const SizedBox(height: 20),
              _buildPassengerInfo(),
              const SizedBox(height: 20),
              _buildContactRow(),
              const SizedBox(height: 24),
              _buildArrivedButton(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTopDistanceBadge() {
    return Positioned(
      top: 70,
      left: 16,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.semanticGrayNeutralFgHigh.withOpacity(0.9),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Text(
          "570 ม.",
          style: AppTypography.heading4.copyWith(
            color: AppColors.semanticGrayNeutralFgWhite,
          ),
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
          _circleButton(
            Icons.navigation,
            onTap: _openGoogleMapsNavigation,
            color: AppColors.semanticSuccessBgHigh,
          ),
          const SizedBox(height: 12),
          _circleButton(Icons.shield_outlined),
          const SizedBox(height: 12),
          _circleButton(Icons.notifications_none),
        ],
      ),
    );
  }

  Widget _circleButton(IconData icon, {VoidCallback? onTap, Color? color}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          color: color ?? AppColors.semanticGrayNeutralFgHigh,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: AppColors.semanticGrayNeutralFgWhite),
      ),
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

  Widget _buildTripHeader() {
    final currentJob = ref.watch(incomingJobControllerProvider).currentJob;
    String headerText = "";
    Color headerColor = AppColors.semanticSuccessBgHigh;

    switch (_currentState) {
      case JobLiveState.headingToPickup:
        headerText = "กำลังไปรับผู้โดยสาร";
        break;
      case JobLiveState.arrivedAtPickup:
        headerText = "รอผู้โดยสาร";
        headerColor = AppColors.foundationOrange600;
        break;
      case JobLiveState.headingToDropoff:
        headerText = "กำลังไปส่งผู้โดยสาร";
        headerColor = AppColors.semanticSuccessBgHigh;
        break;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          headerText,
          style: AppTypography.heading4.copyWith(color: headerColor),
        ),
        const SizedBox(height: 4),
        Text(
          currentJob?.serviceType ?? "Saver Bike",
          style: AppTypography.body2.copyWith(color: Colors.white70),
        ),
      ],
    );
  }

  Widget _buildPassengerInfo() {
    final currentJob = ref.watch(incomingJobControllerProvider).currentJob;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          currentJob?.passengerName ?? "Passenger",
          style: AppTypography.heading4.copyWith(
            color: AppColors.semanticGrayNeutralFgWhite,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          _currentState == JobLiveState.headingToPickup ||
                  _currentState == JobLiveState.arrivedAtPickup
              ? (currentJob?.pickupAddress ?? "Pickup Address")
              : (currentJob?.dropoffAddress ?? "Dropoff Address"),
          style: AppTypography.caption3.copyWith(
            color: Colors.white70,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Text(
              "฿${currentJob?.netIncome.toInt() ?? 0}",
              style: AppTypography.heading3.copyWith(
                color: AppColors.semanticGrayNeutralFgWhite,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              currentJob?.paymentMethod ?? "เงินสด",
              style: AppTypography.heading6.copyWith(
                color: AppColors.semanticGrayNeutralFgWhite,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildContactRow() {
    final currentJob = ref.watch(incomingJobControllerProvider).currentJob;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _bottomAction(
          Icons.chat_bubble_outline,
          "แชท",
          onTap: currentJob == null
              ? null
              : () {
                  AppNavigator.push(
                    context,
                    ChatScreen(
                      jobId: currentJob.jobId,
                      passengerName: currentJob.passengerName,
                    ),
                  );
                },
        ),
        _bottomAction(Icons.phone_outlined, "โทรฟรี"),
        _bottomAction(Icons.help_outline, "ช่วยเหลือ"),
        _bottomAction(Icons.more_horiz, "อื่นๆ"),
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

  Widget _buildArrivedButton() {
    String buttonText = "";
    Color buttonColor = AppColors.semanticSuccessBgHigh;

    switch (_currentState) {
      case JobLiveState.headingToPickup:
        buttonText = "ถึงแล้ว";
        break;
      case JobLiveState.arrivedAtPickup:
        buttonText = "เริ่มเดินทาง";
        buttonColor = AppColors.semanticSuccessBgHigh;
        break;
      case JobLiveState.headingToDropoff:
        buttonText = "ส่งผู้โดยสาร";
        buttonColor = AppColors.semanticSuccessBgHigh;
        break;
    }

    return GestureDetector(
      onTap: () {
        final jobId = ref.read(incomingJobControllerProvider).currentJob?.jobId;
        final socket = ref.read(socketServiceProvider);

        setState(() {
          switch (_currentState) {
            case JobLiveState.headingToPickup:
              _currentState = JobLiveState.arrivedAtPickup;
              if (jobId != null) {
                socket.updateJobStatus(jobId, 'ARRIVED_AT_PICK_UP');
              }
              break;
            case JobLiveState.arrivedAtPickup:
              _currentState = JobLiveState.headingToDropoff;
              if (jobId != null) {
                socket.updateJobStatus(jobId, 'PICKED_UP');
              }
              break;
            case JobLiveState.headingToDropoff:
              if (jobId != null) {
                socket.updateJobStatus(jobId, 'COMPLETED');
              }
              context.push('/payment');
              break;
          }
        });
        // Reload route whenever state changes
        _loadRoute();
      },
      child: Container(
        width: double.infinity,
        height: 56,
        decoration: BoxDecoration(
          color: buttonColor,
          borderRadius: BorderRadius.circular(16),
        ),
        alignment: Alignment.center,
        child: Text(
          buttonText,
          style: AppTypography.heading5.copyWith(
            color: AppColors.semanticGrayNeutralFgWhite,
          ),
        ),
      ),
    );
  }
}
