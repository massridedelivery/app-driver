import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:massdrive/common/widgets/appbar/base_appbar.dart';
import 'package:massdrive/core/constants/app_colors.dart';
import 'package:massdrive/core/constants/app_typography.dart';
import 'package:massdrive/features/dependency_injection.dart';
import 'package:massdrive/features/messenger/domain/models/messenger_order.dart';
import 'package:massdrive/features/messenger/domain/repositories/messenger_repository.dart';

/// Completed (DELIVERED) messenger deliveries, paginated (SCRUM-41 §2).
class MessengerHistoryScreen extends StatefulWidget {
  const MessengerHistoryScreen({super.key});

  @override
  State<MessengerHistoryScreen> createState() => _MessengerHistoryScreenState();
}

class _MessengerHistoryScreenState extends State<MessengerHistoryScreen> {
  static const _pageSize = 20;
  final _scrollController = ScrollController();
  final List<MessengerOrder> _orders = [];

  bool _isLoading = false;
  bool _hasMore = true;
  int _total = 0;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _load();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _load();
    }
  }

  Future<void> _load() async {
    if (_isLoading || !_hasMore) return;
    setState(() => _isLoading = true);
    try {
      final page = await getIt<MessengerRepository>().getCompletedOrders(
        limit: _pageSize,
        offset: _orders.length,
      );
      if (!mounted) return;
      setState(() {
        _orders.addAll(page.orders);
        _total = page.total;
        _hasMore = _orders.length < page.total && page.orders.isNotEmpty;
      });
    } catch (_) {
      if (mounted) setState(() => _hasMore = false);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.semanticGrayNeutralFgHigh,
      appBar: CommonAppBar(
        titleText: _total > 0 ? 'ประวัติงานส่งพัสดุ ($_total)' : 'ประวัติงานส่งพัสดุ',
        showLeftIcon: true,
      ),
      body: _orders.isEmpty && _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _orders.isEmpty
              ? _buildEmpty()
              : ListView.separated(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: _orders.length + (_isLoading ? 1 : 0),
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    if (index == _orders.length) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 16),
                          child: CircularProgressIndicator(),
                        ),
                      );
                    }
                    return _HistoryTile(order: _orders[index]);
                  },
                ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.local_shipping_outlined,
              size: 64, color: AppColors.foundationAlphaWhite400),
          const SizedBox(height: 16),
          Text('ยังไม่มีประวัติงานส่งพัสดุ',
              style: AppTypography.caption3
                  .copyWith(color: AppColors.foundationAlphaWhite400)),
        ],
      ),
    );
  }
}

class _HistoryTile extends StatelessWidget {
  final MessengerOrder order;

  const _HistoryTile({required this.order});

  @override
  Widget build(BuildContext context) {
    final when = order.deliveredAt ?? order.createdAt;
    final dateText =
        when != null ? DateFormat('d MMM yyyy, HH:mm').format(when.toLocal()) : '';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.foundationAlphaWhite100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.semanticSuccessBgHigh.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check_rounded,
                color: AppColors.semanticSuccessBgHigh),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  order.recipientName ?? order.dropoffAddress ?? 'งานส่งพัสดุ',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.caption3
                      .copyWith(color: AppColors.semanticGrayNeutralBgWhite),
                ),
                const SizedBox(height: 4),
                Text(
                  'ขนาด ${order.packageSizeTier} · $dateText',
                  style: AppTypography.caption5
                      .copyWith(color: AppColors.foundationAlphaWhite400),
                ),
              ],
            ),
          ),
          Text(
            '฿${order.fare.toStringAsFixed(0)}',
            style: AppTypography.caption3.copyWith(
              color: AppColors.semanticGrayNeutralBgWhite,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
