import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:massdrive/core/constants/app_colors.dart';
import 'package:massdrive/core/constants/app_typography.dart';
import 'package:massdrive/core/constants/map_constants.dart';
import 'package:massdrive/core/navigation/app_navigator.dart';
import 'package:massdrive/core/utils/map_marker_providers.dart';
import 'package:massdrive/core/services/directions_service.dart';
import 'package:massdrive/core/services/socket_service.dart';
import 'package:massdrive/features/chat/presentation/screens/chat_screen.dart';
import 'package:massdrive/features/incoming_job/presentation/controllers/incoming_job_controller.dart';
import 'package:massdrive/features/support/presentation/widgets/support_actions.dart';
import 'package:massdrive/core/utils/baht.dart';
import 'package:massdrive/core/utils/distance_text.dart';
import 'package:massdrive/common/widgets/slide_to_confirm.dart';
import 'package:massdrive/core/theme/app_palette.dart';
import 'package:massdrive/features/job_live/presentation/widgets/ride_flow_widgets.dart';
import 'package:massdrive/features/payment/domain/collection_amounts.dart';
import 'package:massdrive/features/incoming_job/domain/models/offer_headline.dart';

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

  // Measured height of the sheet's content (drag handle → CTA) so the sheet
  // can open at EXACTLY the extent that shows the full layout, then collapse.
  final GlobalKey _sheetContentKey = GlobalKey();
  double? _sheetContentHeight;
  double _sheetFitExtent = 0.5;
  // Set whenever the content height changes (entry, or a step with a longer
  // address / extra rows): the open sheet is re-fitted once it settles, so
  // the CTA never ends up below the visible part, under the nav bar.
  bool _refitPending = true;
  static const double _sheetMinExtent = 0.12;

  /// The sheet is down at its peek: show the compact card on top.
  bool _collapsed = false;
  double _sheetMinNow = _sheetMinExtent;

  void _onSheetMoved() {
    if (!_sheetController.isAttached) return;
    final c = _sheetController.size <= _sheetMinNow + 0.03;
    if (c != _collapsed) setState(() => _collapsed = c);
  }

  final DirectionsService _directionsService = DirectionsService();

  late JobLiveState _currentState = jobLiveStageFromStatus(
    widget.initialStatus,
  );
  Set<Polyline> _polylines = {};

  /// The driver's last GPS fix, for the distance badge (straight line to the
  /// current destination). Null until the first fix: the badge hides.
  LatLng? _driverAt;
  StreamSubscription<Position>? _positionSub;

  /// Driving time to the current stop from the last route fetch, and where
  /// the driver was then.
  int? _routeEtaSeconds;
  LatLng? _routeEtaFrom;

  @override
  void initState() {
    super.initState();

    _sheetController.addListener(_onSheetMoved);
    _positionSub =
        Geolocator.getPositionStream(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
            distanceFilter: 10,
          ),
        ).listen(
          (p) {
            if (mounted) {
              setState(() => _driverAt = LatLng(p.latitude, p.longitude));
            }
          },
          // No permission / GPS off: the badge simply stays hidden.
          onError: (_) {},
        );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadRoute();
      // The live figures (driver_net, amount_due) come from the server, not
      // the offer — read them now and again at every stage.
      ref.read(incomingJobControllerProvider.notifier).refreshActiveJob();

      // A cancelled job is closed by the app-root JobCancelListener.
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
      if (mounted) setState(() => _driverAt = origin);
    } catch (_) {
      // Fallback to pickup if location unavailable
      origin = LatLng(currentJob.pickupLat, currentJob.pickupLng);
    }

    final pickupLatLng = LatLng(currentJob.pickupLat, currentJob.pickupLng);
    final dropoffLatLng = LatLng(currentJob.dropoffLat, currentJob.dropoffLng);

    // Determine destination based on current state
    final LatLng destination = (_currentState == JobLiveState.headingToDropoff)
        ? dropoffLatLng
        : pickupLatLng;

    final route = await _directionsService.getRoute(
      origin: origin,
      destination: destination,
    );
    final points = route.points;

    if (!mounted) return;
    setState(() {
      // Google's driving time from here to the stop, with the straight-line
      // distance it was measured at — the ETA shrinks with it as the
      // driver closes in.
      _routeEtaSeconds = route.durationSeconds;
      _routeEtaFrom = origin;
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
      destination = MapDefaults.center;
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
        final ok = await launchUrl(
          fallbackUri,
          mode: LaunchMode.externalApplication,
        );
        debugPrint('NAV: fallback https launch result=$ok');
      }
    } catch (e) {
      debugPrint('NAV: launch error: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('ไม่สามารถเปิดแอปนำทางได้')));
    }
  }

  @override
  void dispose() {
    _positionSub?.cancel();
    _sheetController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Read the nav-bar inset here (screen level) — inside the sheet builder's
    // context it can come back 0, leaving the CTA under the Android nav bar.
    final bottomInset = MediaQuery.viewPaddingOf(context).bottom;
    return Scaffold(
      backgroundColor: AppColors.semanticGrayNeutralFgWhite,
      body: Stack(
        children: [
          _buildMap(),
          _buildNavBanner(),
          _buildRightFloatingButtons(),
          _buildBottomSheet(bottomInset),
        ],
      ),
    );
  }

  /// =========================
  /// MAP
  /// =========================
  Widget _buildMap() {
    final currentJob = ref.watch(incomingJobControllerProvider).currentJob;

    // Fallback to the default center if no job (shouldn't happen on this screen)
    final LatLng pickupLatLng = currentJob != null
        ? LatLng(currentJob.pickupLat, currentJob.pickupLng)
        : MapDefaults.center;

    final LatLng dropoffLatLng = currentJob != null
        ? LatLng(currentJob.dropoffLat, currentJob.dropoffLng)
        : MapDefaults.center;

    // Custom pins matching the customer app's ride flow; fall back to the
    // default hue marker until the bitmap finishes rasterizing.
    final pickupIcon =
        ref.watch(pickupMarkerProvider).value ??
        BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen);
    final dropoffIcon =
        ref.watch(dropoffMarkerProvider).value ??
        BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed);

    Set<Marker> markers = {};
    LatLng target = pickupLatLng;

    if (_currentState == JobLiveState.headingToPickup ||
        _currentState == JobLiveState.arrivedAtPickup) {
      target = pickupLatLng;
      markers.add(
        Marker(
          markerId: const MarkerId('pickup'),
          position: pickupLatLng,
          icon: pickupIcon,
        ),
      );
    } else {
      target = dropoffLatLng;
      markers.add(
        Marker(
          markerId: const MarkerId('dropoff'),
          position: dropoffLatLng,
          icon: dropoffIcon,
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
  Widget _buildBottomSheet(double bottomInset) {
    // Edge-to-edge sheet: the Android nav bar overlaps its rounded bottom.
    // The CTA clears the nav bar via bottom padding on Android; on iOS (no
    // nav bar) the padding stays tight. The clearance is baked into the
    // MEASURED content (the key sits on the padded box) so the fit height
    // reserves room for it too — the button always lands above the nav bar.
    final bool isAndroid = defaultTargetPlatform == TargetPlatform.android;
    final double bottomPad = 16 + (isAndroid ? bottomInset : 0.0);
    final surface = RideCardColors.of(context).surface;
    return LayoutBuilder(
      builder: (context, constraints) {
        final availableH = constraints.maxHeight;
        // Extent that EXACTLY fits the measured content (incl. bottom padding).
        // Until the first measurement lands, open at a safe default. Clamp so a
        // very tall layout still leaves the map visible and simply scrolls.
        final double fitExtent = (_sheetContentHeight != null && availableH > 0)
            ? (_sheetContentHeight! / availableH).clamp(0.2, 0.94)
            : 0.5;
        _sheetFitExtent = fitExtent;
        // Collapsed (design A): the next stop, รายได้สุทธิ and the slide.
        final double minExtent = availableH > 0
            ? ((_compactHeight + bottomPad) / availableH).clamp(0.12, fitExtent)
            : _sheetMinExtent;
        _sheetMinNow = minExtent;
        // Measure content + snap the sheet fully open (once) after layout.
        WidgetsBinding.instance.addPostFrameCallback(
          (_) => _fitSheetToContent(),
        );
        // No explicit snapSizes: snapping goes to min/max (peek/full) by
        // default, and a fresh list on every rebuild (GPS ticks, the collapsed
        // flag flipping mid-drag) made the sheet re-snap and fight the drag —
        // a collapsed sheet could not be pulled back up.
        return DraggableScrollableSheet(
          controller: _sheetController,
          initialChildSize: fitExtent,
          minChildSize: minExtent,
          maxChildSize: fitExtent,
          snap: true,
          builder: (context, scrollController) {
            return Container(
              decoration: BoxDecoration(
                color: surface,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(24),
                ),
                boxShadow: const [
                  BoxShadow(color: Colors.black26, blurRadius: 16),
                ],
              ),
              child: SingleChildScrollView(
                controller: scrollController,
                child: Stack(
                  children: [
                    Padding(
                      key: _sheetContentKey,
                      padding: EdgeInsets.fromLTRB(16, 8, 16, bottomPad),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _buildDragIndicator(),
                          const SizedBox(height: 10),
                          _buildNextStop(),
                          const SizedBox(height: 8),
                          _buildThenLine(),
                          const SizedBox(height: 10),
                          _buildPassengerInfo(),
                          const SizedBox(height: 12),
                          _buildArrivedButton(),
                        ],
                      ),
                    ),
                    // Collapsed: the top of the sheet shows the compact card.
                    if (_collapsed)
                      Positioned(
                        left: 0,
                        right: 0,
                        top: 0,
                        // Covers the whole peek, nav-bar strip included, so
                        // the full card never shows through underneath.
                        height: _compactHeight + bottomPad,
                        child: Container(
                          alignment: Alignment.topCenter,
                          color: surface,
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                          child: _buildCompact(),
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  /// Height of the collapsed card above the bottom padding: grip, the boxed
  /// stop, the slide.
  static const double _compactHeight =
      8 + 4 + 10 + _compactBoxHeight + 12 + 56 + 4;

  /// Collapsed stop box: the status/pill row and the address row.
  static const double _compactBoxHeight = 66;

  /// "รายได้สุทธิ ฿63" — the driver's net (driver_net), never what the
  /// passenger pays.
  Widget _netPill(double amount) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.foundationMint600.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text.rich(
        TextSpan(
          children: [
            TextSpan(
              text: 'รายได้สุทธิ ',
              style: AppTypography.caption5.copyWith(
                color: AppColors.foundationMint600,
                fontWeight: FontWeight.w600,
              ),
            ),
            TextSpan(
              text: formatBaht(amount),
              style: AppTypography.label2.copyWith(
                color: AppColors.foundationMint600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Collapsed card (design A): the stop being driven to, รายได้สุทธิ and the
  /// slide — the driver can confirm without opening the sheet.
  Widget _buildCompact() {
    final job = ref.watch(incomingJobControllerProvider).currentJob;
    final p = context.palette;
    final toDropoff = _currentState == JobLiveState.headingToDropoff;
    final headline = offerHeadline(
      fare: job?.netIncome ?? 0,
      driverNet: job?.driverNet,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildDragIndicator(),
        const SizedBox(height: 10),
        // Design 2: the same rounded box as the full card — status and the
        // รายได้สุทธิ pill on top, then the address across the full width.
        Container(
          height: _compactBoxHeight,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: RideCardColors.of(context).chip,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      _compactSub(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.caption5.copyWith(
                        color: AppColors.foundationMint600,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  _netPill(headline.amount),
                ],
              ),
              const Spacer(),
              Row(
                children: [
                  SvgPicture.asset(
                    RideStopsTimeline.pinAsset,
                    width: 20,
                    height: 20,
                    colorFilter: ColorFilter.mode(
                      toDropoff
                          ? RideStopsTimeline.dropoffColor
                          : RideStopsTimeline.pickupColor,
                      BlendMode.srcIn,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      (toDropoff ? job?.dropoffAddress : job?.pickupAddress) ??
                          '',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.caption3.copyWith(
                        color: p.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _buildArrivedButton(),
      ],
    );
  }

  String _compactSub() {
    final facts = [
      _distanceText(),
      _etaText(),
    ].where((t) => t.isNotEmpty).join(' · ');
    return switch (_currentState) {
      JobLiveState.headingToPickup =>
        facts.isEmpty ? 'ไปรับ' : '$facts · ไปรับ',
      JobLiveState.arrivedAtPickup => 'รอผู้โดยสาร',
      JobLiveState.headingToDropoff =>
        facts.isEmpty ? 'ไปส่ง' : '$facts · ไปส่ง',
    };
  }

  /// Measures the sheet content and, once its height is stable, snaps the
  /// sheet open to fit it exactly — so the driver sees the whole layout on
  /// entry and can then drag it down to a compact peek.
  void _fitSheetToContent() {
    if (!mounted) return;
    final h = _sheetContentKey.currentContext?.size?.height;
    if (h == null) return;
    if (_sheetContentHeight == null || (h - _sheetContentHeight!).abs() > 0.5) {
      // Height not known/stable yet — record it and let the rebuild re-fit.
      _refitPending = true;
      setState(() => _sheetContentHeight = h);
      return;
    }
    if (_refitPending && _sheetController.isAttached) {
      _refitPending = false;
      // Leave a sheet the driver collapsed to the peek as it is.
      final collapsed = _sheetController.size <= _sheetMinNow + 0.02;
      if (!collapsed &&
          (_sheetController.size - _sheetFitExtent).abs() > 0.005) {
        _sheetController.jumpTo(_sheetFitExtent);
      }
    }
  }

  /// Straight-line distance from the driver to the stop being driven to
  /// (pickup until the passenger is on board, then the dropoff); empty until
  /// there is a GPS fix.
  String _distanceText() {
    final job = ref.read(incomingJobControllerProvider).currentJob;
    final at = _driverAt;
    if (job == null || at == null) return '';
    final toDropoff = _currentState == JobLiveState.headingToDropoff;
    return formatDistanceTh(
      Geolocator.distanceBetween(
        at.latitude,
        at.longitude,
        toDropoff ? job.dropoffLat : job.pickupLat,
        toDropoff ? job.dropoffLng : job.pickupLng,
      ),
    );
  }

  /// Green bar on top: the step, the address heading to, the distance (or
  /// รอผู้โดยสาร at the pickup) and นำทาง.
  Widget _buildNavBanner() {
    final job = ref.watch(incomingJobControllerProvider).currentJob;
    if (job == null) return const SizedBox.shrink();
    final (step, address, headline) = switch (_currentState) {
      JobLiveState.headingToPickup => (
        '1 · ไปรับผู้โดยสาร',
        job.pickupAddress,
        _distanceText(),
      ),
      JobLiveState.arrivedAtPickup => (
        '1 · ถึงจุดรับแล้ว',
        job.pickupAddress,
        'รอผู้โดยสาร',
      ),
      JobLiveState.headingToDropoff => (
        '2 · ไปส่งผู้โดยสาร',
        job.dropoffAddress,
        _distanceText(),
      ),
    };
    return Positioned(
      top: MediaQuery.paddingOf(context).top + 8,
      left: 12,
      right: 12,
      child: RideNavBanner(
        step: step,
        address: address,
        headline: headline,
        onNavigate: _openGoogleMapsNavigation,
      ),
    );
  }

  Widget _buildRightFloatingButtons() {
    return Positioned(
      right: 16,
      top: MediaQuery.paddingOf(context).top + 140,
      // Navigation lives in the top banner.
      child: Column(children: [_circleButton(Icons.shield_outlined)]),
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
          color: context.palette.border,
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  /// "2 นาที" to the current stop: the route's driving time scaled by how
  /// much of the straight-line distance is left. Empty without a route time.
  String _etaText() {
    final eta = _routeEtaSeconds;
    final from = _routeEtaFrom;
    final at = _driverAt;
    final job = ref.read(incomingJobControllerProvider).currentJob;
    if (eta == null || job == null) return '';
    final toDropoff = _currentState == JobLiveState.headingToDropoff;
    final lat = toDropoff ? job.dropoffLat : job.pickupLat;
    final lng = toDropoff ? job.dropoffLng : job.pickupLng;
    var secs = eta.toDouble();
    if (from != null && at != null) {
      final d0 = Geolocator.distanceBetween(
        from.latitude,
        from.longitude,
        lat,
        lng,
      );
      final d1 = Geolocator.distanceBetween(
        at.latitude,
        at.longitude,
        lat,
        lng,
      );
      if (d0 > 50) secs = eta * (d1 / d0).clamp(0.0, 1.5);
    }
    final mins = (secs / 60).ceil();
    return mins <= 1 ? '1 นาที' : '$mins นาที';
  }

  /// Design 5: the stop being driven to, big — "กำลังไป · จุดรับ" with the
  /// รายได้สุทธิ pill (design 2) on top, then pin, address (full width) and
  /// "600 ม. · 2 นาที".
  Widget _buildNextStop() {
    final job = ref.watch(incomingJobControllerProvider).currentJob;
    final p = context.palette;
    final headline = offerHeadline(
      fare: job?.netIncome ?? 0,
      driverNet: job?.driverNet,
    );
    final toDropoff = _currentState == JobLiveState.headingToDropoff;
    final label = switch (_currentState) {
      JobLiveState.headingToPickup => 'กำลังไป · จุดรับ',
      JobLiveState.arrivedAtPickup => 'ถึงจุดรับแล้ว · รอผู้โดยสาร',
      JobLiveState.headingToDropoff => 'กำลังไป · จุดส่ง',
    };
    final facts = _currentState == JobLiveState.arrivedAtPickup
        ? ''
        : [_distanceText(), _etaText()].where((t) => t.isNotEmpty).join(' · ');
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: RideCardColors.of(context).chip,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: AppTypography.caption5.copyWith(
                    color: AppColors.foundationMint600,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              _netPill(headline.amount),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SvgPicture.asset(
                RideStopsTimeline.pinAsset,
                width: 22,
                height: 22,
                colorFilter: ColorFilter.mode(
                  toDropoff
                      ? RideStopsTimeline.dropoffColor
                      : RideStopsTimeline.pickupColor,
                  BlendMode.srcIn,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      (toDropoff ? job?.dropoffAddress : job?.pickupAddress) ??
                          '',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.label2.copyWith(
                        color: p.textPrimary,
                      ),
                    ),
                    if (facts.isNotEmpty)
                      Text(
                        facts,
                        style: AppTypography.caption5.copyWith(
                          color: p.textSecondary,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// One line about the other stop: "จากนั้นส่งที่ …" before pickup,
  /// "รับผู้โดยสารแล้ว · …" on the way to the dropoff.
  Widget _buildThenLine() {
    final job = ref.watch(incomingJobControllerProvider).currentJob;
    final toDropoff = _currentState == JobLiveState.headingToDropoff;
    final text = toDropoff
        ? 'รับผู้โดยสารแล้ว · ${job?.pickupAddress ?? ''}'
        : 'จากนั้นส่งที่ ${job?.dropoffAddress ?? ''}';
    return Row(
      children: [
        const SizedBox(width: 4),
        toDropoff
            ? const Icon(
                Icons.check_circle,
                size: 14,
                color: RideStopsTimeline.pickupColor,
              )
            : SvgPicture.asset(
                RideStopsTimeline.pinAsset,
                width: 14,
                height: 14,
                colorFilter: const ColorFilter.mode(
                  RideStopsTimeline.dropoffColor,
                  BlendMode.srcIn,
                ),
              ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.caption5.copyWith(
              color: context.palette.textSecondary,
            ),
          ),
        ),
      ],
    );
  }

  bool _collecting = false;

  /// Re-read the job shortly after a status change (waiting fee accrues at
  /// pickup), so รายได้สุทธิ on screen follows the server.
  void _refreshSoon() {
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        ref.read(incomingJobControllerProvider.notifier).refreshActiveJob();
      }
    });
  }

  /// At the drop-off: read what the passenger owes now (fare + toll + waiting
  /// − promo) from the backend, then open the collect screen with it. The
  /// in-memory offer can't be used — its amount_due is always 0.
  Future<void> _goCollect() async {
    if (_collecting) return;
    setState(() => _collecting = true);
    final fresh = await ref
        .read(incomingJobControllerProvider.notifier)
        .refreshActiveJob();
    if (!mounted) return;
    setState(() => _collecting = false);
    // amount_due only — never the fare (BE #199). Without it, don't guess.
    if (fresh == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('ตรวจยอดที่ต้องเก็บไม่สำเร็จ กรุณาลองใหม่อีกครั้ง'),
        ),
      );
      return;
    }
    context.push(
      '/payment',
      extra: {
        'gateCompletion': true,
        'amount': rideAmountToCollect(serverAmountDue: fresh.amountDue ?? 0),
      },
    );
  }

  /// Passenger + แชท / โทรฟรี / ช่วยเหลือ.
  Widget _buildPassengerInfo() {
    final job = ref.watch(incomingJobControllerProvider).currentJob;
    final p = context.palette;
    return Container(
      padding: const EdgeInsets.only(top: 10),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: RideCardColors.of(context).line)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: RideCardColors.of(context).chip,
            child: Icon(Icons.person, color: p.textSecondary),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  job?.passengerName ?? 'ผู้โดยสาร',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.caption3.copyWith(
                    color: p.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                // The role line only under a real name (the default name
                // already says ผู้โดยสาร).
                if (job != null && job.passengerName != 'ผู้โดยสาร')
                  Text(
                    'ผู้โดยสาร',
                    style: AppTypography.caption5.copyWith(
                      color: p.textSecondary,
                    ),
                  ),
              ],
            ),
          ),
          RideIconButton(
            icon: Icons.chat_bubble_outline,
            tooltip: 'แชท',
            onTap: job == null
                ? null
                : () => AppNavigator.push(
                    context,
                    ChatScreen(
                      jobId: job.jobId,
                      passengerName: job.passengerName,
                    ),
                  ),
          ),
          const SizedBox(width: 8),
          RideIconButton(
            icon: Icons.phone_outlined,
            tooltip: 'โทรฟรี',
            onTap: (job == null || job.passengerPhone.isEmpty)
                ? null
                : () => _callPassenger(job.passengerPhone),
          ),
          const SizedBox(width: 8),
          RideIconButton(
            icon: Icons.help_outline,
            tooltip: 'ช่วยเหลือ',
            onTap: () => showHelpSheet(context),
          ),
        ],
      ),
    );
  }

  Future<void> _callPassenger(String phone) async {
    final uri = Uri.parse('tel:$phone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('ไม่สามารถโทรออกได้')));
    }
  }

  /// The step's slide: orange "เลื่อนเมื่อถึงจุดรับ", then green
  /// "เลื่อนเพื่อเริ่มเดินทาง" and "เลื่อนเมื่อส่งถึงแล้ว".
  Widget _buildArrivedButton() {
    final (label, color) = switch (_currentState) {
      JobLiveState.headingToPickup => (
        'เลื่อนเมื่อถึงจุดรับ',
        AppColors.foundationOrange700,
      ),
      JobLiveState.arrivedAtPickup => (
        'เลื่อนเพื่อเริ่มเดินทาง',
        AppColors.foundationMint600,
      ),
      JobLiveState.headingToDropoff => (
        'เลื่อนเมื่อส่งถึงแล้ว',
        AppColors.foundationMint600,
      ),
    };
    return SlideToConfirm(
      key: ValueKey(_currentState),
      label: label,
      color: color,
      loading: _collecting,
      onConfirmed: _advance,
    );
  }

  void _advance() {
    final jobId = ref.read(incomingJobControllerProvider).currentJob?.jobId;
    final socket = ref.read(socketServiceProvider);

    setState(() {
      switch (_currentState) {
        case JobLiveState.headingToPickup:
          _currentState = JobLiveState.arrivedAtPickup;
          if (jobId != null) {
            socket.updateJobStatus(jobId, 'ARRIVED_AT_PICK_UP');
            _refreshSoon();
          }
          break;
        case JobLiveState.arrivedAtPickup:
          _currentState = JobLiveState.headingToDropoff;
          if (jobId != null) {
            socket.updateJobStatus(jobId, 'PICKED_UP');
            _refreshSoon();
          }
          break;
        case JobLiveState.headingToDropoff:
          // New flow (SCRUM-86): don't complete yet — PaymentScreen collects
          // the fare and marks COMPLETED only once it's settled. Pass the
          // amount explicitly (amount_due when real, else fare) so the
          // collect screen never depends on live controller state.
          _goCollect();
          break;
      }
    });
    // Reload route whenever state changes
    _loadRoute();
  }
}
