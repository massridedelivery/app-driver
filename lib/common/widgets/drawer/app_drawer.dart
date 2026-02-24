import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:massdrive/common/images/asset_image.dart';
import 'package:massdrive/common/widgets/button/blueprint_button.dart';
import 'package:massdrive/common/widgets/button/button_styles.dart';
import 'package:massdrive/common/widgets/drawer/app_drawer_menu.dart';
import 'package:massdrive/core/constants/app_assets.dart';
import 'package:massdrive/core/constants/app_colors.dart';
import 'package:massdrive/core/constants/app_spacing.dart';
import 'package:massdrive/core/constants/app_typography.dart';
import 'package:massdrive/core/utils/app_util.dart';
import 'package:massdrive/features/settings/domain/entities/language_entity.dart';
import 'package:massdrive/features/auth/presentation/controllers/auth_controller.dart';
import 'package:massdrive/features/settings/presentation/screens/settings_screen.dart';
import 'package:massdrive/features/settings/presentation/state/localization_state.dart';

import '../../../core/constants/enum/images.dart' show ImageFormat;
import '../../../features/settings/presentation/controllers/developer_options_controller.dart';
import '../../../features/settings/presentation/controllers/localization_provider.dart';

class AppDrawer extends ConsumerWidget {
  final Function(AppDrawerMenuType)? onMenuTap;

  const AppDrawer({super.key, this.onMenuTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Drawer(
      backgroundColor: Colors.white,
      shape: const Border(),
      child: SafeArea(
        child: Column(
          children: [
            const _NavMenu(),
            _BodyMenu(onMenuTap: onMenuTap),
            _BottomMenu(onMenuTap: onMenuTap),
          ],
        ),
      ),
    );
  }
}

/// Nav Menu
class _NavMenu extends StatelessWidget {
  const _NavMenu();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.s4),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            style: IconButton.styleFrom(
              backgroundColor: AppColors.semanticGrayNeutralBgLightgray,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSpacing.rounded3),
              ),
            ),
            icon: const AssetImageWidget(
              width: 20,
              height: 20,
              AppAssets.chevronLeftLineIcon,
              format: ImageFormat.svg,
            ),
          ),
          const Spacer(),
          const _LanguageDropdown(),
        ],
      ),
    );
  }
}

/// Language
class _LanguageDropdown extends ConsumerWidget {
  const _LanguageDropdown();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final localization = ref.watch(localizationProvider);
    final notifier = ref.read(localizationProvider.notifier);
    return Material(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        side: const BorderSide(
          color: AppColors.semanticGrayNeutralBorderLightgray,
        ),
        borderRadius: BorderRadius.circular(AppSpacing.rounded3),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton(
          elevation: 6,
          value: localization.selectedIndex,
          icon: const Padding(
            padding: EdgeInsets.only(left: AppSpacing.s3),
            child: AssetImageWidget(
              AppAssets.chevronDownLineIcon,
              width: AppSpacing.s5,
              height: AppSpacing.s5,
              format: ImageFormat.svg,
            ),
          ),
          isDense: true,
          items: localization.languages.asMap().entries.map((entry) {
            final index = entry.key;
            final lang = entry.value;
            return DropdownMenuItem(
              value: index,
              child: _LanguageMenu(language: lang),
            );
          }).toList(),
          onChanged: (index) async {
            await _handleLanguageChange(index, notifier, localization, context);
          },
          borderRadius: BorderRadius.circular(AppSpacing.rounded3),
          padding: const EdgeInsetsGeometry.all(AppSpacing.s3),
          dropdownColor: Colors.white,
          selectedItemBuilder: (context) {
            return localization.languages.map((lang) {
              return _LanguageMenu(language: lang);
            }).toList();
          },
        ),
      ),
    );
  }

  Future<void> _handleLanguageChange(
    int? index,
    LocalizationNotifier notifier,
    LocalizationState localization,
    BuildContext context,
  ) async {
    if (index != null) {
      notifier.setSelectedIndex(index);

      notifier.setLanguage(
        Locale(
          localization.languages[index].languageCode,
          localization.languages[index].countryCode,
        ),
      );
      if (context.mounted) {
        await context.setLocale(
          Locale(
            localization.languages[index].languageCode,
            localization.languages[index].countryCode,
          ),
        );
      }
    }
  }
}

class _LanguageMenu extends StatelessWidget {
  const _LanguageMenu({required this.language});

  final LanguageEntity language;

  @override
  Widget build(BuildContext context) {
    return Row(
      spacing: AppSpacing.s2,
      children: [
        _buildFlagIcon(),
        Text(language.languageName, style: AppTypography.caption5),
      ],
    );
  }

