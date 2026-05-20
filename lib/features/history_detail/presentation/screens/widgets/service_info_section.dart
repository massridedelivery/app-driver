import 'package:flutter/material.dart';
import 'package:massdrive/core/constants/app_colors.dart';
import 'package:massdrive/core/constants/app_typography.dart';
import 'package:massdrive/features/history_detail/domain/entities/history_entity.dart';

class ServiceInfoSection extends StatelessWidget {
  final HistoryDetailEntity data;

  const ServiceInfoSection({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.semanticGrayNeutralBgWhite,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(theme),
          const SizedBox(height: 16),
          _buildServiceRow(
            icon: data.isFood ? Icons.fastfood : Icons.two_wheeler_sharp,
            label: "ประเภทบริการ",
            value: _getServiceType(),
            iconColor: data.isFood
                ? AppColors.foundationOrange600
                : null,
          ),
          if (data.isFood && data.restaurantName != null) ...[
            const SizedBox(height: 12),
            _buildServiceRow(
              icon: Icons.storefront,
              label: "ร้านอาหาร",
              value: data.restaurantName!,
              iconColor: AppColors.foundationOrange600,
            ),
          ],
          const SizedBox(height: 12),
          _buildServiceRow(
            icon: Icons.location_on_outlined,
            label: data.isFood ? "รับอาหารจาก" : "จุดรับ",
            value: data.pickupAddress,
          ),
          const SizedBox(height: 12),
          _buildServiceRow(
            icon: Icons.flag_outlined,
            label: data.isFood ? "ส่งที่" : "จุดส่ง",
            value: data.dropoffAddress,
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return Text(
      "ข้อมูลการให้บริการ",
      style: AppTypography.heading5.copyWith(
        color: AppColors.semanticGrayNeutralFgHigh,
      ),
    );
  }

  Widget _buildServiceRow({
    required IconData icon,
    required String label,
    required String value,
    Color? iconColor,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: iconColor),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: AppTypography.caption5.copyWith(
                  color: AppColors.semanticGrayNeutralFgMidOnGray,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: AppTypography.caption4.copyWith(
                  color: AppColors.semanticGrayNeutralFgHigh,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Map serviceType from entity to display label
  String _getServiceType() {
    if (data.isFood) {
      return "MassFood Delivery";
    }
    return "Saver Bike";
  }
}

