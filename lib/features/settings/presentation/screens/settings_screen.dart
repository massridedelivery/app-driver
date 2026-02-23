import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:massdrive/common/widgets/announcement/announcement_styles.dart';
import 'package:massdrive/common/widgets/announcement/blueprint_announcement.dart';
import 'package:massdrive/common/widgets/badge/blueprint_badge.dart';
import 'package:massdrive/common/widgets/badge/models/badge_color.dart';
import 'package:massdrive/common/widgets/badge/models/badge_colors.dart';
import 'package:massdrive/common/widgets/badge/models/badge_size.dart';
import 'package:massdrive/common/widgets/badge/models/badge_sizes.dart';
import 'package:massdrive/common/widgets/badge/models/badge_styles.dart';
import 'package:massdrive/common/widgets/button/blueprint_button.dart';
import 'package:massdrive/common/widgets/button/button_styles.dart';
import 'package:massdrive/common/widgets/snackbar/blueprint_snackbar_utils.dart';
import 'package:massdrive/common/widgets/snackbar/snackbar_style.dart';
import 'package:massdrive/common/widgets/snackbar/snackbar_styles.dart';
import 'package:massdrive/core/constants/app_assets.dart';
import 'package:massdrive/core/constants/app_colors.dart';
import 'package:massdrive/core/constants/app_routes.dart';
import 'package:massdrive/core/constants/app_spacing.dart';
import 'package:massdrive/core/constants/enum/links.dart';
import 'package:massdrive/core/managers/deeplink_manager.dart';

