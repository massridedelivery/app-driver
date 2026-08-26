import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:massdrive/core/constants/app_colors.dart';
import 'package:massdrive/core/constants/app_routes.dart';
import 'package:massdrive/core/constants/app_typography.dart';
import 'package:massdrive/core/services/route_restoration_service.dart';
import 'package:massdrive/features/splash_screen/presentation/controllers/app_startup_controller.dart';
import 'package:massdrive/router/startup_destination.dart';

/// Splash styled to match the MassCustomer app (blurred brand auras, a gently
/// breathing gradient logo tile, and a fixed minimum dwell time before routing
/// on). Uses the shared Mass brand red and the official MassDriver "M" mark.
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  // Mass brand red — identical shades to the MassCustomer splash
  // (primary #DB1439 / deep #B71130), so the style matches exactly; only the
  // "M" mark and the copy below are the driver's own.
  static const Color _bg = Color(0xFFF8F8F9);
  static const Color _brand = AppColors.foundationRed700; // #DB1439
  static const Color _brandDeep = AppColors.foundationRed800; // #B71130
  static const Color _subtitle = Color(0xFF475569);

  // MassCustomer holds the splash a flat 2s before handing off to the router.
  static const Duration _minDwell = Duration(seconds: 2);

  late final AnimationController _pulseController;
  late final Animation<double> _scale;

  Timer? _minTimer;
  bool _minTimeElapsed = false;
  bool _navigated = false;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
    _scale = Tween<double>(begin: 0.97, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Hold the splash for the minimum dwell even when startup finishes sooner,
    // so the branding is actually seen (matches MassCustomer's 2s timer).
    _minTimer = Timer(_minDwell, () {
      _minTimeElapsed = true;
      _maybeNavigate();
    });
  }

  @override
  void dispose() {
    _minTimer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  /// Routes on only once BOTH the min dwell has elapsed and startup resolved.
  void _maybeNavigate() {
    if (_navigated || !_minTimeElapsed || !mounted) return;
    ref.read(appStartupControllerProvider).whenOrNull(
      data: (result) => _go(() {
        // An in-progress job found on cold launch wins over normal routing.
        if (result.resumeRoute != null) {
          context.go(result.resumeRoute!, extra: result.resumeExtra);
          return;
        }
        switch (result.destination) {
          case StartupDestination.onboarding:
            context.go(AppRoutes.loginNamedPage);
            break;
          case StartupDestination.home:
            // Land on Home first, then push the restored screen on top of it.
            // Restoring with a bare `go` makes that screen the only entry in
            // the stack, so its back arrow (Navigator.maybePop) has nothing to
            // pop and silently does nothing.
            context.go(AppRoutes.homeNamedPage);
            final restored = RouteRestorationService.instance.lastRoute;
            if (restored != null && restored != AppRoutes.homeNamedPage) {
              context.push(restored);
            }
            break;
        }
      }),
      // Last line of defence. The controller already converts its own failures
      // into a destination, but anything that still errors must not leave the
      // driver staring at the splash with no way forward.
      error: (e, _) {
        debugPrint('Startup Error: $e');
        _go(() => context.go(AppRoutes.loginNamedPage));
      },
    );
  }

  void _go(VoidCallback navigate) {
    if (_navigated) return;
    _navigated = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      navigate();
    });
  }

  @override
  Widget build(BuildContext context) {
    // Navigate the moment startup resolves (the dwell timer covers the rest).
    ref.listen(appStartupControllerProvider, (previous, next) => _maybeNavigate());

    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: _bg,
      body: Stack(
        children: [
          // Soft, out-of-focus brand blobs behind the content.
          _AuraBlur(
            color: _brand,
            diameter: size.width * 0.8,
            top: -size.height * 0.1,
            left: -size.width * 0.1,
          ),
          _AuraBlur(
            color: _brandDeep,
            diameter: size.width * 0.7,
            top: size.height * 0.35,
            right: -size.width * 0.2,
          ),
          _AuraBlur(
            color: _brand,
            diameter: size.width * 0.6,
            bottom: -size.height * 0.05,
            left: size.width * 0.1,
          ),

          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Breathing gradient logo tile with the white "M" mark.
                ScaleTransition(
                  scale: _scale,
                  child: Transform.rotate(
                    angle: -4 * math.pi / 180,
                    child: Container(
                      width: 120,
                      height: 120,
                      padding: const EdgeInsets.all(22),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(30),
                        gradient: const LinearGradient(
                          colors: [_brandDeep, _brand],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: _brand.withOpacity(0.35),
                            blurRadius: 28,
                            offset: const Offset(0, 14),
                          ),
                        ],
                      ),
                      // The official MassDriver "M" mark (white, on the red
                      // tile) — the same brand mark as the store icon.
                      child: Image.asset(
                        'assets/images/app_logo_mark.png',
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 40),
                Text(
                  'MassDriver',
                  style: AppTypography.heading1.copyWith(
                    fontSize: 44,
                    fontWeight: FontWeight.w900,
                    color: _brand,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'ขับเคลื่อนเมืองไปด้วยกัน',
                  style: AppTypography.label2.copyWith(
                    fontWeight: FontWeight.bold,
                    color: _subtitle,
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

/// A single large, heavily-blurred circle used as a soft background aura.
class _AuraBlur extends StatelessWidget {
  final Color color;
  final double diameter;
  final double? top;
  final double? left;
  final double? right;
  final double? bottom;

  const _AuraBlur({
    required this.color,
    required this.diameter,
    this.top,
    this.left,
    this.right,
    this.bottom,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: top,
      left: left,
      right: right,
      bottom: bottom,
      child: IgnorePointer(
        child: ImageFiltered(
          imageFilter: ImageFilter.blur(sigmaX: 80, sigmaY: 80),
          child: Container(
            width: diameter,
            height: diameter,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withOpacity(0.12),
            ),
          ),
        ),
      ),
    );
  }
}
