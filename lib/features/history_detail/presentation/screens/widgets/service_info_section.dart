import 'package:flutter/material.dart';
import 'package:massdrive/core/theme/app_palette.dart';
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
        color: context.palette.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(context, theme),
          const SizedBox(height: 16),
          _buildServiceRow(context,
            label: "ประเภทบริการ",
            value: _getServiceType(),
          ),
          if (data.isFood && data.restaurantName != null) ...[
            const SizedBox(height: 12),
            _buildServiceRow(context,
              label: "ร้านอาหาร",
              value: data.restaurantName!,
            ),
          ],
          const SizedBox(height: 12),
          _buildServiceRow(context,
            label: data.isFood ? "รับอาหารจาก" : "จุดรับ",
            value: data.pickupAddress,
          ),
          const SizedBox(height: 12),
          _buildServiceRow(context,
            label: data.isFood ? "ส่งที่" : "จุดส่ง",
            value: data.dropoffAddress,
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, ThemeData theme) {
    return Text(
      "ข้อมูลการให้บริการ",
      style: AppTypography.heading5.copyWith(
        color: context.palette.textPrimary,
      ),
    );
  }

  Widget _buildServiceRow(BuildContext context, {
    required String label,
    required String value,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTypography.caption5.copyWith(
            color: context.palette.textSecondary,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: AppTypography.caption4.copyWith(
            color: context.palette.textPrimary,
          ),
        ),
      ],
    );
  }

  /// Map serviceType from entity to display label
  String _getServiceType() {
    if (data.isFood) {
      return "ส่งอาหาร";
    }
    return "มอเตอร์ไซค์";
  }
}

