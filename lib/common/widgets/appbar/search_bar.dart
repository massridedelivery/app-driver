import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:massdrive/common/images/asset_image.dart';
import 'package:massdrive/core/constants/app_assets.dart';
import 'package:massdrive/core/constants/app_colors.dart';
import 'package:massdrive/core/constants/app_typography.dart';

class SearchInputBar extends StatelessWidget {
  const SearchInputBar({
    super.key,
    this.onSearchTap,
    this.onCameraTap,
    this.placeholder,
  });

  final VoidCallback? onSearchTap;
  final VoidCallback? onCameraTap;
  final String? placeholder;

  static const double _height = 40;
  static const BorderRadius _radius = BorderRadius.all(Radius.circular(32));

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.semanticGrayNeutralBgLightgray,
      shape: const RoundedRectangleBorder(
        side: BorderSide(width: 1, color: AppColors.semanticGrayNeutralBgWhite),
        borderRadius: _radius,
      ),
      child: InkWell(
        onTap: onSearchTap, // แตะแถบค้นหา
        borderRadius: _radius,
        child: SizedBox(
          height: _height,
          child: Row(
            children: [
              const Padding(
                padding: EdgeInsets.only(left: 12, right: 8),
                child: AssetImageWidget(
                  AppAssets.searchIcon,
                  width: 22,
                  height: 22,
                  color: AppColors.semanticGrayNeutralFgHigh,
                ),
              ),
              Expanded(
                child: Text(
                  placeholder ?? tr('home.app_bar_search_placeholder'),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.caption4.copyWith(
                    color: AppColors.semanticGrayNeutralFgMidOnWhite,
                  ),
                ),
              ),
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: onCameraTap,
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  child: AssetImageWidget(
                    AppAssets.cameraLineIcon,
                    width: 20,
                    height: 20,
                    color: AppColors.semanticGrayNeutralFgHigh,
                    format: .svg,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
