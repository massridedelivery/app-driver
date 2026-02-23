import 'package:flutter/material.dart';
import 'package:massdrive/common/widgets/appbar/base_appbar.dart';
import 'package:massdrive/core/constants/app_colors.dart';
import 'package:massdrive/features/history_detail/domain/entities/history_entity.dart';
import 'package:massdrive/features/history_detail/presentation/screens/widgets/history_map_section.dart';
import 'package:massdrive/features/history_detail/presentation/screens/widgets/payment_section.dart';
import 'package:massdrive/features/history_detail/presentation/screens/widgets/service_info_section.dart';
import 'package:massdrive/features/history_detail/presentation/screens/widgets/your_net_income_section.dart';

class HistoryDetailScreen extends StatelessWidget {
  final String historyId;
  final data = HistoryMock.detail;

  HistoryDetailScreen({super.key, required this.historyId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonAppBar(
        titleText: 'รายละเอียดการให้บริการ',
        showLeftIcon: true,
      ),
      body: Container(
        color: AppColors.semanticGrayNeutralFgHigh,
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Column(
                children: [
                  HistoryMapSection(data: data),
                  ServiceInfoSection(data: data),
                  PaymentSection(data: data),
                  YourNetIncomeSection(data: data),
                  SizedBox(height: 24.0),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class HistoryMock {
  static HistoryDetailEntity detail = HistoryDetailEntity(
    id: "A-8P8KEI5GWRFGAV",
    dateTime: DateTime(2025, 12, 24, 23, 31),
    pickupAddress: "เซเว่น อีเลฟเว่น พระราม 6 ซอย 5",
    dropoffAddress: "453/13 ซอยแก้วฟ้า มหาพฤฒาราม บางรัก",
    distanceKm: 1.75,
    durationMinute: 6,
    total: 30.0,
    paymentMethod: "QR Payment",
    driverNet: 30.0,
  );
}
