import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:massdrive/common/widgets/appbar/base_appbar.dart';
import 'package:massdrive/common/widgets/indicator/mass_loading_m.dart';
import 'package:massdrive/core/theme/app_palette.dart';
import 'package:massdrive/core/constants/app_typography.dart';
import 'package:massdrive/features/history_detail/presentation/controllers/history_detail_provider.dart';
import 'package:massdrive/features/history_detail/presentation/screens/widgets/history_map_section.dart';
import 'package:massdrive/features/history_detail/presentation/screens/widgets/order_items_section.dart';
import 'package:massdrive/features/history_detail/presentation/screens/widgets/payment_section.dart';
import 'package:massdrive/features/history_detail/presentation/screens/widgets/service_info_section.dart';
import 'package:massdrive/features/history_detail/presentation/screens/widgets/your_net_income_section.dart';

class HistoryDetailScreen extends ConsumerWidget {
  /// Job/trip id of the tapped history row (`job_id`). Trip detail is loaded
  /// from the real earnings endpoints via [historyDetailProvider].
  final String jobId;

  const HistoryDetailScreen({super.key, required this.jobId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(historyDetailProvider(jobId));
    return Scaffold(
      appBar: CommonAppBar(
        titleText: 'รายละเอียดการให้บริการ',
        showLeftIcon: true,
      ),
      body: Container(
        color: context.palette.bg,
        child: async.when(
          loading: () => const Center(child: MassLoadingM(size: 64)),
          error: (_, _) => _message(
            context,
            'โหลดรายละเอียดไม่สำเร็จ ลองใหม่อีกครั้ง',
          ),
          data: (data) => data == null
              ? _message(
                  context,
                  'ไม่มีรายละเอียดการเดินทางสำหรับรายการนี้',
                )
              : CustomScrollView(
                  slivers: [
                    SliverToBoxAdapter(
                      child: Column(
                        children: [
                          HistoryMapSection(data: data),
                          ServiceInfoSection(data: data),
                          if (data.isFood) OrderItemsSection(data: data),
                          PaymentSection(data: data),
                          YourNetIncomeSection(data: data),
                          const SizedBox(height: 24.0),
                        ],
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: SizedBox(
                        height: MediaQuery.viewPaddingOf(context).bottom,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _message(BuildContext context, String text) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.receipt_long_outlined,
                  size: 56, color: context.palette.textTertiary),
              const SizedBox(height: 12),
              Text(
                text,
                textAlign: TextAlign.center,
                style: AppTypography.caption3
                    .copyWith(color: context.palette.textSecondary),
              ),
            ],
          ),
        ),
      );
}
