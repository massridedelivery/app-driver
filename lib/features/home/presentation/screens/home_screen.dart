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
import 'package:massdrive/core/services/connectivity_monitor.dart';
import 'package:massdrive/features/home/presentation/widgets/home_offline_card.dart';
import 'package:massdrive/features/inbox/presentation/widgets/inbox_bell_button.dart';
import 'package:massdrive/core/constants/map_constants.dart';
import 'package:massdrive/core/constants/app_typography.dart';
import 'package:massdrive/core/theme/app_palette.dart';
import 'package:massdrive/core/services/location_service.dart';
import 'package:massdrive/core/services/socket_service.dart';
import 'package:massdrive/features/call/presentation/call_permissions.dart';
import 'package:massdrive/features/dependency_injection.dart';
import 'package:massdrive/features/home/data/sources/home_api_service.dart';
import 'package:massdrive/features/home/presentation/widgets/active_job_banner.dart';
import 'package:massdrive/features/income/presentation/controllers/wallet_controller.dart';
import 'package:massdrive/features/income/presentation/widgets/credit_notice_dialog.dart';
import 'package:massdrive/features/home/presentation/widgets/home_coach_marks.dart';
import 'package:massdrive/features/home/presentation/widgets/online_toggle_button.dart';
import 'package:massdrive/features/home/presentation/widgets/home_card.dart';
import 'package:massdrive/features/home/presentation/widgets/reupload_banner.dart';
import 'package:massdrive/features/service_area/service_area_service.dart';
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
        // Start GPS first (prompts permission) so we can send our position when
        // registering online — the dispatch pool is fed by location, so BE adds
        // us as dispatchable right away instead of waiting for the first frame.
        await locationService.startLocationUpdates();
        final pos = await locationService.currentPosition();

        // Set Online via API (with current coords)
        if (!skipApiCall) {
          try {
            final res = await ref.read(homeApiServiceProvider).goOnline(
                  lat: pos?.latitude,
                  lng: pos?.longitude,
                );
            if (!res.isSuccessful) throw Exception('Failed to go online');
          } catch (e) {
            locationService.stopLocationUpdates(); // undo GPS on failure
            if (kDebugMode) debugPrint('Go Online API Error: $e');
            rethrow;
          }
        }

        // Connect WebSocket — carries the continuous location_update frames.
        await socketService.connect();

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

  /// Disposes the held controller and forgets it.
  void release() {
    state?.dispose();
    state = null;
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
  late final MapController _mapNotifier;

  @override
  void initState() {
    super.initState();

    _mapNotifier = ref.read(mapControllerProvider.notifier);
    // NOTE: Removed the _sheetSize listener — it was calling setState on every
    // pixel of scroll but _sheetSize was never used in build(), causing
    // unnecessary full widget-tree rebuilds.

    WidgetsBinding.instance.addPostFrameCallback((_) => _loadHome());
  }

  bool _retrying = false;

  /// "ลองใหม่" on the offline card: re-probe the network and reload.
  Future<void> _retryLoad() async {
    if (_retrying) return;
    setState(() => _retrying = true);
    try {
      await ref.read(connectivityMonitorProvider.notifier).refresh();
      await _loadHome();
    } finally {
      if (mounted) setState(() => _retrying = false);
    }
  }

  /// Load the profile, then start the verified/unverified flow. Run on open,
  /// on "ลองใหม่", and automatically when the connection comes back.
  Future<void> _loadHome() async {
    if (kDebugMode) debugPrint('HomeScreen: initState - Calling fetchProfile()');
    final profileNotifier = ref.read(profileControllerProvider.notifier);
    await profileNotifier.fetchProfile();

    final profile = ref.read(profileControllerProvider).profile;
    // Load failed (offline / server error): the offline card shows instead;
    // don't start the unverified flow on a missing profile.
    if (profile == null) return;
    if (kDebugMode) {
      debugPrint(
        'HomeScreen: fetchProfile() finished. Verified: ${profile.isVerified}',
      );
    }

    if (profile.isVerified == true) {
      if (kDebugMode) debugPrint('HomeScreen: Driver is verified. Calling initStatus()');
      await _startVerified();
    } else {
      if (kDebugMode) debugPrint('HomeScreen: Driver is NOT verified. Skipping initStatus()');
      // Load the registration status (reads /api/driver/documents) so the
      // home can show "กำลังดำเนินการตรวจสอบข้อมูล" once the driver has
      // submitted, rather than the "register now" CTA.
      if (mounted) {
        ref.read(registrationControllerProvider.notifier).fetchStatus();
      }
    }
  }

  @override
  void dispose() {
    // Drop the app-wide GoogleMapController reference so the native map can be
    // released instead of being held for the app's lifetime. `ref` is off
    // limits in dispose (Riverpod throws "Using ref when a widget is about to
    // or has been unmounted" — a Crashlytics crash), so use the notifier read
    // in initState, after this frame rather than mid tree teardown.
    final mapNotifier = _mapNotifier;
    Future.microtask(mapNotifier.release);
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

    // Offline card (instead of an endless skeleton) when the driver's data
    // couldn't load. Reload by itself once the connection comes back.
    final network = ref.watch(connectivityMonitorProvider);
    final offline = network.quality == NetworkQuality.offline;
    final loadFailed = profileState.profile == null &&
        !profileState.isLoading &&
        (profileState.errorMessage != null || offline);
    // Approved while home is open (pull-to-refresh, the registration status
    // refetch, consent…): start the verified home now — including the first
    // coach-mark tour — instead of only on the next cold start. A first load
    // (prev profile null) is left to _loadHome.
    ref.listen(profileControllerProvider, (prev, next) {
      final before = prev?.profile;
      final after = next.profile;
      if (before != null && !before.isVerified && (after?.isVerified ?? false)) {
        WidgetsBinding.instance.addPostFrameCallback((_) => _startVerified());
      }
    });
    ref.listen(connectivityMonitorProvider, (prev, next) {
      final recovered = prev?.quality == NetworkQuality.offline &&
          (next.quality == NetworkQuality.good ||
              next.quality == NetworkQuality.weak);
      if (recovered && ref.read(profileControllerProvider).profile == null) {
        _loadHome();
      }
    });

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
            child: const InboxBellButton(),
          ),
          Positioned(
            top: MediaQuery.of(context).padding.top + 76,
            right: 16,
            child: _buildSettingsButton(),
          ),
          Positioned(
            top: MediaQuery.of(context).padding.top + 136,
            right: 16,
            child: const _RecenterButton(),
          ),
          // Persistent indicator when the driver has a job in progress.
          Positioned(
            top: MediaQuery.of(context).padding.top + 196,
            left: 16,
            right: 16,
            child: const ActiveJobBanner(),
          ),
          loadFailed
              ? HomeOfflineCard(
                  offline: offline,
                  retrying: _retrying,
                  onRetry: _retryLoad,
                )
              : profileState.isLoading || profileState.profile == null
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
                  'ใกล้จะเสร็จแล้ว!\nโปรดยื่นเอกสารสมัครขับรถของคุณเพื่อเป็นคนขับ Mass\n\nติดต่อ 065-6924555',
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

  /// The verified driver's home: online status, the credit notice and, on
  /// this install's first visit, the coach-mark tour of the main controls.
  /// Runs from [_loadHome], and again when an already-open home sees
  /// is_verified flip to true (see the listener in [build]).
  Future<void> _startVerified() async {
    if (!mounted) return;
    ref.read(onlineStatusProvider.notifier).initStatus(context);
    // Refresh the cash-job gate on every home entry (app open, back from a
    // job or a top-up) and warn in a dialog when credit is low / blocked.
    await _maybeShowCreditNotice(context, ref);
    if (mounted) unawaited(HomeCoachMarks.maybeShow(context));
  }

  /// Re-check verification from the backend (pull-to-refresh on the under-review
  /// sheet) so a driver whose is_verified just flipped to true doesn't have to
  /// cold-restart the app to get in. The flip itself starts the verified home
  /// (listener in [build]).
  Future<void> _refreshVerification() async {
    await ref.read(profileControllerProvider.notifier).fetchProfile();
    if (!mounted) return;
    final verified =
        ref.read(profileControllerProvider).profile?.isVerified ?? false;
    if (!verified) {
      await ref.read(registrationControllerProvider.notifier).fetchStatus();
    }
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
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.55,
            ),
            child: RefreshIndicator(
              onRefresh: _refreshVerification,
              child: ListView(
                shrinkWrap: true,
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
                children: [
                  Column(
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
                      const SizedBox(height: 8),
                      Text(
                        'ดึงลงเพื่อตรวจสอบสถานะอีกครั้ง',
                        textAlign: TextAlign.center,
                        style: AppTypography.caption5
                            .copyWith(color: context.palette.textTertiary),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ================= MAP =================

  // ================= BOTTOM SHEET =================

  /// Three cards over the map, Grab-style: the online control, the status
  /// and the menu. Fixed at the bottom — no sheet to drag or scroll, so the
  /// cards always show in full.
  Widget _buildBottomSheet() {
    return Align(
      alignment: Alignment.bottomCenter,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          12,
          0,
          12,
          12 + MediaQuery.viewPaddingOf(context).bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const ReuploadBanner(),
            const _OnlineAndStatus(),
            const SizedBox(height: 8),
            _buildMenuRow(),
          ],
        ),
      ),
    );
  }

  // ================= MENU =================

  Widget _buildMenuRow() {
    // Use a simple Row instead of GridView to avoid shrinkWrap layout cost
    return HomeCard(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _circleMenu(Icons.card_giftcard, "รายได้", key: HomeCoachMarks.incomeMenu, () {
            context.push(AppRoutes.incomeNamedPage);
          }),
          _circleMenu(Icons.directions_car, "ประเภทบริการ", key: HomeCoachMarks.serviceMenu, () {
            context.push(AppRoutes.serviceTypeNamedPage);
          }),
          _circleMenu(Icons.person_sharp, "โปรไฟล์", () {
            context.push(AppRoutes.profileNamedPage);
          }),
          _circleMenu(Icons.settings_sharp, "การตั้งค่า", () {
            context.push(AppRoutes.settingNamedPage);
          }),
        ],
      ),
    );
  }

  Widget _circleMenu(
    IconData icon,
    String text,
    VoidCallback onTap, {
    Key? key,
  }) {
    return Expanded(
      child: InkWell(
      key: key,
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
          const SizedBox(height: 8),
          Text(
            text,
            textAlign: TextAlign.center,
            maxLines: 2,
            style: AppTypography.caption5.copyWith(
              color: context.palette.textPrimary,
            ),
          ),
        ],
      ),
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

    return OnlineToggleButton(
      isOnline: isOnline,
      buttonKey: HomeCoachMarks.onlineButton,
      onTap: () async {
        final current = ref.read(onlineStatusProvider).isOnline;
        final newValue = !current;

        // Service-area gate (SCRUM-99): before going online, check the zone at
        // the driver's current position. Fail-open — only an explicit
        // available:false blocks. Going offline is never gated.
        if (newValue) {
          final blocked = await _serviceAreaBlocksOnline(context, ref);
          if (blocked) return; // dialog shown; stay offline
          if (!context.mounted) return;
        }

        try {
          await ref.read(onlineStatusProvider.notifier).setStatus(newValue);

          // No "พร้อมรับงานแล้ว" snackbar: the button moving to the corner and
          // the status card saying กำลังค้นหางาน already say it.
          if (context.mounted && newValue && ref.read(onlineStatusProvider).isOnline) {
            // The driver just went online but can't share location if GPS is
            // off or location is permanently denied — nudge them to Settings.
            await _promptLocationIfNeeded(context, ref);
            // Going online is never refused for credit (BE dev115); warn if
            // the balance is low or cash jobs are blocked.
            if (context.mounted) await _maybeShowCreditNotice(context, ref);
            // Once: customers' in-app calls need the microphone (and the
            // full-screen call permission on Android 14+) granted up front.
            if (context.mounted) await primeCallPermissions(context, ref);
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
                      // White on the red fill (readable in light & dark).
                      color: Colors.white,
                    ),
                  ),
                  backgroundColor: AppColors.semanticErrorBgHigh,
                ),
              );
            }
          }
        }
      },
    );
  }
}

