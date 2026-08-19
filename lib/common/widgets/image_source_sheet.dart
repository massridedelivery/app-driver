import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:massdrive/core/constants/app_colors.dart';
import 'package:massdrive/core/constants/app_typography.dart';

/// Bottom sheet that lets the driver pick an image source — take a photo with
/// the camera or choose from the gallery. Returns the chosen [ImageSource], or
/// null if the sheet is dismissed.
Future<ImageSource?> showImageSourceSheet(BuildContext context) {
  return showModalBottomSheet<ImageSource>(
    context: context,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (sheetContext) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 10),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.semanticGrayNeutralBorderLightgray,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 6),
          ListTile(
            leading: const Icon(
              Icons.camera_alt_outlined,
              color: AppColors.semanticGrayNeutralFgHigh,
            ),
            title: Text(
              'ถ่ายรูป',
              style: AppTypography.label2.copyWith(
                color: AppColors.semanticGrayNeutralFgHigh,
              ),
            ),
            onTap: () => Navigator.pop(sheetContext, ImageSource.camera),
          ),
          ListTile(
            leading: const Icon(
              Icons.photo_library_outlined,
              color: AppColors.semanticGrayNeutralFgHigh,
            ),
            title: Text(
              'เลือกจากคลังภาพ',
              style: AppTypography.label2.copyWith(
                color: AppColors.semanticGrayNeutralFgHigh,
              ),
            ),
            onTap: () => Navigator.pop(sheetContext, ImageSource.gallery),
          ),
          const SizedBox(height: 8),
        ],
      ),
    ),
  );
}
