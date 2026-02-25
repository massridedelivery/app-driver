import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:massdrive/core/constants/app_colors.dart';
import 'package:massdrive/core/constants/app_typography.dart';
import 'package:massdrive/core/services/socket_service.dart';
import 'package:massdrive/features/incoming_job/presentation/controllers/incoming_job_controller.dart';

enum JobLiveState {
  headingToPickup,
  arrivedAtPickup,
  headingToDropoff,
}

class JobLiveScreen extends ConsumerStatefulWidget {
  const JobLiveScreen({super.key});

  @override
  ConsumerState<JobLiveScreen> createState() => _JobLiveScreenState();
}

class _JobLiveScreenState extends ConsumerState<JobLiveScreen> {
  final DraggableScrollableController _sheetController =
      DraggableScrollableController();

  StreamSubscription? _socketSub;

  final double _minSize = 0.12;
  final double _initialSize = 0.45;
  final double _maxSize = 0.85;

  double _currentSize = 0.45;
  JobLiveState _currentState = JobLiveState.headingToPickup;

  @override
  void initState() {
    super.initState();
    _sheetController.addListener(() {
      setState(() {
        _currentSize = _sheetController.size;
      });
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _socketSub = ref.read(socketServiceProvider).messages.listen((msg) {
        if (!mounted) return;
        if (msg.type == 'job_status') {
          final jobId = msg.data['job_id'];
          final status = msg.data['status'];
          final currentJobId = ref.read(incomingJobControllerProvider).currentJob?.jobId;
          
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
    final LatLng pickupLatLng = const LatLng(13.7815, 100.5435);
    final LatLng dropoffLatLng = const LatLng(13.7900, 100.5500);

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
      zoomControlsEnabled: false,
      myLocationButtonEnabled: false,
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

  /// =========================
  /// UI COMPONENTS (เหมือนของเดิม)
  /// =========================

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

  Widget _buildTripHeader() {
    String headerText = "";
    Color headerColor = AppColors.semanticSuccessBgHigh;

    switch (_currentState) {
      case JobLiveState.headingToPickup:
        headerText = "1. กำลังไปรับผู้โดยสาร";
        break;
      case JobLiveState.arrivedAtPickup:
        headerText = "2. รอผู้โดยสาร";
        headerColor = AppColors.foundationOrange600;
        break;
      case JobLiveState.headingToDropoff:
        headerText = "3. กำลังไปส่งผู้โดยสาร";
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
          "Saver Bike",
          style: AppTypography.body2.copyWith(color: Colors.white70),
        ),
      ],
    );
  }

  Widget _buildPassengerInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Prim Winurach",
          style: AppTypography.heading4.copyWith(
            color: AppColors.semanticGrayNeutralFgWhite,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          "เซเว่น อีเลฟเว่น พหลโยธิน ซอย 8\nถนนพหลโยธิน พญาไท กรุงเทพ 10400",
          style: AppTypography.caption3.copyWith(
            color: Colors.white70,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Text(
              "฿39",
              style: AppTypography.heading3.copyWith(
                color: AppColors.semanticGrayNeutralFgWhite,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              "เงินสด",
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
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _bottomAction(Icons.chat_bubble_outline, "แชท"),
        _bottomAction(Icons.phone_outlined, "โทรฟรี"),
        _bottomAction(Icons.help_outline, "ช่วยเหลือ"),
        _bottomAction(Icons.more_horiz, "อื่นๆ"),
      ],
    );
  }

  Widget _bottomAction(IconData icon, String label) {
    return Column(
      children: [
        Icon(icon, color: Colors.white70),
        const SizedBox(height: 6),
        Text(
          label,
          style: AppTypography.caption4.copyWith(color: Colors.white70),
        ),
      ],
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
              if (jobId != null) socket.updateJobStatus(jobId, 'ARRIVED_AT_PICKUP');
              break;
            case JobLiveState.arrivedAtPickup:
              _currentState = JobLiveState.headingToDropoff;
              if (jobId != null) socket.updateJobStatus(jobId, 'PICKED_UP');
              break;
            case JobLiveState.headingToDropoff:
              if (jobId != null) socket.updateJobStatus(jobId, 'COMPLETED');
              context.push('/payment');
              break;
          }
        });
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
