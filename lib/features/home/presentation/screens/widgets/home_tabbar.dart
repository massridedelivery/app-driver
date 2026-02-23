import 'package:flutter/material.dart';
import 'package:massdrive/core/constants/app_colors.dart';
import 'package:massdrive/core/constants/app_spacing.dart';
import 'package:massdrive/core/constants/app_typography.dart';
import 'package:massdrive/core/utils/image_util.dart';

class HomeTabBar extends StatelessWidget implements PreferredSizeWidget {
  const HomeTabBar({
    required this.tabController,
    required this.onTap,
    required this.items,
    required this.height,
    super.key,
  });

  final TabController tabController;
  final ValueChanged<int> onTap;
  final List<TabItem> items;
  final double height;

  @override
  Size get preferredSize => Size.fromHeight(height);

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final tabItemWidth = screenWidth * 0.22;
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.s2),
      child: SizedBox(
        height: height,
        child: AnimatedBuilder(
          animation: Listenable.merge([
            tabController,
            tabController.animation!,
          ]),
          builder: (context, _) {
            final selectedIndex = tabController.index;
            final isScrollable = items.length > 4 ? true : false;
            return TabBar(
              controller: tabController,
              onTap: onTap,
              isScrollable: isScrollable,
              tabAlignment: isScrollable
                  ? TabAlignment.start
                  : TabAlignment.fill,
              splashFactory: NoSplash.splashFactory,
              overlayColor: WidgetStateProperty.all(Colors.transparent),
              indicatorSize: TabBarIndicatorSize.tab,
              dividerHeight: AppSpacing.s1,
              dividerColor: AppColors.semanticGrayNeutralBorderLightgray,
              indicator: const UnderlineTabIndicator(
                borderSide: BorderSide(
                  width: 2,
                  color: AppColors.semanticPrimaryBorderHigh,
                ),
              ),
              labelPadding: const EdgeInsets.symmetric(vertical: AppSpacing.s3),
              labelStyle: AppTypography.label3.copyWith(
                color: AppColors.semanticGrayNeutralFgHigh,
              ),
              unselectedLabelStyle: AppTypography.caption5.copyWith(
                color: AppColors.semanticGrayNeutralFgMidOnWhite,
              ),
              tabs: List.generate(items.length, (i) {
                final it = items[i];
                final selected = i == selectedIndex;
                return Tab(
                  text: it.title,
                  icon: SizedBox(
                    width: tabItemWidth,
                    child: Image(
                      image: ImageUtils.getImageProvider(
                        selected ? it.assetSelected : it.asset,
                      ),
                      gaplessPlayback: true,
                      width: 36,
                      height: 36,
                    ),
                  ),
                );
              }),
            );
          },
        ),
      ),
    );
  }
}

class TabItem {
  final int id;
  final String title;
  final String asset;
  final String assetSelected;
  const TabItem({
    required this.id,
    required this.title,
    required this.asset,
    required this.assetSelected,
  });
}
