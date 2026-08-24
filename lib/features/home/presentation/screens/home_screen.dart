import 'dart:async';

import 'package:dio/dio.dart' as dio_client;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:massdrive/common/widgets/indicator/mass_loading_m.dart';
import 'package:massdrive/core/constants/app_colors.dart';
import 'package:massdrive/core/constants/app_routes.dart';
import 'package:massdrive/core/constants/map_constants.dart';
import 'package:massdrive/core/constants/app_typography.dart';
import 'package:massdrive/core/theme/app_palette.dart';
import 'package:massdrive/core/navigation/app_navigator.dart';
import 'package:massdrive/core/services/location_service.dart';
import 'package:massdrive/core/services/socket_service.dart';
import 'package:massdrive/features/dependency_injection.dart';
import 'package:massdrive/features/home/data/sources/home_api_service.dart';
import 'package:massdrive/features/home/presentation/widgets/active_job_banner.dart';
import 'package:massdrive/features/income/presentation/controllers/wallet_controller.dart';
import 'package:massdrive/features/income/presentation/screens/income_screen.dart';
import 'package:massdrive/features/incoming_job/domain/models/incoming_job_model.dart';
import 'package:massdrive/features/incoming_job/presentation/controllers/incoming_job_controller.dart';
import 'package:massdrive/features/job_live/domain/models/active_item.dart';
import 'package:massdrive/features/job_live/domain/repositories/job_live_repository.dart';
import 'package:massdrive/features/job_live/domain/services/active_job_resolver.dart';
import 'package:massdrive/features/messenger/domain/repositories/messenger_repository.dart';
import 'package:massdrive/features/messenger/presentation/controllers/messenger_controller.dart';
import 'package:massdrive/features/document_registration/domain/models/registration_status.dart';
import 'package:massdrive/features/document_registration/presentation/controllers/registration_controller.dart';
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
        // Cross-vertical now (dev15): ride/food/messenger via the typed response.
        final offer = await repo.getActiveOffer(lat: lat, lng: lng);
        final route = applyRecoveredOffer(ref, offer);
        if (route != null && context.mounted) context.go(route);
        return;
      }

      // Driver holds 0–1 active items; the list is newest-first.
      final item = active.first;
      if (kDebugMode) {
        debugPrint('OnlineStatus: active ${item.type} (${item.status}) → resuming');
      }

      // Messenger has its own model/screen — resume it directly (SCRUM-41).
      if (item.type == ActiveJobType.messenger) {
        final order = await getIt<MessengerRepository>().getActiveOrder();
        if (order == null) return;
        ref.read(messengerControllerProvider.notifier).setActiveOrder(order);
        if (context.mounted) context.go('/messenger-live');
        return;
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
  // Cap the sheet at its resting size — there's no extra content to reveal, so
  // dragging it taller only exposed empty panel space.
  final double _maxSize = 0.40;

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
        // Load the registration status (reads /api/driver/documents) so the
        // home can show "กำลังดำเนินการตรวจสอบข้อมูล" once the driver has
        // submitted, rather than the "register now" CTA.
        if (mounted) {
          ref.read(registrationControllerProvider.notifier).fetchStatus();
        }
      }
    });
  }

  @override
  void dispose() {
    _sheetController.dispose();
    // Drop the app-wide GoogleMapController reference so the native map can be
    // released instead of being held for the app's lifetime.
    final mapController = ref.read(mapControllerProvider);
    mapController?.dispose();
    ref.read(mapControllerProvider.notifier).setController(null);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final profileState = ref.watch(profileControllerProvider);
    final onlineStatus = ref.watch(onlineStatusProvider);
    final profile = profileState.profile;
    final isVerified = profile?.isVerified ?? false;
    // "Under review" comes from the registration status, which is derived from
    // GET /api/driver/documents (see fetchRegistrationStatus). We can't use
    // profile.documents here — the /api/driver/profile payload leaves that list
    // empty for a submitted-but-unverified driver, so it would wrongly show the
    // "register now" CTA. fetchStatus() is kicked off in initState when unverified.
    final regStatus = ref
        .watch(registrationControllerProvider)
        .overallStatus;
    final inReview =
        !isVerified && regStatus == RegistrationStateStatus.inReview;

    // Ensure the offer controllers are initialized early to catch WebSocket
    // messages (job_offer / food_delivery_offer / messenger_offer).
    ref.watch(incomingJobControllerProvider);
    ref.watch(messengerControllerProvider);

    return Scaffold(
      backgroundColor: context.palette.textPrimary,
      body: Stack(
        children: [
          const _HomeMap(),
          Positioned(
            top: MediaQuery.of(context).padding.top + 16,
            right: 16,
            child: _buildSettingsButton(),
          ),
          Positioned(
            top: MediaQuery.of(context).padding.top + 76,
            right: 16,
            child: const _RecenterButton(),
          ),
          // Persistent indicator when the driver has a job in progress.
          Positioned(
            top: MediaQuery.of(context).padding.top + 136,
            left: 16,
            right: 16,
            child: const ActiveJobBanner(),
          ),
          profileState.isLoading || profileState.profile == null
              ? _buildSkeletonLoading()
              : (isVerified
                    ? _buildBottomSheet()
                    : (inReview
                          ? _buildInReviewBottomSheet()
                          : _buildUnverifiedBottomSheet())),
          if (onlineStatus.isLoading)
            Container(
              color: Colors.black.withOpacity(0.3),
              child: const Center(child: MassLoadingM(size: 72)),
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
          color: context.palette.bg.withOpacity(0.7),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(
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
        baseColor: context.palette.sheet,
        highlightColor: context.palette.sheetAlt,
        child: Container(
          width: double.infinity,
          height: 350,
          decoration: BoxDecoration(
            color: context.palette.sheet,
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
                    decoration: BoxDecoration(
                      color: context.palette.border,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    width: 200,
                    height: 28,
                    decoration: BoxDecoration(
                      color: context.palette.border,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    height: 16,
                    decoration: BoxDecoration(
                      color: context.palette.border,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: 180,
                    height: 16,
                    decoration: BoxDecoration(
                      color: context.palette.border,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 32),
                  Container(
                    width: double.infinity,
                    height: 56,
                    decoration: BoxDecoration(
                      color: context.palette.border,
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
        decoration: BoxDecoration(
          color: context.palette.sheet, // Matches the premium dark blue from image
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
                Icon(Icons.info_sharp, color: context.palette.textSecondary, size: 56),
                const SizedBox(height: 20),
                Text(
                  'ส่งเอกสารสมัครคนขับ',
                  style: AppTypography.heading3.copyWith(color: context.palette.textPrimary),
                ),
                const SizedBox(height: 12),
                Text(
                  'ใกล้จะเสร็จแล้ว!\nโปรดยื่นเอกสารสมัครขับรถของคุณเพื่อเป็นคนขับ Mass\n\nติดต่อ 089-9999999',
                  textAlign: TextAlign.center,
                  style: AppTypography.caption4.copyWith(
                    color: context.palette.textSecondary,
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
                        color: context.palette.textPrimary,
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

  /// Shown once the driver has submitted their documents and is awaiting
  /// approval — replaces the "register now" CTA with an under-review status.
  Widget _buildInReviewBottomSheet() {
    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: context.palette.sheet,
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
                Icon(
                  Icons.hourglass_top_rounded,
                  color: AppColors.foundationOrange500,
                  size: 56,
                ),
                const SizedBox(height: 20),
                Text(
                  'กำลังดำเนินการตรวจสอบข้อมูล',
                  textAlign: TextAlign.center,
                  style: AppTypography.heading3.copyWith(color: context.palette.textPrimary),
                ),
                const SizedBox(height: 12),
                Text(
                  'ระบบได้รับเอกสารของคุณแล้ว และกำลังตรวจสอบ\n'
                  'จะแจ้งเตือนอีกครั้งเมื่อผลการพิจารณาเสร็จสิ้น',
                  textAlign: TextAlign.center,
                  style: AppTypography.caption4.copyWith(
                    color: context.palette.textSecondary,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.foundationOrange500.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(
                      color: AppColors.foundationOrange500.withValues(
                        alpha: 0.4,
                      ),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.foundationOrange500,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'อยู่ระหว่างการตรวจสอบ',
                        style: AppTypography.caption3.copyWith(
                          color: AppColors.foundationOrange500,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () => context.push(
                    AppRoutes.documentRegistrationChecklistNamedPage,
                  ),
                  child: Text(
                    'ดูสถานะเอกสาร',
                    style: AppTypography.caption4.copyWith(
                      color: context.palette.textSecondary,
                      decoration: TextDecoration.underline,
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
      snapSizes: const [0.40],
      builder: (context, scrollController) {
        return Stack(
          clipBehavior: Clip.none,
          children: [
            // Fill the whole sheet (top:26 leaves room for the overlapping
            // online button) so the panel colour reaches the bottom edge —
            // otherwise short content lets the map show through underneath.
            Positioned(
              top: 26,
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                decoration: BoxDecoration(
                  color: context.palette.bg,
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
                            color: context.palette.textSecondary,
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      const _StatusCard(),
                      _buildMenuRow(),
                    ],
                  ),
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
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: context.palette.surfaceAlt,
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
                color: context.palette.textPrimary,
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
                    color: context.palette.textPrimary,
                  ),
                ),
                backgroundColor: AppColors.semanticSuccessBgHigh,
              ),
            );
            // The driver just went online but can't share location if GPS is
            // off or location is permanently denied — nudge them to Settings.
            await _promptLocationIfNeeded(context, ref);
            // Warn (in Thai) when the credit wallet is too low to keep taking
            // jobs — or empty/negative, where the backend won't dispatch at all.
            if (context.mounted) await _maybeShowCreditWarning(context, ref);
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
                      color: context.palette.textPrimary,
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
            Icon(
              Icons.power_settings_new,
              color: context.palette.textPrimary,
            ),
            const SizedBox(width: 10),
            Text(
              isOnline ? "พร้อมรับงาน" : "ปิดรับงาน",
              style: AppTypography.heading5.copyWith(
                color: context.palette.textPrimary,
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
        color: context.palette.surfaceAlt,
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
              color: context.palette.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

/// After going online, nudge the driver to Settings when location can't be
/// shared: GPS off → device location settings; permanently denied → app
/// settings. The first-time OS prompt already fired inside
/// [LocationService.startLocationUpdates]; this only covers the blocked cases.
Future<void> _promptLocationIfNeeded(BuildContext context, WidgetRef ref) async {
  final loc = ref.read(locationServiceProvider);

  if (!await loc.serviceEnabled()) {
    if (!context.mounted) return;
    _showLocationSettingsDialog(
      context,
      title: 'เปิดตำแหน่ง (GPS)',
      message: 'กรุณาเปิดบริการระบุตำแหน่งของเครื่อง เพื่อรับงานและนำทางได้',
      onOpen: Geolocator.openLocationSettings,
    );
    return;
  }

  if (await loc.permission() == LocationPermission.deniedForever) {
    if (!context.mounted) return;
    _showLocationSettingsDialog(
      context,
      title: 'อนุญาตการเข้าถึงตำแหน่ง',
      message:
          'แอปต้องใช้ตำแหน่งเพื่อนำทางไปจุดรับ-ส่งและรับงานใกล้คุณ\n'
          'กรุณาเปิดสิทธิ์ตำแหน่งในตั้งค่า',
      onOpen: Geolocator.openAppSettings,
    );
  }
}

void _showLocationSettingsDialog(
  BuildContext context, {
  required String title,
  required String message,
  required Future<bool> Function() onOpen,
}) {
  showDialog(
    context: context,
    builder: (dialogContext) => AlertDialog(
      backgroundColor: dialogContext.palette.surface,
      title: Text(
        title,
        style: AppTypography.heading5.copyWith(
          color: dialogContext.palette.textPrimary,
        ),
      ),
      content: Text(
        message,
        style: AppTypography.caption4.copyWith(
          color: dialogContext.palette.textSecondary,
          height: 1.4,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext),
          child: Text(
            'ไว้ทีหลัง',
            style: AppTypography.caption3.copyWith(
              color: dialogContext.palette.textTertiary,
            ),
          ),
        ),
        TextButton(
          onPressed: () {
            Navigator.pop(dialogContext);
            onOpen();
          },
          child: Text(
            'เปิดตั้งค่า',
            style: AppTypography.caption3.copyWith(
              color: AppColors.foundationOrange600,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    ),
  );
}

/// Minimum credit the driver should keep to keep taking jobs (product rule;
/// the backend is the source of truth and will confirm/override — SCRUM-97).
const double _kCreditMinBalance = 25.0;

/// After going online, check the credit wallet and warn (in Thai) when it is
/// too low. Two tiers: empty/negative → the backend won't dispatch at all
/// (must top up first); below the minimum → still gets a few jobs but should
/// top up soon. No dialog when the balance is healthy.
Future<void> _maybeShowCreditWarning(BuildContext context, WidgetRef ref) async {
  // Pull a fresh credit figure (lightweight) before deciding.
  try {
    await ref.read(walletControllerProvider.notifier).fetchPayoutSummary();
  } catch (_) {
    // Non-fatal — fall back to whatever is already in state.
  }
  if (!context.mounted) return;
  final credit = ref.read(walletControllerProvider).creditBalance;
  if (credit >= _kCreditMinBalance) return;
  _showCreditWarningDialog(context, credit: credit);
}

/// The low-credit dialog. `blocking` (empty/negative) uses stronger copy since
/// the backend stops dispatching jobs entirely until the driver tops up.
void _showCreditWarningDialog(BuildContext context, {required double credit}) {
  final bool blocking = credit <= 0;
  final String balanceText = '฿${credit.toStringAsFixed(0)}';
  final String title = blocking ? 'เครดิตไม่พอรับงาน' : 'เครดิตใกล้หมด';
  final String message = blocking
      ? 'เครดิตคงเหลือ $balanceText — ไม่สามารถรับงานได้\n'
          'กรุณาเติมเงินเครดิตก่อน ระบบจึงจะจ่ายงานให้'
      : 'เครดิตคงเหลือ $balanceText คุณอาจรับงานได้อีกไม่กี่งาน\n'
          'กรุณาเติมเงินเครดิตเพื่อรับงานต่อเนื่อง (ขั้นต่ำ ฿${_kCreditMinBalance.toStringAsFixed(0)})';

  showDialog(
    context: context,
    builder: (dialogContext) => AlertDialog(
      backgroundColor: dialogContext.palette.surface,
      title: Text(
        title,
        style: AppTypography.heading5.copyWith(
          color: blocking
              ? AppColors.semanticErrorBgHigh
              : dialogContext.palette.textPrimary,
        ),
      ),
      content: Text(
        message,
        style: AppTypography.caption4.copyWith(
          color: dialogContext.palette.textSecondary,
          height: 1.5,
        ),
      ),
      actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      actions: [
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(dialogContext);
                  dialogContext.go(AppRoutes.creditWalletNamedPage);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.foundationGreen700,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(28),
                  ),
                ),
                child: Text(
                  'เติมเงินเครดิต',
                  style: AppTypography.label1.copyWith(color: Colors.white),
                ),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(
                'รับทราบ',
                style: AppTypography.caption3.copyWith(
                  color: dialogContext.palette.textTertiary,
                ),
              ),
            ),
          ],
        ),
      ],
    ),
  );
}

// Reusable static dialog — called from _OnlineButton which is outside the
// _HomeScreenState, so we expose it as a top-level helper.
void _showUnverifiedDocsDialogStatic(BuildContext context) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (context) {
      return Container(
        decoration: BoxDecoration(
          color: context.palette.sheet,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        // Reserve the system nav-bar inset so the buttons clear the Android
        // 3-button bar (viewPadding.bottom, not padding — the sheet consumes it).
        padding: EdgeInsets.fromLTRB(
          24,
          32,
          24,
          32 + MediaQuery.of(context).viewPadding.bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.warning_amber_rounded,
              color: AppColors.foundationOrange500,
              size: 64,
            ),
            const SizedBox(height: 16),
            Text(
              'เอกสารของคุณยังไม่ได้รับการอนุมัติ',
              style: AppTypography.heading5.copyWith(color: context.palette.textPrimary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'กรุณาอัปโหลดเอกสารที่จำเป็นให้ครบถ้วนและรอการตรวจสอบให้เรียบร้อยเพื่อเริ่มต้นรับงาน',
              style: AppTypography.caption3.copyWith(
                color: context.palette.textSecondary,
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
                      side: BorderSide(color: context.palette.textTertiary),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: Text(
                      'ยกเลิก',
                      style: AppTypography.label2.copyWith(color: context.palette.textSecondary),
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

class _HomeMap extends ConsumerStatefulWidget {
  const _HomeMap();

  @override
  ConsumerState<_HomeMap> createState() => _HomeMapState();
}

class _HomeMapState extends ConsumerState<_HomeMap> {
  static const double _driverZoom = 16;

  GoogleMapController? _controller;
  StreamSubscription<Position>? _positionSub;

  /// Stops the first-fix listener from yanking the camera back after the
  /// driver has already been centered (and possibly panned away since).
  bool _hasCentered = false;

  @override
  void initState() {
    super.initState();

    // The one-shot below can come back empty on a cold start (no last known
    // fix, GPS still warming up). Going online starts the tracking session, so
    // adopt its first fix instead of leaving the driver on the default view.
    _positionSub = ref.read(locationServiceProvider).onPosition.listen((pos) {
      if (_hasCentered) return;
      _moveTo(LatLng(pos.latitude, pos.longitude));
    });
  }

  @override
  void dispose() {
    _positionSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox.expand(
      child: GoogleMap(
        onMapCreated: (controller) {
          _controller = controller;
          ref.read(mapControllerProvider.notifier).setController(controller);
          _centerOnDriver();
        },
        initialCameraPosition: const CameraPosition(
          target: MapDefaults.center,
          zoom: 14,
        ),
        myLocationEnabled: true,
        zoomControlsEnabled: false,
        myLocationButtonEnabled: false,
      ),
    );
  }

  /// The map opens on [MapDefaults.center] because no fix exists at build time.
  /// Move onto the driver as soon as one is available — without this the driver
  /// always sees the default city center.
  Future<void> _centerOnDriver() async {
    final pos = await ref.read(locationServiceProvider).currentPosition();
    if (pos == null) return; // No fix / no permission — default view stays.
    _moveTo(LatLng(pos.latitude, pos.longitude));
  }

  Future<void> _moveTo(LatLng target) async {
    final controller = _controller;
    if (controller == null || !mounted) return;
    _hasCentered = true;
    await controller.animateCamera(
      CameraUpdate.newLatLngZoom(target, _driverZoom),
    );
  }
}

/// Recenters the Home map on the driver. Lives outside [_HomeMap] because it
/// sits in the screen's Stack, above the map, and drives it through
/// [mapControllerProvider].
class _RecenterButton extends ConsumerStatefulWidget {
  const _RecenterButton();

  @override
  ConsumerState<_RecenterButton> createState() => _RecenterButtonState();
}

class _RecenterButtonState extends ConsumerState<_RecenterButton> {
  bool _locating = false;

  Future<void> _recenter() async {
    if (_locating) return;
    setState(() => _locating = true);

    try {
      // Returns the live fix while online, a fresh lookup otherwise.
      final pos = await ref.read(locationServiceProvider).currentPosition();
      final controller = ref.read(mapControllerProvider);

      if (!mounted) return;
      if (pos == null || controller == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('ยังไม่พบตำแหน่งของคุณ')),
        );
        return;
      }

      await controller.animateCamera(
        CameraUpdate.newLatLngZoom(
          LatLng(pos.latitude, pos.longitude),
          _HomeMapState._driverZoom,
        ),
      );
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _recenter,
      child: Container(
        height: 50,
        width: 50,
        decoration: BoxDecoration(
          color: context.palette.bg.withOpacity(0.7),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: _locating
            ? const Padding(
                padding: EdgeInsets.all(15),
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation(Colors.white),
                ),
              )
            : Icon(
                Icons.my_location,
                color: Colors.white,
                size: 24,
              ),
      ),
    );
  }
}
