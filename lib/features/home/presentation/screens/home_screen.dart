import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:massdrive/core/constants/app_colors.dart';
import 'package:massdrive/core/constants/app_typography.dart';
import 'package:massdrive/core/navigation/app_navigator.dart';
import 'package:massdrive/features/income/presentation/screens/income_screen.dart';
import 'package:massdrive/features/incoming_job/domain/models/incoming_job_model.dart';
import 'package:massdrive/features/incoming_job/presentation/controllers/incoming_job_controller.dart';
import 'package:massdrive/features/profile/presentation/screens/profile_screen.dart';
import 'package:massdrive/features/service_type/presentation/screens/service_type_screen.dart';
import 'package:massdrive/features/setting/presentation/screens/setting_screen.dart';

import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:massdrive/core/services/socket_service.dart';

class OnlineStatus extends Notifier<bool> {
  StreamSubscription<Position>? _positionStreamSubscription;

  @override
  bool build() {
    ref.onDispose(() {
      _positionStreamSubscription?.cancel();
    });
    return false;
  }

  Future<void> setStatus(bool value) async {
    if (value == state) return;

    final socketService = ref.read(socketServiceProvider);

    if (value) {
      // Check location permissions before going online
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return; // You might want to show a dialog here

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied || 
            permission == LocationPermission.deniedForever) {
          return;
        }
      }
      
      // Connect WebSocket
      await socketService.connect();
      
      // Send initial location
      try {
        final position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        );
        socketService.sendLocationUpdate(position.latitude, position.longitude);
      } catch (e) {
        debugPrint('Home Screen Initial Location Error: $e');
      }

      // Start stream
      _positionStreamSubscription = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 10, // Only send if moved 10 meters
        ),
      ).listen((Position position) {
        if (ref.read(socketServiceProvider).isConnected) {
          socketService.sendLocationUpdate(position.latitude, position.longitude);
        }
      });
      
      state = true;
    } else {
      // Go offline
      await _positionStreamSubscription?.cancel();
      _positionStreamSubscription = null;
      socketService.disconnect();
      state = false;
    }
  }
}

