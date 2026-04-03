import 'package:flutter/material.dart';
import 'package:massdrive/common/images/asset_image.dart';
import 'package:massdrive/common/widgets/appbar/search_bar.dart';
import 'package:massdrive/core/constants/app_assets.dart';
import 'package:massdrive/core/constants/app_colors.dart';
import 'package:massdrive/core/constants/app_spacing.dart';
import 'package:massdrive/core/constants/app_typography.dart';

enum CommonAppBarType { title, search, empty }

class CommonAppBar extends StatelessWidget implements PreferredSizeWidget {
  final bool showLeftIcon;
  final Widget? leftIcon;
  final VoidCallback? onLeftTap;
  final CommonAppBarType type;
  final String? titleText;
  final List<Widget> rightWidgets;
  final PreferredSizeWidget? childWidgets;

  CommonAppBar({
    super.key,
    this.showLeftIcon = true,
    this.leftIcon,
    this.onLeftTap,
    this.type = CommonAppBarType.title,
    this.titleText,
    this.childWidgets,
    List<Widget>? rightWidgets,
  }) : rightWidgets = (rightWidgets ?? const []) {
    assert(
      (rightWidgets ?? const []).length <= 3,
      'Right widgets must be <= 3',
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: AppColors.semanticGrayNeutralFgHigh,
      automaticallyImplyLeading: false,
      scrolledUnderElevation: 0,
      leading: showLeftIcon
          ? Padding(
              padding: const EdgeInsets.only(left: AppSpacing.s5),
              child: IconButton(
                onPressed: onLeftTap ?? () => Navigator.maybePop(context),
                splashRadius: AppSpacing.s6,
                icon:
                    leftIcon ??
                    const AssetImageWidget(
                      AppAssets.icArrowLeft,
                      color: AppColors.semanticGrayNeutralBgWhite,
                      width: AppSpacing.s6,
                      height: AppSpacing.s6,
                      format: .svg,
                    ),
              ),
            )
          : null,
      centerTitle: false,
      title: _buildCenter(context),
      actions: [
        for (int i = 0; i < rightWidgets.length; i++) ...[
          rightWidgets[i],
          if (i != rightWidgets.length - 1)
            const SizedBox(width: AppSpacing.s3),
        ],
        const SizedBox(width: AppSpacing.s5),
      ],
      bottom: childWidgets,
    );
  }

  Widget? _buildCenter(BuildContext context) {
    switch (type) {
      case CommonAppBarType.title:
        return Text(
          titleText ?? '',
          style: AppTypography.heading4.copyWith(
            color: AppColors.semanticGrayNeutralBgWhite,
          ),
        );
      case CommonAppBarType.search:
        return const SearchInputBar();
      case CommonAppBarType.empty:
        return const SizedBox.shrink();
    }
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
