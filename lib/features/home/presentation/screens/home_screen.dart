import 'dart:async';

import 'package:dio/dio.dart' as dio_client;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:massdrive/common/widgets/indicator/default_circular_progress_indicator.dart';
import 'package:massdrive/core/constants/app_colors.dart';
import 'package:massdrive/core/constants/app_routes.dart';
import 'package:massdrive/core/constants/app_typography.dart';
import 'package:massdrive/core/navigation/app_navigator.dart';
import 'package:massdrive/core/services/location_service.dart';
import 'package:massdrive/core/services/socket_service.dart';
import 'package:massdrive/features/dependency_injection.dart';
import 'package:massdrive/features/home/data/sources/home_api_service.dart';
import 'package:massdrive/features/income/presentation/screens/income_screen.dart';
import 'package:massdrive/features/incoming_job/domain/models/incoming_job_model.dart';
import 'package:massdrive/features/incoming_job/presentation/controllers/incoming_job_controller.dart';
import 'package:massdrive/features/job_live/domain/models/active_item.dart';
import 'package:massdrive/features/job_live/domain/repositories/job_live_repository.dart';
import 'package:massdrive/features/profile/presentation/controllers/profile_controller.dart';
import 'package:massdrive/features/profile/presentation/screens/profile_screen.dart';
import 'package:massdrive/features/service_type/presentation/screens/service_type_screen.dart';
import 'package:massdrive/features/setting/presentation/screens/setting_screen.dart';
import 'package:shimmer/shimmer.dart';

class OnlineStatusState {
  final bool isOnline;
  final bool isLoading;

  const OnlineStatusState({this.isOnline = false, this.isLoading = false});