import '../controllers/localization_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final localization = ref.watch(localizationProvider);
    final notifier = ref.read(localizationProvider.notifier);
    return Scaffold(
      appBar: AppBar(title: const Text('Settings Screen')),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Text(
              'Example Locales: ${tr('common.greeting', namedArgs: {"user_name": 'TREG'})}',
            ),
            const SizedBox(height: 16),
            DropdownButton<int>(
              value: localization.selectedIndex,
              items: localization.languages.asMap().entries.map((entry) {
                final index = entry.key;
                final lang = entry.value;
                return DropdownMenuItem(
                  value: index,
                  child: Text(lang.languageName),
                );
              }).toList(),
              onChanged: (index) async {
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
              },
            ),
            const SizedBox(height: 16),
            Center(
              child: ElevatedButton(
                onPressed: () {
                  DeeplinkManager().handleLink(
                    DestinationType.internal,
                    AppRoutes.homePath,
                  );
                },
                child: const Text('Go back to Home'),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: BlueprintButton(
                style: ButtonStyles.success.lg,
                text: 'Go to Webview',
                onPressed: () {
                  DeeplinkManager().handleLink(
                    DestinationType.external,
                    'https://google.com',
                    NavigationMethod.push,
                    'Test Webview Title',
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: BlueprintButton(
                style: ButtonStyles.secondary.xl,
                text: 'Go to Product Detail',
                onPressed: () {
                  DeeplinkManager().handleLink(
                    DestinationType.internal,
                    AppRoutes.checkoutName,
                    NavigationMethod.push,
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: BlueprintButton(
                style: ButtonStyles.secondary.xl,
                text: 'Go to Micro Site',
                onPressed: () {
                  DeeplinkManager().handleLink(
                    DestinationType.internal,
                    AppRoutes.checkoutPath,
                    NavigationMethod.push,
                    {'pageId': '1001'},
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: BlueprintButton(
                style: ButtonStyles.primary.xl.copyWith(
                  size: ButtonStyles.primary.xl.size.copyWith(
                    width: double.infinity,
                  ),
                ),
                text: 'Example Blueprint Button Primary XL',
                onPressed: () {},
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: BlueprintButton(
                style: ButtonStyles.danger.lg.copyWith(
                  size: ButtonStyles.danger.lg.size.copyWith(
                    width: double.infinity,
                  ),
                ),
                text: 'Example Blueprint Button Danger LG',
                onPressed: () {},
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: BlueprintButton(
                style: ButtonStyles.danger.xs,
                isLoading: true,
                text: 'Example Blueprint Button SX Loading',
                onPressed: () {},
              ),
            ),
            BlueprintAnnouncement(
              title: 'This is the title',
              description:
                  'In publishing and graphic design, Lorem ipsum is a placeholder text',
              state: AnnouncementStyle.info,
              size: AnnouncementSizes.sm,
              variant: AnnouncementVariants.inBody,
              onClose: () {},
              actionTitle: 'Change here',
              onAction: () {},
            ),
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: ExampleBlueprintSnackBar(),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                children: [
                  BlueprintBadge(
                    style: BadgeStyle(
                      color: BadgeColors.red,
                      size: BadgeSizes.xs,
                      font: BadgeFontType.bold,
                    ),
                    text: 'Badge red xs',
                  ),
                  SizedBox(width: 4),
                  BlueprintBadge(
                    style: BadgeStyle(
                      color: BadgeColors.red,
                      size: BadgeSizes.sm,
                      type: BadgeType.mid,
                      font: BadgeFontType.bold,
                    ),
                    text: 'Badge red sm',
                  ),
                  SizedBox(width: 4),
                  BlueprintBadge(
                    style: BadgeStyle(
                      color: BadgeColors.red,
                      size: BadgeSizes.lg,
                      type: BadgeType.low,
                      font: BadgeFontType.bold,
                    ),
                    text: 'Badge red lg',
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 6.0,
              ),
              child: Row(
                children: [
                  const BlueprintBadge(
                    style: BadgeStyle(
                      color: BadgeColors.green,
                      size: BadgeSizes.xs,
                    ),
                    text: 'Badge green xs',
                  ),
                  const SizedBox(width: 4),
                  const BlueprintBadge(
                    style: BadgeStyle(
                      color: BadgeColors.green,
                      size: BadgeSizes.sm,
                      type: BadgeType.mid,
                    ),
                    text: 'Badge green sm',
                  ),
                  const SizedBox(width: 4),
                  BlueprintBadge(
                    style: BadgeStyle(
                      color: BadgeColors.green.copyWith(
                        iconColor: AppColors.semanticSupportMintBgHigh,
                      ),
                      size: BadgeSizes.lg,
                      type: BadgeType.low,
                    ),
                    text: 'Badge green lg',
                    iconStart: AppAssets.storeLineIcon,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

const List<String> _snackBarItems = [
  'success',
  'error',
  'warning',
  'informative',
];

class ExampleBlueprintSnackBar extends StatefulWidget {
  const ExampleBlueprintSnackBar({super.key});

  @override
  State<ExampleBlueprintSnackBar> createState() => _ExampleBlueprintSnackBar();
}

class _ExampleBlueprintSnackBar extends State<ExampleBlueprintSnackBar> {
  String _selectedSnackBar = _snackBarItems.first;

  @override
  Widget build(BuildContext context) {
    return Row(
      spacing: AppSpacing.s3,
      children: [
        DropdownMenu(
          initialSelection: _snackBarItems.first,
          dropdownMenuEntries: _snackBarItems
              .map((e) => DropdownMenuEntry(value: e, label: e))
              .toList(),
          onSelected: (value) {
            _selectedSnackBar = value!;
          },
        ),
        BlueprintButton(
          style: ButtonStyles.defaultStyle.xs,
          text: 'Show Blueprint SnackBar',
          onPressed: () {
            showSnackBar(
              context,
              'Example Blueprint SnackBar of $_selectedSnackBar',
              style: getStyle(_selectedSnackBar),
            );
          },
        ),
      ],
    );
  }

  SnackBarStyle getStyle(String value) {
    switch (value) {
      case 'error':
        return SnackBarStyles.error;
      case 'warning':
        return SnackBarStyles.warning;
      case 'informative':
        return SnackBarStyles.informative;
      default:
        return SnackBarStyles.success;
    }
  }
}
