import 'package:flutter/material.dart';
import 'package:massdrive/common/images/asset_image.dart';
import 'package:massdrive/common/widgets/appbar/base_appbar.dart';
import 'package:massdrive/core/constants/app_assets.dart';
import 'package:massdrive/core/constants/app_colors.dart';
import 'package:massdrive/core/constants/app_spacing.dart';
import 'package:massdrive/features/home/presentation/screens/widgets/home_tabbar.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final TabController tabController;
  final ValueChanged<int> onTap;
  final List<TabItem> items;

  const CustomAppBar({
    required this.tabController,
    required this.onTap,
    required this.items,
    super.key,
  });

  static const double _tabsArea = 76;

  @override
  Widget build(BuildContext context) {
    return CommonAppBar(
      showLeftIcon: false,
      type: CommonAppBarType.search,
      rightWidgets: [_buildIconButton()],
      childWidgets: items.length > 1 ? _buildHomeTabBar() : null,
    );
  }

  HomeTabBar _buildHomeTabBar() {
    return HomeTabBar(
      tabController: tabController,
      onTap: onTap,
      items: items,
      height: _tabsArea,
    );
  }

  Widget _buildIconButton() {
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: AppColors.semanticGrayNeutralBgLightgray,
        borderRadius: BorderRadius.circular(20.0),
      ),
      child: IconButton(
        onPressed: () {},
        icon: const AssetImageWidget(
          AppAssets.notificationIcon,
          color: AppColors.semanticGrayNeutralFgHigh,
          width: 22,
          height: 22,
          format: .svg,
        ),
      ),
    );
  }

  @override
  Size get preferredSize {
    if (items.length > 1) {
      return const Size.fromHeight(kToolbarHeight + AppSpacing.s11);
    } else {
      return const Size.fromHeight(kToolbarHeight + AppSpacing.s3);
    }
  }
}
