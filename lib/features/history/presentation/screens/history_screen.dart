import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:massdrive/common/widgets/appbar/base_appbar.dart';
import 'package:massdrive/common/widgets/earnings/day_job_groups.dart';
import 'package:massdrive/common/widgets/earnings/job_earnings_card.dart';
import 'package:massdrive/core/constants/app_colors.dart';
import 'package:massdrive/features/history/domain/models/history_item_model.dart';
import 'package:massdrive/features/history/domain/models/trip_history_rows.dart';
import 'package:massdrive/features/history/presentation/states/history_state.dart';
import 'package:massdrive/common/widgets/indicator/mass_loading_m.dart';
import 'package:massdrive/core/theme/app_palette.dart';
import 'package:massdrive/core/constants/app_typography.dart';
import 'package:massdrive/core/navigation/app_navigator.dart';
import 'package:massdrive/features/history/presentation/controllers/history_controller.dart';
import 'package:massdrive/features/history/presentation/widgets/history_item.dart';
import 'package:massdrive/features/history/presentation/widgets/date_selector.dart';
import 'package:massdrive/features/history_detail/presentation/screens/history_detail_screen.dart';

// ---------------------------------------------------------------------------
// Screen
// ---------------------------------------------------------------------------
class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key});

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(historyControllerProvider.notifier).fetchHistoryList();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      ref.read(historyControllerProvider.notifier).loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(historyControllerProvider);

    return Scaffold(
      appBar: CommonAppBar(
        titleText: 'ประวัติการให้บริการ',
        showLeftIcon: true,
      ),
      body: Container(
        color: context.palette.bg,
        child: Column(
          children: [
            DateSelector(
              selectedDate: state.selectedDate,
              onSelected: (date) => ref
                  .read(historyControllerProvider.notifier)
                  .setDateFilter(date),
            ),
            Expanded(
              child: state.isLoading
                  ? const Center(child: MassLoadingM(size: 72))
                  : state.items.isEmpty
                      ? _buildEmptyState()
                      : CustomScrollView(
                          controller: _scrollController,
                          slivers: [
                            SliverPadding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                              sliver: _buildCards(state),
                            ),
                            // Clear the Android edge-to-edge system nav.
                            SliverToBoxAdapter(
                              child: SizedBox(
                                height:
                                    MediaQuery.viewPaddingOf(context).bottom,
                              ),
                            ),
                          ],
                        ),
            ),
          ],
        ),
      ),
    );
  }

  // -------------------------------------------------------------------------
  // Job cards (design E) under a day header — same card as รายการทั้งหมด
  // -------------------------------------------------------------------------
  Widget _buildCards(HistoryState state) {
    final entries = groupByDayAndJob<HistoryItemModel>(
      state.items,
      time: (i) => i.dateTime,
      jobId: (i) => i.jobId,
    );
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          if (index == entries.length) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: CircularProgressIndicator(),
              ),
            );
          }
          return switch (entries[index]) {
            DayHeader(:final date) => EarningsDayHeader(date: date),
            JobGroup(:final jobId, :final items) => _card(jobId, items),
            SingleRow(:final item) => HistoryItemWidget(
              item: item,
              onTap: () => AppNavigator.push(
                context,
                HistoryDetailScreen(jobId: item.jobId ?? item.id),
              ),
            ),
          };
        },
        childCount: entries.length + (state.isLoadingMore ? 1 : 0),
      ),
    );
  }

  Widget _card(String jobId, List<HistoryItemModel> items) {
    final rows = jobCardOrder(items);
    final first = rows.first;
    return JobEarningsCard(
      jobId: jobId,
      time: items
          .map((i) => i.dateTime)
          .reduce((a, b) => a.isAfter(b) ? a : b),
      service: first.serviceType == ServiceType.food ? 'food' : first.service,
      vehicleTypeName: first.vehicleTypeName,
      pickupAddress: rows
          .map((i) => i.pickupAddress)
          .firstWhere((a) => a != null && a.trim().isNotEmpty, orElse: () => null),
      driverNet: first.tripNet,
      lines: [
        for (final i in rows)
          JobCardLine(
            label: historyLineLabel(i),
            amount: i.amount ?? 0,
            badge: i.status == HistoryStatus.cancelled
                ? Text(
                    'ยกเลิก',
                    style: AppTypography.caption5.copyWith(
                      color: AppColors.semanticSupportRedBgHigh,
                    ),
                  )
                : null,
          ),
      ],
      onTap: () => AppNavigator.push(context, HistoryDetailScreen(jobId: jobId)),
    );
  }

  // -------------------------------------------------------------------------
  // Empty state
  // -------------------------------------------------------------------------
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.receipt_long_rounded,
            size: 64,
            color: context.palette.textSecondary,
          ),
          const SizedBox(height: 16),
          Text(
            // This screen lists jobs only (fares, commissions).
            ref.read(historyControllerProvider).selectedDate == null
                ? 'ยังไม่มีงาน'
                : 'ยังไม่มีงานในวันนี้',
            style: AppTypography.caption3.copyWith(
              color: context.palette.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