/// The online control and the status. Offline, the "เริ่มรับงาน" pill sits
/// centred above the status card; online, it shrinks into a white square as
/// tall as the status card and slides to its right, the card narrowing to
/// make room. Going offline plays it backwards.
class _OnlineAndStatus extends ConsumerWidget {
  const _OnlineAndStatus();

  static const double _statusH = 64;
  static const double _gap = 8;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isOnline = ref.watch(onlineStatusProvider).isOnline;
    const d = OnlineToggleButton.motion;
    const c = OnlineToggleButton.curve;
    final pill = OnlineToggleButton.offlineSize;
    final square = OnlineToggleButton.onlineSize;
    return LayoutBuilder(
      builder: (context, box) {
        final w = box.maxWidth;
        return AnimatedContainer(
          duration: d,
          curve: c,
          height: isOnline ? _statusH : pill.height + 10 + _statusH,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              AnimatedPositioned(
                duration: d,
                curve: c,
                left: 0,
                right: isOnline ? square.width + _gap : 0,
                bottom: 0,
                height: _statusH,
                child: KeyedSubtree(
                  key: HomeCoachMarks.statusCard,
                  child: const _StatusCard(),
                ),
              ),
              AnimatedPositioned(
                duration: d,
                curve: c,
                left: isOnline ? w - square.width : (w - pill.width) / 2,
                bottom: isOnline ? 0 : _statusH + 10,
                child: const _OnlineButton(),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Status card ("กำลังค้นหางาน" / "คุณปิดรับงาน") — extracted so only this
/// widget rebuilds when online status changes.
class _StatusCard extends ConsumerWidget {
  const _StatusCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isOnline = ref.watch(onlineStatusProvider).isOnline;
    return HomeCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          CircleAvatar(
            radius: 6,
            backgroundColor: isOnline
                ? AppColors.semanticSupportMintBgHigh
                : AppColors.foundationOrange700,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  isOnline ? 'กำลังค้นหางาน' : 'คุณปิดรับงาน',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.label2.copyWith(
                    color: context.palette.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  isOnline
                      ? 'งานใหม่จะเด้งขึ้นมาเอง'
                      : 'กดเริ่มรับงานเมื่อพร้อม',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.caption5.copyWith(
                    color: context.palette.textSecondary,
                  ),
                ),
              ],
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

/// Service-area gate (SCRUM-99): returns true (and shows the blocked dialog)
/// when the driver's current zone is closed for all their services. Fail-open —
/// unknown location or any error returns false (allow online).
Future<bool> _serviceAreaBlocksOnline(BuildContext context, WidgetRef ref) async {
  Position? pos;
  try {
    pos = await Geolocator.getLastKnownPosition() ??
        await Geolocator.getCurrentPosition(
          timeLimit: const Duration(seconds: 3),
        );
  } catch (_) {}
  if (pos == null) return false; // no location → fail-open

  final result = await _checkServiceArea(pos.latitude, pos.longitude);
  if (result.available) return false; // open (or fail-open)
  if (!context.mounted) return true;

  // WARN-ONLY (never blocks): show the notice, and acknowledging proceeds to
  // go online so the driver can keep working normally.
  showServiceAreaNoticeDialog(
    context,
    areaName: result.areaName,
    message: result.message,
    onAcknowledge: () async {
      if (context.mounted) {
        await ref.read(onlineStatusProvider.notifier).setStatus(true);
      }
    },
  );
  return true; // going-online is handled by the acknowledge button
}

/// Checks the driver's relevant services; a zone may be open for one only, so
/// allow online when ANY is available. Returns a blocking result otherwise.
Future<ServiceAreaResult> _checkServiceArea(double lat, double lng) async {
  const services = ['ride', 'messenger'];
  ServiceAreaResult blocked = ServiceAreaResult.open;
  for (final s in services) {
    final r =
        await ServiceAreaService.instance.check(lat: lat, lng: lng, service: s);
    if (r.available) return r; // any open → allow
    blocked = r;
  }
  return blocked;
}

/// What the credit dialog last showed this app session (balance + blocked),
/// so returning home after every job doesn't re-open the same warning.
String? _lastCreditNotice;

/// Fetches the cash-job gate and, when it has a notice (cash jobs blocked or
/// credit running low), shows the credit dialog — once per session for the
/// same balance, only while home is on top (never over a job offer or a job
/// in progress).
Future<void> _maybeShowCreditNotice(BuildContext context, WidgetRef ref) async {
  final gate = await ref.read(walletControllerProvider.notifier).fetchPayoutSummary();
  if (gate == null || !gate.hasNotice || !context.mounted) return;
  // A job offer on screen: its countdown matters more than the warning.
  if (ref.read(incomingJobControllerProvider).isModalVisible ||
      ref.read(messengerControllerProvider).isModalVisible) {
    return;
  }
  // An active job restored on open sits on top of home: don't cover the
  // driver's live screen. Not remembered, so it shows back on home later.
  if (ModalRoute.of(context)?.isCurrent == false) return;
  final key = '${gate.cashBlocked}|${gate.balance}';
  if (key == _lastCreditNotice) return;
  _lastCreditNotice = key;
  await showCreditNoticeDialog(context, gate);
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
