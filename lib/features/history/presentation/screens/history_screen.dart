import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:massdrive/common/widgets/appbar/base_appbar.dart';
import 'package:massdrive/core/constants/app_colors.dart';
import 'package:massdrive/core/constants/app_typography.dart';
import 'package:massdrive/core/navigation/app_navigator.dart';
import 'package:massdrive/features/history/domain/models/history_item_model.dart';
import 'package:massdrive/features/history/presentation/controllers/history_controller.dart';
import 'package:massdrive/features/history/presentation/widgets/history_item.dart';
import 'package:massdrive/features/history_detail/presentation/screens/history_detail_screen.dart';

// ---------------------------------------------------------------------------
// Filter definitions
// ---------------------------------------------------------------------------
class _FilterOption {
  final String label;
  final String? apiValue; // null = "All"

  const _FilterOption(this.label, this.apiValue);
}

const _filters = [
  _FilterOption('ทั้งหมด', null),
  _FilterOption('ค่าโดยสาร', 'FARE_PAYMENT'),
  _FilterOption('ค่าคอมมิชชัน', 'COMMISSION_DEDUCTION'),
  _FilterOption('เติมเงิน', 'TOPUP'),
  _FilterOption('ถอนเงิน', 'WITHDRAWAL'),
  _FilterOption('โบนัส', 'BONUS'),
  _FilterOption('ปรับยอด', 'ADJUSTMENT'),
];

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

  void _onFilterTap(String? apiValue) {
    final current = ref.read(historyControllerProvider).selectedType;
    // Tap same chip → deselect (show all)
    ref
        .read(historyControllerProvider.notifier)
        .setTypeFilter(current == apiValue ? null : apiValue);
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
        color: AppColors.semanticGrayNeutralFgHigh,
        child: Column(
          children: [
            _buildFilterBar(state.selectedType),
            Expanded(
              child: state.isLoading
                  ? const Center(child: CircularProgressIndicator())
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
                                          historyId: item.id,
                                          isFood: item.serviceType ==
                                              ServiceType.food,
                                        ),
                                      );
                                    },
                                  );
                                },
                                childCount: state.items.length +
                                    (state.isLoadingMore ? 1 : 0),
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
  // Filter bar
  // -------------------------------------------------------------------------
  Widget _buildFilterBar(String? selectedType) {
    return Container(
      height: 48,
      color: AppColors.semanticGrayNeutralFgHigh,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: _filters.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final filter = _filters[index];
          final isSelected = filter.apiValue == selectedType;
          return _FilterChip(
            label: filter.label,
            isSelected: isSelected,
            onTap: () => _onFilterTap(filter.apiValue),
          );
        },
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
            color: AppColors.foundationAlphaWhite400,
          ),
          const SizedBox(height: 16),
          Text(
            'ยังไม่มีรายการธุรกรรม',
            style: AppTypography.caption3.copyWith(
              color: AppColors.foundationAlphaWhite400,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Filter chip widget
// ---------------------------------------------------------------------------
class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.semanticPrimaryBgLow
              : Colors.white.withOpacity(0.08),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? AppColors.semanticPrimaryBgLow
                : Colors.white24,
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: AppTypography.caption5.copyWith(
            color: isSelected ? Colors.white : Colors.white60,
            fontWeight:
                isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}
