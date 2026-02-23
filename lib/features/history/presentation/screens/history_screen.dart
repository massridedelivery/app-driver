import 'package:flutter/material.dart';
import 'package:massdrive/common/widgets/appbar/base_appbar.dart';
import 'package:massdrive/core/constants/app_colors.dart';
import 'package:massdrive/core/navigation/app_navigator.dart';
import 'package:massdrive/features/history/domain/models/history_item_model.dart';
import 'package:massdrive/features/history/presentation/widgets/history_item.dart';
import 'package:massdrive/features/history_detail/presentation/screens/history_detail_screen.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final ScrollController _scrollController = ScrollController();

  bool isDaily = true;

  final List<HistoryItemModel> items = [
    HistoryItemModel(
      id: "1",
      dateTime: DateTime.now(),
      title: "เกษรอัมรินทร์ ทางเข้าล็อบบี้ออฟฟิศ",
      amount: 28,
      paymentType: PaymentType.grabPay,
      status: HistoryStatus.completed,
    ),
    HistoryItemModel(
      id: "2",
      dateTime: DateTime.now(),
      title: "ก๋วยเตี๋ยวต้มยำสามล้อสูตรโบราณ",
      status: HistoryStatus.cancelled,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonAppBar(
        titleText: 'ประวัติการให้บริการ',
        showLeftIcon: true,
      ),
      body: Container(
        color: AppColors.semanticGrayNeutralFgHigh,
        child: CustomScrollView(
          controller: _scrollController,
          slivers: [
            // /// Toggle
            // SliverToBoxAdapter(
            //   child: HistoryToggle(
            //     isDaily: isDaily,
            //     onChanged: (value) {
            //       setState(() => isDaily = value);
            //     },
            //   ),
            // ),
            //
            // /// Date Selector
            // SliverToBoxAdapter(child: DateSelector()),

            /// List
            SliverList(
              delegate: SliverChildBuilderDelegate((context, index) {
                final item = items[index];

                return HistoryItemWidget(
                  item: item,
                  onTap: () {
                    AppNavigator.push(
                      context,
                      HistoryDetailScreen(historyId: ''),
                    );
                  },
                );
              }, childCount: items.length),
            ),
          ],
        ),
      ),
    );
  }
}