  OnlineStatusState copyWith({bool? isOnline, bool? isLoading}) {
    return OnlineStatusState(
      isOnline: isOnline ?? this.isOnline,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class OnlineStatus extends Notifier<OnlineStatusState> {
  // Default Bangkok center for emulator testing
  static const double defaultLat = 13.7563;
  static const double defaultLng = 100.5018;

  // Keep subscription so we can cancel it on dispose — prevents memory leak
  StreamSubscription<bool>? _connectionSubscription;

  @override
  OnlineStatusState build() {
    // Cancel previous subscription before creating a new one
    _connectionSubscription?.cancel();

    final socket = ref.read(socketServiceProvider);
    _connectionSubscription = socket.onConnectionStatus.listen((connected) {
      if (connected && state.isOnline) {
        if (kDebugMode) {
          debugPrint(
            'OnlineStatus: Connection successful and driver is online. Starting location updates.',
          );
        }
        ref.read(locationServiceProvider).startLocationUpdates();
      }
    });

    ref.onDispose(() {
      _connectionSubscription?.cancel();
      _connectionSubscription = null;
    });

    return const OnlineStatusState();
  }

  Future<void> initStatus(BuildContext context) async {
    state = state.copyWith(isLoading: true);
    try {
      final res = await ref.read(homeApiServiceProvider).fetchDriverStatus();
      if (res.isSuccessful && res.data != null) {
        final status = res.data['status']?.toString().toUpperCase();
        if (kDebugMode) debugPrint('OnlineStatus: Driver Initial Status (Normalized): $status');

        if (status == 'BUSY' || status == 'ON_TRIP') {
          // Check for active job and redirect
          await _checkAndRedirectToActiveJob(context);
        } else if (status == 'ONLINE') {
          await setStatus(true, skipApiCall: true);
        } else {
          await setStatus(false, skipApiCall: true);
        }
      }
    } catch (e) {
      if (kDebugMode) debugPrint('Fetch Driver Status Error: $e');
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> _checkAndRedirectToActiveJob(BuildContext context) async {
    try {
      final repo = getIt<JobLiveRepository>();

      double? lat;
      double? lng;
      try {
        final position = await Geolocator.getLastKnownPosition() ??
            await Geolocator.getCurrentPosition(
              timeLimit: const Duration(seconds: 3),
            );
        lat = position.latitude;
        lng = position.longitude;
      } catch (e) {
        if (kDebugMode) debugPrint('HomeScreen: Error fetching location for active check: $e');
      }

      // 1. Probe the cross-vertical index once (SCRUM-45) instead of firing
      //    every per-vertical endpoint and guessing which one wins.
      final active = await repo.getActiveSummary();

      if (active.isEmpty) {
        // No accepted job — recover a pending (pre-accept) offer if one exists.
        final offer = await repo.getActiveOffer(lat: lat, lng: lng);
        final offerJson = _extractJobJson(offer);
        if (offerJson != null && context.mounted) {
          final job = IncomingJobModel.fromJson(offerJson);
          ref.read(incomingJobControllerProvider.notifier).receiveJob(job);
          context.go(AppRoutes.incomingJobNamedPage);
        }
        return;
      }

      // Driver holds 0–1 active items; the list is newest-first.
      final item = active.first;
      if (kDebugMode) {
        debugPrint('OnlineStatus: active ${item.type} (${item.status}) → resuming');
      }

      // 2. Fetch full detail from the endpoint matching the item's vertical.
      dynamic detail;
      switch (item.type) {
        case ActiveJobType.ride:
          detail = await repo.getActiveJob(lat: lat, lng: lng);
          break;
        case ActiveJobType.food:
          detail = await repo.getActiveFoodOrder(lat: lat, lng: lng);
          break;
        case ActiveJobType.messenger:
        case ActiveJobType.unknown:
          if (kDebugMode) {
            debugPrint('OnlineStatus: type ${item.type} not supported yet');
          }
          return;
      }

      final jobJson = _extractJobJson(detail);
      if (jobJson == null) {
        if (kDebugMode) {
          debugPrint('OnlineStatus: active ${item.type} found but detail unparseable.');
        }
        return;
      }

      final job = IncomingJobModel.fromJson(jobJson);
      ref.read(incomingJobControllerProvider.notifier).resumeJob(job);

      if (!context.mounted) return;
      if (item.type == ActiveJobType.food) {
        context.go(AppRoutes.foodLiveNamedPage);
      } else {
        // Phase 3: hand the vertical status to the live screen so it resumes
        // at the correct trip stage instead of restarting at pickup.
        context.go('/job-live', extra: item.status);
      }
    } catch (e) {
      if (kDebugMode) debugPrint('OnlineStatus: Error checking active job: $e');
    }
  }

  /// Extracts the job/order JSON from a per-vertical detail response, which may
  /// be a bare object, a `{ "job": {...} }` wrapper, or a list.
  Map<String, dynamic>? _extractJobJson(dynamic data) {
    if (data is Map<String, dynamic>) {
      final job = data['job'];
      if (job is Map<String, dynamic>) return job;
      return data;
    }
    if (data is List && data.isNotEmpty) {
      final first = data.first;
      if (first is Map<String, dynamic>) return first;
    }
    return null;
  }

  Future<void> setStatus(
    bool value, {
    bool skipApiCall = false,
    bool force = false,
  }) async {
    if (value == state.isOnline && !force) return;

    final socketService = ref.read(socketServiceProvider);
    final locationService = ref.read(locationServiceProvider);

    state = state.copyWith(isLoading: true);

    try {
      if (value) {
        // Set Online via API first
        if (!skipApiCall) {
          try {
            final res = await ref.read(homeApiServiceProvider).goOnline();
            if (!res.isSuccessful) throw Exception('Failed to go online');
          } catch (e) {
            if (kDebugMode) debugPrint('Go Online API Error: $e');
            rethrow;
          }
        }

        // Connect WebSocket
        await socketService.connect();

        // Start location stream updates
        await locationService.startLocationUpdates();

        state = state.copyWith(isOnline: true);
      } else {
        // Go offline
        locationService.stopLocationUpdates();

        if (!skipApiCall) {
          try {
            await ref.read(homeApiServiceProvider).goOffline();
          } catch (e) {
            if (kDebugMode) debugPrint('Go Offline API Error: $e');
          }
        }

        socketService.disconnect();
        state = state.copyWith(isOnline: false);
      }
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }
}

final onlineStatusProvider = NotifierProvider<OnlineStatus, OnlineStatusState>(
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

  final double _minSize = 0.25;
  final double _maxSize = 0.85;

  @override
  void initState() {
    super.initState();

    _sheetController = DraggableScrollableController();
    // NOTE: Removed the _sheetSize listener — it was calling setState on every
    // pixel of scroll but _sheetSize was never used in build(), causing
    // unnecessary full widget-tree rebuilds.

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (kDebugMode) debugPrint('HomeScreen: initState - Calling fetchProfile()');
      final profileNotifier = ref.read(profileControllerProvider.notifier);
      await profileNotifier.fetchProfile();

      final profile = ref.read(profileControllerProvider).profile;
      if (kDebugMode) {
        debugPrint(
          'HomeScreen: fetchProfile() finished. Verified: ${profile?.isVerified}',
        );
      }

      if (profile?.isVerified == true) {
        if (kDebugMode) debugPrint('HomeScreen: Driver is verified. Calling initStatus()');
        if (mounted) ref.read(onlineStatusProvider.notifier).initStatus(context);
      } else {
        if (kDebugMode) debugPrint('HomeScreen: Driver is NOT verified. Skipping initStatus()');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final profileState = ref.watch(profileControllerProvider);
    final onlineStatus = ref.watch(onlineStatusProvider);
    final profile = profileState.profile;
    final isVerified = profile?.isVerified ?? false;

    // Ensure IncomingJobController is initialized early to catch WebSocket messages
    ref.watch(incomingJobControllerProvider);

    return Scaffold(
      backgroundColor: AppColors.semanticGrayNeutralFgWhite,
      body: Stack(
        children: [
          const _HomeMap(),
          Positioned(
            top: MediaQuery.of(context).padding.top + 16,
            right: 16,
            child: _buildSettingsButton(),
          ),
          profileState.isLoading || profileState.profile == null
              ? _buildSkeletonLoading()
              : (isVerified
                    ? _buildBottomSheet()
                    : _buildUnverifiedBottomSheet()),
          if (onlineStatus.isLoading)
            Container(
              color: Colors.black.withOpacity(0.3),
              child: const Center(child: DefaultCircularProgressIndicator()),
            ),
        ],
      ),
    );
  }

  Widget _buildSettingsButton() {
    return GestureDetector(
      onTap: () => context.push(AppRoutes.settingNamedPage),
      child: Container(
        height: 50,
        width: 50,
        decoration: BoxDecoration(
          color: AppColors.semanticGrayNeutralFgHigh.withOpacity(0.7),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: const Icon(
          Icons.settings_outlined,
          color: Colors.white,
          size: 26,
        ),
      ),
    );
  }

  Widget _buildSkeletonLoading() {
    return Align(
      alignment: Alignment.bottomCenter,
      child: Shimmer.fromColors(
        baseColor: const Color(0xFF1E2F38),
        highlightColor: const Color(0xFF2C3E4A),
        child: Container(
          width: double.infinity,
          height: 350,
          decoration: const BoxDecoration(
            color: Color(0xFF1E2F38),
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 32, 24, 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: const BoxDecoration(
                      color: Colors.white12,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    width: 200,
                    height: 28,
                    decoration: BoxDecoration(
                      color: Colors.white12,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    height: 16,
                    decoration: BoxDecoration(
                      color: Colors.white12,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: 180,
                    height: 16,
                    decoration: BoxDecoration(
                      color: Colors.white12,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 32),
                  Container(
                    width: double.infinity,
                    height: 56,
                    decoration: BoxDecoration(
                      color: Colors.white12,
                      borderRadius: BorderRadius.circular(28),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ================= UNVERIFIED UI =================

  Widget _buildUnverifiedBottomSheet() {
    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          color: Color(0xFF1E2F38), // Matches the premium dark blue from image
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          boxShadow: [
            BoxShadow(
              color: Colors.black54,
              blurRadius: 10,
              offset: Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 32, 24, 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.info_sharp, color: Colors.white70, size: 56),
                const SizedBox(height: 20),
                Text(
                  'ส่งเอกสารสมัครคนขับ',
                  style: AppTypography.heading3.copyWith(color: Colors.white),
                ),
                const SizedBox(height: 12),
                Text(
                  'ใกล้จะเสร็จแล้ว!\nโปรดยื่นเอกสารสมัครขับรถของคุณเพื่อเป็นคนขับ Mass\n\nติดต่อ 089-9999999',
                  textAlign: TextAlign.center,
                  style: AppTypography.caption4.copyWith(
                    color: Colors.white70,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.foundationOrange600,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(28),
                      ),
                      elevation: 0,
                    ),
                    onPressed: () {
                      context.push(
                        AppRoutes.documentRegistrationChecklistNamedPage,
                      );
                    },
                    child: Text(
                      'ไปที่ลงทะเบียนคนขับ',
                      style: AppTypography.caption3.copyWith(
                        color: AppColors.semanticGrayNeutralFgWhite,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ================= MAP =================

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
                      const _StatusCard(),
                      _buildMenuRow(),
                      const SizedBox(height: 500),
                    ],
                  ),
                ),
              ),
            ),

            const Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Center(child: _OnlineButton()),
            ),
          ],
        );
      },
    );
  }

  // ================= MENU =================

  Widget _buildMenuRow() {
    // Use a simple Row instead of GridView to avoid shrinkWrap layout cost
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _circleMenu(Icons.card_giftcard, "รายได้", () {
            AppNavigator.push(context, IncomeScreen());
          }),
          _circleMenu(Icons.directions_car, "ประเภทบริการ", () {
            AppNavigator.push(context, ServiceTypeScreen());
          }),
          _circleMenu(Icons.person_sharp, "โปรไฟล์", () {
            AppNavigator.push(context, ProfileScreen());
          }),
          _circleMenu(Icons.settings_sharp, "การตั้งค่า", () {
            AppNavigator.push(context, SettingScreen());
          }),
        ],
      ),
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

// ─────────────────────────────────────────────────────────────
// Extracted ConsumerWidgets — rebuild independently from HomeScreen
// ─────────────────────────────────────────────────────────────

/// Online/Offline toggle button — extracted so only this widget rebuilds
/// when onlineStatusProvider changes, not the entire HomeScreen tree.
class _OnlineButton extends ConsumerWidget {
  const _OnlineButton();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isOnline = ref.watch(onlineStatusProvider).isOnline;

    return GestureDetector(
      onTap: () async {
        final current = ref.read(onlineStatusProvider).isOnline;
        final newValue = !current;

        try {
          await ref.read(onlineStatusProvider.notifier).setStatus(newValue);

          if (context.mounted && newValue && ref.read(onlineStatusProvider).isOnline) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'พร้อมรับงานแล้ว',
                  style: AppTypography.label2.copyWith(
                    color: AppColors.semanticGrayNeutralBgWhite,
                  ),
                ),
                backgroundColor: AppColors.semanticSuccessBgHigh,
              ),
            );
          }
        } catch (e) {
          if (context.mounted && newValue) {
            bool isDocError = false;
            if (e is dio_client.DioException) {
              final resp = e.response;
              if (resp?.statusCode == 403) {
                final data = resp?.data;
                if (data is Map && data['code'] == 'documents_not_verified') {
                  isDocError = true;
                }
              }
            } else if (e.toString().contains('documents_not_verified') ||
                e.toString().contains('403')) {
              isDocError = true;
            }

            if (isDocError) {
              _showUnverifiedDocsDialogStatic(context);
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'ไม่สามารถเปิดรับงานได้ กรุณาลองใหม่อีกครั้ง',
                    style: AppTypography.label2.copyWith(
                      color: AppColors.semanticGrayNeutralBgWhite,
                    ),
                  ),
                  backgroundColor: AppColors.semanticErrorBgHigh,
                ),
              );
            }
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
}

/// Status text card ("ระบบกำลังค้นหางาน" / "คุณปิดรับงาน") — extracted so
/// only this widget rebuilds when online status changes.
class _StatusCard extends ConsumerWidget {
  const _StatusCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isOnline = ref.watch(onlineStatusProvider).isOnline;
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
}

// Reusable static dialog — called from _OnlineButton which is outside the
// _HomeScreenState, so we expose it as a top-level helper.
void _showUnverifiedDocsDialogStatic(BuildContext context) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (context) {
      return Container(
        decoration: const BoxDecoration(
          color: Color(0xFF1E2F38),
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.warning_amber_rounded,
              color: AppColors.foundationOrange500,
              size: 64,
            ),
            const SizedBox(height: 16),
            Text(
              'เอกสารของคุณยังไม่ได้รับการอนุมัติ',
              style: AppTypography.heading5.copyWith(color: Colors.white),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'กรุณาอัปโหลดเอกสารที่จำเป็นให้ครบถ้วนและรอการตรวจสอบให้เรียบร้อยเพื่อเริ่มต้นรับงาน',
              style: AppTypography.caption3.copyWith(
                color: Colors.white70,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.white30),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: Text(
                      'ยกเลิก',
                      style: AppTypography.label2.copyWith(color: Colors.white70),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      context.push(
                        AppRoutes.documentRegistrationChecklistNamedPage,
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.foundationOrange600,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      elevation: 0,
                    ),
                    child: Text(
                      'ตรวจสอบเอกสาร',
                      style: AppTypography.label2.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    },
  );
}

class _HomeMap extends ConsumerWidget {
  const _HomeMap();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SizedBox.expand(
      child: GoogleMap(
        onMapCreated: (controller) {
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
}
