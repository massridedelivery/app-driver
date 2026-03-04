import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:massdrive/core/constants/app_colors.dart';
import 'package:massdrive/core/constants/app_typography.dart';
import 'package:massdrive/core/navigation/app_navigator.dart';
import 'package:massdrive/core/services/socket_service.dart';
import 'package:massdrive/features/home/data/sources/home_api_service.dart';
import 'package:massdrive/features/income/presentation/screens/income_screen.dart';
import 'package:massdrive/features/incoming_job/presentation/controllers/incoming_job_controller.dart';
import 'package:massdrive/features/profile/presentation/screens/profile_screen.dart';
import 'package:massdrive/features/service_type/presentation/screens/service_type_screen.dart';
import 'package:massdrive/features/setting/presentation/screens/setting_screen.dart';

class OnlineStatus extends Notifier<bool> {
  StreamSubscription<Position>? _positionStreamSubscription;

  // Default Bangkok center for emulator testing
  static const double defaultLat = 13.7563;
  static const double defaultLng = 100.5018;

  @override
  bool build() {
    ref.listen(socketServiceProvider.select((s) => s.onConnectionStatus), (
      previous,
      next,
    ) {
      next.listen((connected) {
        if (connected && state) {
          debugPrint(
            'OnlineStatus: Connection successful and driver is online. Sending location_update.',
          );
          _sendInitialLocation();
        }
      });
    });

    ref.onDispose(() {
      _positionStreamSubscription?.cancel();
    });
    return false;
  }

  Future<void> _sendInitialLocation() async {
    try {
      final socketService = ref.read(socketServiceProvider);
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      if (socketService.isConnected) {
        socketService.sendLocationUpdate(position.latitude, position.longitude);

        // Center map on real location
        final controller = ref.read(mapControllerProvider);
        controller?.animateCamera(
          CameraUpdate.newLatLng(LatLng(position.latitude, position.longitude)),
        );
      }
    } catch (e) {
      debugPrint('OnlineStatus Initial Location Error: $e');
    }
  }

  Future<void> initStatus() async {
    try {
      final res = await ref.read(homeApiServiceProvider).fetchDriverStatus();
      if (res.isSuccessful && res.data != null) {
        final status = res.data['status'];
        if (status == 'online') {
          // If already online, skip the goOnline API call
          await setStatus(true, skipApiCall: true);
        } else {
          await setStatus(false);
        }
      }
    } catch (e) {
      debugPrint('Fetch Driver Status Error: $e');
    }
  }

  Future<void> setStatus(bool value, {bool skipApiCall = false}) async {
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

      // Set Online via API first (required by Backend to receive jobs/allow connection)
      // Skip if already online according to /api/driver/status
      if (!skipApiCall) {
        try {
          final res = await ref.read(homeApiServiceProvider).goOnline();
          if (!res.isSuccessful) {
            throw Exception('Failed to go online');
          }
        } catch (e) {
          debugPrint('Go Online API Error: $e');
          rethrow;
        }
      }

      // Connect WebSocket and wait for it to be ready
      await socketService.connect();

      // Send initial location - only after successful connection
      await _sendInitialLocation();

      // Start stream
      _positionStreamSubscription = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 10, // Only send if moved 10 meters
        ),
      ).listen((Position position) {
        if (ref.read(socketServiceProvider).isConnected) {
          socketService.sendLocationUpdate(
            position.latitude,
            position.longitude,
          );
        }
      });

      state = true;
    } else {
      // Go offline
      await _positionStreamSubscription?.cancel();
      _positionStreamSubscription = null;

      try {
        await ref.read(homeApiServiceProvider).goOffline();
      } catch (e) {
        debugPrint('Go Offline API Error: $e');
      }

      socketService.disconnect();
      state = false;
    }
  }
}

final onlineStatusProvider = NotifierProvider<OnlineStatus, bool>(
  () => OnlineStatus(),
);

class MapController extends Notifier<GoogleMapController?> {
  @override
  GoogleMapController? build() => null;

  void setController(GoogleMapController? controller) {
    state = controller;
  }
}

final mapControllerProvider =
    NotifierProvider<MapController, GoogleMapController?>(
      () => MapController(),
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

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(onlineStatusProvider.notifier).initStatus();
    });
  }

  @override
  Widget build(BuildContext context) {
    // Ensure IncomingJobController is initialized early to catch WebSocket messages
    ref.watch(incomingJobControllerProvider);

    return Scaffold(
      backgroundColor: AppColors.semanticGrayNeutralFgWhite,
      body: Stack(children: [_buildMap(), _buildBottomSheet()]),
    );
  }

  // ================= MAP =================

  Widget _buildMap() {
    return SizedBox.expand(
      child: GoogleMap(
        onMapCreated: (controller) {
          _mapController = controller;
          ref.read(mapControllerProvider.notifier).setController(controller);
        },
        initialCameraPosition: const CameraPosition(
          target: LatLng(OnlineStatus.defaultLat, OnlineStatus.defaultLng),
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
      onTap: () async {
        final current = ref.read(onlineStatusProvider);
        final newValue = !current;

        try {
          await ref.read(onlineStatusProvider.notifier).setStatus(newValue);

          if (mounted && newValue && ref.read(onlineStatusProvider)) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('เชื่อมต่อ WebSocket สำเร็จ พร้อมรับงานแล้ว'),
                backgroundColor: AppColors.semanticSuccessBgHigh,
              ),
            );
          }
        } catch (e) {
          print('error : $e');
          if (mounted && newValue) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('ไม่สามารถเปิดรับงานได้ กรุณาลองใหม่อีกครั้ง'),
                backgroundColor: AppColors.semanticErrorBgHigh,
              ),
            );
          }
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
