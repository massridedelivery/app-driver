import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';
import 'package:massdrive/common/images/asset_image.dart';
import 'package:massdrive/common/widgets/announcement/announcement_size.dart';
import 'package:massdrive/common/widgets/announcement/announcement_state.dart';
import 'package:massdrive/common/widgets/announcement/announcement_styles.dart';
import 'package:massdrive/common/widgets/announcement/announcement_variant.dart';
import 'package:massdrive/common/widgets/tappable.dart';
import 'package:massdrive/core/constants/app_assets.dart';
import 'package:massdrive/core/constants/app_colors.dart';
import 'package:massdrive/core/constants/app_spacing.dart';
import 'package:massdrive/core/constants/app_typography.dart';

import '../../../core/constants/enum/images.dart';

class BlueprintAnnouncement extends StatelessWidget {
  const BlueprintAnnouncement({
    required this.title,
    required this.state,
    super.key,
    this.description,
    this.size = AnnouncementSizes.sm,
    this.variant = AnnouncementVariants.inBody,
    this.onClose,
    this.actionTitle,
    this.onAction,
  });

  final String title;
  final String? description;
  final AnnouncementState state;
  final AnnouncementSize size;
  final AnnouncementVariant variant;
  final VoidCallback? onClose;
  final String? actionTitle;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: variant.isFullWidth ? double.infinity : null,
      decoration: BoxDecoration(
        color: state.bgColor,
        border: variant.isShowBorder
            ? Border.all(color: state.borderColor)
            : Border.all(width: 0, color: Colors.transparent),
        borderRadius: variant.isFullWidth
            ? const BorderRadius.all(Radius.zero)
            : const BorderRadius.all(Radius.circular(AppSpacing.rounded2)),
        boxShadow: variant.isShowShadow
            ? const [
                BoxShadow(
                  blurRadius: 18,
                  offset: Offset(0, 8),
                  color: Color(0x1A000000),
                ),
              ]
            : null,
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (variant.isShowBorder)
              Container(
                width: 6,
                decoration: BoxDecoration(
                  color: state.themeColor,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(AppSpacing.rounded2),
                    bottomLeft: Radius.circular(AppSpacing.rounded2),
                  ),
                ),
              ),
            const SizedBox(width: AppSpacing.s3),
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.s3),
              child: AssetImageWidget(
                state.icon,
                color: state.themeColor,
                width: AppSpacing.s5,
                height: AppSpacing.s5,
                format: ImageFormat.svg,
              ),
            ),
            const SizedBox(width: AppSpacing.s3),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.s3),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: size.titleTextStyle.copyWith(
                        color: AppColors.semanticGrayNeutralFgMidOnGray,
                      ),
                    ),
                    if (description != null)
                      Text(
                        description ?? '',
                        style: size.descriptionTextStyle.copyWith(
                          color: AppColors.semanticGrayNeutralFgLowOnGray,
                        ),
                      ),
                    if (actionTitle != null)
                      Tappable(
                        onTap: onAction!,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              actionTitle ?? '',
                              style: AppTypography.label3.copyWith(
                                color: AppColors.semanticSecondaryFgHigh,
                              ),
                            ),
                            const AssetImageWidget(
                              AppAssets.chevronRightLineIcon,
                              color: AppColors.semanticSecondaryFgHigh,
                              width: AppSpacing.s5,
                              height: AppSpacing.s5,
                              format: ImageFormat.svg,
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
            if (onClose != null) ...[
              const Padding(
                padding: EdgeInsets.only(
                  top: AppSpacing.s3,
                  right: AppSpacing.s3,
                ),
                child: AssetImageWidget(
                  AppAssets.crossIcon,
                  color: AppColors.semanticGrayNeutralFgHigh,
                  width: AppSpacing.s5,
                  height: AppSpacing.s5,
                  format: ImageFormat.svg,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// MARK: - Preview
@Preview(group: 'Announcement')
Widget buildPreview() {
  return const BlueprintAnnouncement(
    title: 'Announcement Title',
    description: 'This is a sample announcement description.',
    state: AnnouncementStyle.info,
    size: AnnouncementSizes.sm,
    variant: AnnouncementVariants.inBody,
  );
}
