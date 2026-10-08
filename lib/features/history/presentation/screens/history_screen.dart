import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:massdrive/common/widgets/appbar/base_appbar.dart';
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
                            SliverList(
                              delegate: SliverChildBuilderDelegate(
                                (context, index) {
                                  if (index == state.items.length) {
                                    return const Center(
                                      child: Padding(
                                        padding: EdgeInsets.symmetric(
                                            vertical: 16),
                                        child: CircularProgressIndicator(),
                                      ),
                                    );
                                  }

                                  final item = state.items[index];
                                  return HistoryItemWidget(
                                    item: item,
                                    onTap: () {
                                      AppNavigator.push(
                                        context,
                                        HistoryDetailScreen(
                                          jobId: item.jobId ?? item.id,
                                        ),
                                      );
                                    },
                                  );
                                },
                                childCount: state.items.length +
                                    (state.isLoadingMore ? 1 : 0),
                              ),
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
            'ยังไม่มีรายการธุรกรรม',
            style: AppTypography.caption3.copyWith(
              color: context.palette.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