final onlineStatusProvider = NotifierProvider<OnlineStatus, bool>(
  () => OnlineStatus(),
);

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with TickerProviderStateMixin {
  late DraggableScrollableController _sheetController;
  GoogleMapController? _mapController;

  double _sheetSize = 0.35;

  final double _minSize = 0.25;
  final double _maxSize = 0.85;

  @override
  void initState() {
    super.initState();

    _sheetController = DraggableScrollableController();

    _sheetController.addListener(() {
      setState(() {
        _sheetSize = _sheetController.size;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(incomingJobControllerProvider, (previous, next) {
      if (next.isModalVisible &&
          next.currentJob != null &&
          (previous?.isModalVisible != true)) {
        // Push the new standalone screen
        context.push('/incoming-job');
      }
    });

    return Scaffold(
      backgroundColor: AppColors.semanticGrayNeutralFgWhite,
      body: Stack(children: [_buildMap(), _buildBottomSheet()]),
    );
  }

  // ================= MAP =================

  Widget _buildMap() {
    return SizedBox.expand(
      child: GoogleMap(
        onMapCreated: (controller) => _mapController = controller,
        initialCameraPosition: const CameraPosition(
          target: LatLng(13.7563, 100.5018),
          zoom: 14,
        ),
        myLocationEnabled: true,
        zoomControlsEnabled: false,
        myLocationButtonEnabled: false,
      ),
    );
  }

  // ================= BOTTOM SHEET =================

  Widget _buildBottomSheet() {
    return DraggableScrollableSheet(
      controller: _sheetController,
      initialChildSize: 0.40,
      minChildSize: _minSize,
      maxChildSize: _maxSize,
      snap: true,
      snapSizes: const [0.40, 0.85],
      builder: (context, scrollController) {
        return Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 26),
              decoration: const BoxDecoration(
                color: AppColors.semanticGrayNeutralFgHigh,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: SingleChildScrollView(
                controller: scrollController,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 22, 14, 40),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 40,
                          height: 5,
                          decoration: BoxDecoration(
                            color: AppColors.foundationAlphaWhite500,
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      _buildStatusCard(),
                      _buildMenuRow(),
                      const SizedBox(height: 500),
                    ],
                  ),
                ),
              ),
            ),

            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Center(child: _buildOnlineButton()),
            ),
          ],
        );
      },
    );
  }

  Widget _buildOnlineButton() {
    final isOnline = ref.watch(onlineStatusProvider);
    return GestureDetector(
      onTap: () {
        final current = ref.read(onlineStatusProvider);
        final newValue = !current;
        ref.read(onlineStatusProvider.notifier).setStatus(newValue);

        // Simulation: If online, trigger a fake job after 2.5s
        print(
          'newValue --> $newValue : $mounted : ${ref.read(onlineStatusProvider)}',
        );
        if (newValue) {
          Future.delayed(const Duration(milliseconds: 2500), () {
            if (mounted && ref.read(onlineStatusProvider)) {
              ref
                  .read(incomingJobControllerProvider.notifier)
                  .receiveJob(
                    const IncomingJobModel(
                      jobId: 'JOB_123',
                      pickupAddress: 'Katsuya (คัตสึยะ) หมูทอด',
                      pickupAddressDetail:
                          '4 4 / 1-4 / 2 4 / 4, แขวง ปทุมวัน, เขต ปทุมวัน, Central World, ห้อง เลข',
                      dropoffAddress: 'Katsuya (คัตสึยะ) หมูทอด',
                      dropoffAddressDetail:
                          '388 สยามสแควร์วัน ห้องเลขที่ SS 4011 ชั้นที่ 4 ถนนพระราม 1 แขวงปทุมวัน เขต',
                      netIncome: 37.0,
                      paymentMethod: 'เงินสด',
                      points: 18,
                      serviceType: 'GrabExpress (Bike) - Bag',
                      itemSummary: 'รายการ 1',
                      pickupDistanceKm: 0.39,
                      dropoffDistanceKm: 5.78,
                      pickupLat: 13.7563,
                      pickupLng: 100.5018,
                      dropoffLat: 13.7663,
                      dropoffLng: 100.5188,
                      timeoutSeconds: 15,
                    ),
                  );
            }
          });
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(40),
          gradient: LinearGradient(
            colors: isOnline
                ? [
                    AppColors.semanticSupportMintBgHigh,
                    AppColors.semanticSupportMintBgMid,
                    AppColors.semanticSupportMintBgHigh,
                  ]
                : [
                    AppColors.foundationOrange700,
                    AppColors.foundationOrange500,
                    AppColors.foundationOrange700,
                  ],
          ),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.4), blurRadius: 20),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.power_settings_new,
              color: AppColors.semanticGrayNeutralBgWhite,
            ),
            const SizedBox(width: 10),
            Text(
              isOnline ? "พร้อมรับงาน" : "ปิดรับงาน",
              style: AppTypography.heading5.copyWith(
                color: AppColors.semanticGrayNeutralBgWhite,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ================= STATUS CARD =================

  Widget _buildStatusCard() {
    final isOnline = ref.watch(onlineStatusProvider);
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.foundationAlphaWhite100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 6,
            backgroundColor: isOnline
                ? AppColors.semanticSupportMintBgHigh
                : AppColors.foundationOrange700,
          ),
          const SizedBox(width: 12),
          Text(
            isOnline ? "ระบบกำลังค้นหางาน...." : "คุณปิดรับงาน",
            style: AppTypography.caption3.copyWith(
              color: AppColors.semanticGrayNeutralBgWhite,
            ),
          ),
        ],
      ),
    );
  }

  // ================= MENU =================

  Widget _buildMenuRow() {
    return GridView.count(
      padding: EdgeInsets.symmetric(vertical: 16),
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      crossAxisCount: 4,
      crossAxisSpacing: 10,
      mainAxisSpacing: 2,
      childAspectRatio: 1,
      children: [
        _circleMenu(Icons.card_giftcard, "รายได้", () {
          AppNavigator.push(context, const IncomeScreen());
        }),
        _circleMenu(Icons.directions_car, "ประเภทบริการ", () {
          AppNavigator.push(context, const ServiceTypeScreen());
        }),
        _circleMenu(Icons.location_on, "ปลายทางของฉัน", () {}),
        _circleMenu(Icons.person_sharp, "โปรไฟล์", () {
          AppNavigator.push(context, const ProfileScreen());
        }),
        _circleMenu(Icons.settings_sharp, "การตั้งค่า", () {
          AppNavigator.push(context, const SettingScreen());
        }),
      ],
    );
  }

  Widget _circleMenu(IconData icon, String text, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(50),
      child: Column(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white10,
            ),
            child: Icon(icon, color: AppColors.foundationOrange700),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: 90,
            child: Text(
              text,
              textAlign: TextAlign.center,
              style: AppTypography.caption5.copyWith(
                color: AppColors.semanticGrayNeutralBgWhite,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
