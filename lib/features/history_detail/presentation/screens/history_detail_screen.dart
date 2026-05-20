import 'package:flutter/material.dart';
import 'package:massdrive/common/widgets/appbar/base_appbar.dart';
import 'package:massdrive/core/constants/app_colors.dart';
import 'package:massdrive/features/history_detail/domain/entities/history_entity.dart';
import 'package:massdrive/features/history_detail/presentation/screens/widgets/history_map_section.dart';
import 'package:massdrive/features/history_detail/presentation/screens/widgets/order_items_section.dart';
import 'package:massdrive/features/history_detail/presentation/screens/widgets/payment_section.dart';
import 'package:massdrive/features/history_detail/presentation/screens/widgets/service_info_section.dart';
import 'package:massdrive/features/history_detail/presentation/screens/widgets/your_net_income_section.dart';

class HistoryDetailScreen extends StatelessWidget {
  final String historyId;
  final bool isFood;

  HistoryDetailScreen({
    super.key,
    required this.historyId,
    this.isFood = false,
  });

  HistoryDetailEntity get data =>
      isFood ? HistoryMock.foodDetail : HistoryMock.detail;

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
                  if (data.isFood) OrderItemsSection(data: data),
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
    serviceType: 'ride',
  );

  static HistoryDetailEntity foodDetail = HistoryDetailEntity(
    id: "F-XK2LM9P4QWRT",
    dateTime: DateTime(2025, 12, 24, 22, 15),
    pickupAddress: "ร้านขนมหวานสุดอร่อย 123 ถนนเพชรบุรี เขตราชเทวี",
    dropoffAddress: "Condo 14/22 ตึกตรงขวาง ใต้ต้นไม้ใหญ่",
    distanceKm: 3.2,
    durationMinute: 12,
    total: 45.0,
    paymentMethod: "เงินสด",
    driverNet: 45.0,
    serviceType: 'food',
    restaurantName: "ร้านขนมหวานสุดอร่อย",
    orderItems: [
      {
        'name': 'Honey Toast ฉ่ำๆ',
        'qty': 1,
        'price': 150.0,
        'note': 'แยกน้ำผึ้ง',
      },
      {
        'name': 'Taiwan Milk Tea',
        'qty': 1,
        'price': 65.0,
        'note': 'หวาน 50%, เพิ่มไข่มุกน้ำผึ้ง',
      },
    ],
  );
}