  ClipOval _buildFlagIcon() {
    return ClipOval(
      child: SizedBox(
        width: 20,
        height: 20,
        child: AssetImageWidget(
          language.languageCode == 'th'
              ? AppAssets.flagThIcon
              : AppAssets.flagEnIcon,
          width: 20,
          height: 20,
          format: .svg,
          fit: .cover,
        ),
      ),
    );
  }
}

/// Body menu
class _BodyMenu extends ConsumerWidget {
  const _BodyMenu({this.onMenuTap});

  final Function(AppDrawerMenuType)? onMenuTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Expanded(
      child: ListTileTheme(
        iconColor: AppColors.semanticGrayNeutralFgHigh,
        textColor: AppColors.semanticGrayNeutralFgHigh,
        horizontalTitleGap: AppSpacing.s4,
        minLeadingWidth: 20,
        child: ListView(
          physics: const ClampingScrollPhysics(),
          padding: EdgeInsets.zero,
          children: [
            Padding(
              padding: const .symmetric(horizontal: AppSpacing.s5),
              child: Text(
                'บัญชีของฉัน',
                style: AppTypography.label3.copyWith(
                  color: AppColors.foundationGrayscale500,
                ),
              ),
            ),

            _MenuTile(
              icon: AppAssets.hashtagIcon,
              title: 'แฮชแท็กที่ติดตาม',
              onTap: () => onMenuTap?.call(.followedHashtags),
            ),

            _MenuTile(
              icon: AppAssets.cardLineIcon,
              title: tr('hamburger.saved_cards_menu'),
              onTap: () => onMenuTap?.call(.savedCards),
            ),

            _MenuTile(
              icon: AppAssets.houseLineIcon,
              title: tr('hamburger.address_menu'),
              onTap: () => onMenuTap?.call(.myAddresses),
            ),

            _MenuTile(
              icon: AppAssets.circleQuestionLineIcon,
              title: 'ประกันของฉัน',
              onTap: () => onMenuTap?.call(.myInsurance),
            ),

            const SizedBox(height: AppSpacing.s7),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s5),
              child: Text(
                'Others',
                style: AppTypography.label3.copyWith(
                  color: AppColors.foundationGrayscale500,
                ),
              ),
            ),

            _MenuTile(
              icon: AppAssets.circleQuestionLineIcon,
              title: 'Chat with Customer Service',
              onTap: () => onMenuTap?.call(.customerService),
            ),

            _MenuTile(
              icon: AppAssets.callCenterLineIcon,
              title: 'Help Center',
              onTap: () => onMenuTap?.call(.helpCenter),
            ),

            ListTile(
              leading: const Icon(
                Icons.settings,
                color: AppColors.semanticGrayNeutralFgHigh,
              ),
              title: const Text('Settings', style: AppTypography.caption4),
              minTileHeight: 52,
              onTap: () {
                onMenuTap?.call(.settings);
              },
            ),
          ],
        ),
      ),
    );
  }
}

///Bottom menu
class _BottomMenu extends ConsumerWidget {
  const _BottomMenu({this.onMenuTap});

  final Function(AppDrawerMenuType)? onMenuTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen(developerOptionsControllerProvider, (previous, next) {
      if (previous?.count == 10 && next.count == 0) {
        Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (context) => SettingsScreen()));
      }
    });
    final versionName = AppUtil.getPackageInfo().version;
    final buildNumber = AppUtil.getPackageInfo().buildNumber;
    final isLogin = ref.watch(authControllerProvider).value?.isLogin ?? false;
    final authButtonTitle = tr(
      isLogin ? 'hamburger.logout_button' : 'login.login_create_button',
    );
    return Padding(
      padding: const EdgeInsets.only(
        left: AppSpacing.s5,
        right: AppSpacing.s5,
        bottom: AppSpacing.s5,
      ),
      child: Column(
        spacing: AppSpacing.s3,
        children: [
          SizedBox(
            width: double.infinity,
            child: BlueprintButton(
              style: ButtonStyles.defaultStyle,
              text: authButtonTitle,
              onPressed: () =>
                  onMenuTap?.call(AppDrawerMenuType.authentication),
            ),
          ),
          GestureDetector(
            onTap: () {},
            child: Text(
              '${tr('hamburger.version_title')} $versionName ($buildNumber)',
              style: AppTypography.label3.copyWith(
                color: AppColors.foundationGrayscale500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

final class _MenuTile extends StatelessWidget {
  const _MenuTile({required this.icon, required this.title, this.onTap});

  final String title;
  final String icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ListTile(
          leading: AssetImageWidget(
            icon,
            width: 20,
            height: 20,
            format: ImageFormat.svg,
          ),
          title: Text(title, style: AppTypography.caption4),
          onTap: onTap,
        ),
        const Padding(
          padding: EdgeInsets.only(left: AppSpacing.s5),
          child: Divider(
            height: 1,
            color: AppColors.semanticGrayNeutralBorderLightgray,
          ),
        ),
      ],
    );
  }
}
