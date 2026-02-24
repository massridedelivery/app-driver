import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:massdrive/common/widgets/badge/badge_icon.dart';
import 'package:massdrive/common/widgets/button/blueprint_button.dart';
import 'package:massdrive/common/widgets/button/button_styles.dart';
import 'package:massdrive/common/widgets/drawer/app_drawer.dart';
import 'package:massdrive/common/widgets/drawer/app_drawer_menu.dart';
import 'package:massdrive/common/widgets/snackbar/blueprint_snackbar_utils.dart';
import 'package:massdrive/common/widgets/snackbar/snackbar_provider.dart';
import 'package:massdrive/core/constants/app_assets.dart';
import 'package:massdrive/core/constants/app_colors.dart';
import 'package:massdrive/core/constants/app_routes.dart';
import 'package:massdrive/core/constants/app_spacing.dart';
import 'package:massdrive/core/constants/app_typography.dart';
import 'package:massdrive/core/managers/deeplink_manager.dart';
import 'package:massdrive/core/navigation/app_navigator.dart';
import 'package:massdrive/features/auth/presentation/controllers/auth_controller.dart';
import 'package:massdrive/router/app_routes.dart';

class ScaffoldWithNavBar extends ConsumerStatefulWidget {
  const ScaffoldWithNavBar({required this.navigationShell, super.key});

  final StatefulNavigationShell navigationShell;

  @override
  ConsumerState<ScaffoldWithNavBar> createState() => _ScaffoldWithNavBarState();
}

class _ScaffoldWithNavBarState extends ConsumerState<ScaffoldWithNavBar> {
  static const _inactiveIconColor = AppColors.semanticGrayNeutralFgMidOnWhite;
  static const _activeIconColor = AppColors.foundationOrange600;

  static const _iconHome = BadgeIcon(
    iconPath: AppAssets.bottomNavHomeIcon,
    color: _inactiveIconColor,
  );

  static const _activeIconHome = BadgeIcon(
    iconPath: AppAssets.bottomNavHomeActiveIcon,
    color: _activeIconColor,
  );

  static const _iconAccount = BadgeIcon(
    iconPath: AppAssets.bottomNavUserIcon,
    color: _inactiveIconColor,
  );

  static const _activeIconAccount = BadgeIcon(
    iconPath: AppAssets.bottomNavUserActiveIcon,
    color: _activeIconColor,
  );
  late final ProviderSubscription _snackbarSub;

  @override
  void initState() {
    super.initState();
    _listenShowSnackbar();
  }

  @override
  void dispose() {
    _snackbarSub.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: widget.navigationShell,
      endDrawer: AppDrawer(onMenuTap: _handleDrawerNavigation),
      endDrawerEnableOpenDragGesture: false,
      bottomNavigationBar: Theme(
        data: Theme.of(context).copyWith(
          splashFactory: NoSplash.splashFactory,
          highlightColor: Colors.transparent,
        ),
        child: Container(
          color: AppColors.semanticGrayNeutralFgWhite,
          child: SafeArea(
            child: Container(
              padding: const EdgeInsets.only(top: 1),
              color: AppColors.semanticGrayNeutralBorderLightgray,
              child: BottomNavigationBar(
                currentIndex: widget.navigationShell.currentIndex,
                type: BottomNavigationBarType.fixed,
                backgroundColor: AppColors.semanticGrayNeutralFgWhite,
                elevation: 0,
                showSelectedLabels: true,
                showUnselectedLabels: true,
                selectedItemColor: AppColors.semanticPrimaryFgHigh,
                unselectedItemColor: AppColors.semanticGrayNeutralFgMidOnWhite,
                items: [
                  const BottomNavigationBarItem(
                    icon: _iconHome,
                    activeIcon: _activeIconHome,
                    label: 'Home',
                  ),
                  const BottomNavigationBarItem(
                    icon: _iconAccount,
                    activeIcon: _activeIconAccount,
                    label: 'Income',
                  ),
                  const BottomNavigationBarItem(
                    icon: _activeIconAccount,
                    activeIcon: _activeIconHome,
                    label: 'Profile',
                  ),
                ],
                onTap: (int index) {
                  widget.navigationShell.goBranch(
                    index,
                    initialLocation:
                        index == widget.navigationShell.currentIndex,
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  // MARK: Handle Drawer Navigation
  void _handleDrawerNavigation(AppDrawerMenuType menuType) {
    if (context.canPop()) context.pop();
    final deepLinkManager = DeeplinkManager();
    switch (menuType) {
      case .followedHashtags:
        // Navigate to followed hashtags
        break;
      case .savedCards:
        deepLinkManager.handleLink(.internal, AppRoutes.checkoutPath, .push);
        break;
      case .myAddresses:
        deepLinkManager.handleLink(.internal, AppRoutes.checkoutPath, .push);
        break;
      case .myInsurance:
        // Navigate to my insurance
        break;
      case .referralProgram:
        // Navigate to referral program
        break;
      case .customerService:
        // Navigate to customer service
        break;
      case .helpCenter:
        // Navigate to help center
        break;
      case .settings:
        deepLinkManager.handleLink(.internal, AppRoutes.settingsPath, .push);
        break;
      case .authentication:
        final authValue = ref.read(authControllerProvider).value;
        if (authValue?.isLogin == true) {
          _showDialogLogout();
        } else {
          context.push(AppRoutes.loginNamedPage);
        }
        break;
    }
  }

  // MARK: Handle Snackbar
  void _listenShowSnackbar() {
    _snackbarSub = ref.listenManual(snackbarProvider, (prev, next) {
      if (!next.isShow) return;
      Future.delayed(Duration(milliseconds: next.delayedInMilliseconds), () {
        if (!mounted) return;
        showSnackBar(
          context,
          tr(next.message),
          style: next.style,
          textAlignment: next.textAlignment,
        );
        ref.read(snackbarProvider.notifier).hide();
      });
    });
  }

  void _showDialogLogout() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        insetPadding: const .symmetric(horizontal: AppSpacing.none),
        contentPadding: const .symmetric(
          horizontal: AppSpacing.s4,
          vertical: AppSpacing.s5,
        ),
        actionsPadding: const .all(AppSpacing.s4),
        titlePadding: const .only(
          left: AppSpacing.s4,
          right: AppSpacing.s4,
          bottom: AppSpacing.none,
          top: AppSpacing.s4,
        ),
        buttonPadding: const .only(left: AppSpacing.s3),
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: .circular(AppSpacing.s3)),
        title: Text(
          tr('logout.modal_title'),
          textAlign: .start,
          style: AppTypography.heading5.copyWith(
            color: AppColors.semanticGrayNeutralFgHigh,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 328),
          child: Text(
            tr('logout.modal_description'),
            style: AppTypography.body2.copyWith(
              color: AppColors.foundationGrayscale1000,
            ),
          ),
        ),
        actions: [
          BlueprintButton(
            style: ButtonStyles.defaultStyle,
            text: tr('logout.stay_button'),
            onPressed: context.pop,
          ),
          BlueprintButton(
            style: ButtonStyles.primary,
            text: tr('logout.logout_button'),
            onPressed: () async {
              context.pop();
              await ref.read(authControllerProvider.notifier).logout();
              if (context.mounted) {
                AppNavigator.go(context, AppRoutes.loginNamedPage);
              }
            },
          ),
        ],
      ),
    );
  }
}
