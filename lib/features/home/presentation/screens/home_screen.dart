import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:massdrive/core/constants/app_colors.dart';
import 'package:massdrive/core/constants/app_typography.dart';
import 'package:massdrive/core/navigation/app_navigator.dart';
import 'package:massdrive/features/income/presentation/screens/income_screen.dart';
import 'package:massdrive/features/job_live/presentation/screens/job_live_screen.dart';
import 'package:massdrive/features/profile/presentation/screens/profile_screen.dart';
import 'package:massdrive/features/service_type/presentation/screens/service_type_screen.dart';
import 'package:massdrive/features/setting/presentation/screens/setting_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  late DraggableScrollableController _sheetController;

  double _sheetSize = 0.35;
  bool isOnline = false;

  final double _minSize = 0.25;
  final double _maxSize = 0.85;

  @override
  void initState() {
    super.initState();

    _sheetController = DraggableScrollableController();

    _sheetController.addListener(() {
      setState(() {
        _sheetSize = _sheetController.size;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.semanticGrayNeutralFgWhite,
      body: Stack(children: [_buildMap(), _buildBottomSheet()]),
    );
  }

  // ================= MAP =================

  Widget _buildMap() {
    return const SizedBox.expand(
      child: GoogleMap(
        initialCameraPosition: CameraPosition(
          target: LatLng(13.7563, 100.5018),
          zoom: 14,
        ),
        myLocationEnabled: true,
        zoomControlsEnabled: false,
        myLocationButtonEnabled: false,
      ),
    );
  }

  // ================= BOTTOM SHEET =================

  Widget _buildBottomSheet() {
    return DraggableScrollableSheet(
      controller: _sheetController,
      initialChildSize: 0.40,
      minChildSize: _minSize,
      maxChildSize: _maxSize,
      snap: true,
      snapSizes: const [0.40, 0.85],
      builder: (context, scrollController) {
        return Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 26),
              decoration: const BoxDecoration(
                color: AppColors.semanticGrayNeutralFgHigh,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: SingleChildScrollView(
                controller: scrollController,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 22, 14, 40),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 40,
                          height: 5,
                          decoration: BoxDecoration(
                            color: AppColors.foundationAlphaWhite500,
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      _buildStatusCard(),
                      _buildMenuRow(),
                      const SizedBox(height: 500),
                    ],
                  ),
                ),
              ),
            ),

            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Center(child: _buildOnlineButton()),
            ),
          ],
        );
      },
    );
  }

  Widget _buildOnlineButton() {
    return GestureDetector(
      onTap: () {
        AppNavigator.push(context, const JobLiveScreen());
        setState(() {
          isOnline = !isOnline;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(40),
          gradient: LinearGradient(
            colors: isOnline
                ? [
                    AppColors.semanticSupportMintBgHigh,
                    AppColors.semanticSupportMintBgMid,
                    AppColors.semanticSupportMintBgHigh,
                  ]
                : [
                    AppColors.foundationOrange700,
                    AppColors.foundationOrange500,
                    AppColors.foundationOrange700,
                  ],
          ),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.4), blurRadius: 20),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.power_settings_new,
              color: AppColors.semanticGrayNeutralBgWhite,
            ),
            const SizedBox(width: 10),
            Text(
              isOnline ? "พร้อมรับงาน" : "ปิดรับงาน",
              style: AppTypography.heading5.copyWith(
                color: AppColors.semanticGrayNeutralBgWhite,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ================= STATUS CARD =================

  Widget _buildStatusCard() {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.foundationAlphaWhite100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 6,
            backgroundColor: isOnline
                ? AppColors.semanticSupportMintBgHigh
                : AppColors.foundationOrange700,
          ),
          const SizedBox(width: 12),
          Text(
            isOnline ? "ระบบกำลังค้นหางาน...." : "คุณปิดรับงาน",
            style: AppTypography.caption3.copyWith(
              color: AppColors.semanticGrayNeutralBgWhite,
            ),
          ),
        ],
      ),
    );
  }

  // ================= MENU =================

  Widget _buildMenuRow() {
    return GridView.count(
      padding: EdgeInsets.symmetric(vertical: 16),
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      crossAxisCount: 4,
      crossAxisSpacing: 10,
      mainAxisSpacing: 2,
      childAspectRatio: 1,
      children: [
        _circleMenu(Icons.card_giftcard, "รายได้", () {
          AppNavigator.push(context, const IncomeScreen());
        }),
        _circleMenu(Icons.directions_car, "ประเภทบริการ", () {
          AppNavigator.push(context, const ServiceTypeScreen());
        }),
        _circleMenu(Icons.location_on, "ปลายทางของฉัน", () {}),
        _circleMenu(Icons.person_sharp, "โปรไฟล์", () {
          AppNavigator.push(context, const ProfileScreen());
        }),
        _circleMenu(Icons.settings_sharp, "การตั้งค่า", () {
          AppNavigator.push(context, const SettingScreen());
        }),
      ],
    );
  }

  Widget _circleMenu(IconData icon, String text, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(50),
      child: Column(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white10,
            ),
            child: Icon(icon, color: AppColors.foundationOrange700),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: 90,
            child: Text(
              text,
              textAlign: TextAlign.center,
              style: AppTypography.caption5.copyWith(
                color: AppColors.semanticGrayNeutralBgWhite,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
