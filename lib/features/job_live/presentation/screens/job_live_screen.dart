import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class JobLiveScreen extends StatefulWidget {
  const JobLiveScreen({super.key});

  @override
  State<JobLiveScreen> createState() => _JobLiveScreenState();
}

class _JobLiveScreenState extends State<JobLiveScreen> {
  final DraggableScrollableController _sheetController =
      DraggableScrollableController();

  final double _minSize = 0.12;
  final double _initialSize = 0.45;
  final double _maxSize = 0.85;

  double _currentSize = 0.45;

  @override
  void initState() {
    super.initState();
    _sheetController.addListener(() {
      setState(() {
        _currentSize = _sheetController.size;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          _buildMap(),
          _buildTopDistanceBadge(),
          _buildRightFloatingButtons(),
          _buildBottomSheet(),
        ],
      ),
    );
  }

  /// =========================
  /// MAP
  /// =========================
  Widget _buildMap() {
    return const GoogleMap(
      initialCameraPosition: CameraPosition(
        target: LatLng(13.7815, 100.5435),
        zoom: 16,
      ),
      zoomControlsEnabled: false,
      myLocationButtonEnabled: false,
      compassEnabled: false,
    );
  }

  /// =========================
  /// BOTTOM SHEET (PRODUCTION)
  /// =========================
  Widget _buildBottomSheet() {
    return DraggableScrollableSheet(
      initialChildSize: 0.45,
      minChildSize: 0.12,
      maxChildSize: 0.48,
      snap: true,
      snapSizes: const [0.12, 0.45, 0.48],
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Color(0xFF121212),
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: ListView(
            controller: scrollController,
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
            children: [
              _buildDragIndicator(),
              const SizedBox(height: 16),
              _buildTripHeader(),
              const SizedBox(height: 20),
              _buildPassengerInfo(),
              const SizedBox(height: 20),
              _buildContactRow(),
              const SizedBox(height: 24),
              _buildArrivedButton(),
            ],
          ),
        );
      },
    );
  }

  /// =========================
  /// UI COMPONENTS (เหมือนของเดิม)
  /// =========================

  Widget _buildTopDistanceBadge() {
    return Positioned(
      top: 70,
      left: 16,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.85),
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Text(
          "570 ม.",
          style: TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildRightFloatingButtons() {
    return Positioned(
      right: 16,
      top: 160,
      child: Column(
        children: [
          _circleButton(Icons.shield_outlined),
          const SizedBox(height: 12),
          _circleButton(Icons.notifications_none),
        ],
      ),
    );
  }

  Widget _circleButton(IconData icon) {
    return Container(
      width: 52,
      height: 52,
      decoration: const BoxDecoration(
        color: Color(0xFF1C1C1E),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: Colors.white),
    );
  }

  Widget _buildDragIndicator() {
    return Center(
      child: Container(
        width: 40,
        height: 4,
        decoration: BoxDecoration(
          color: Colors.grey[700],
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  Widget _buildTripHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: const [
        Text(
          "1. รับผู้โดยสาร",
          style: TextStyle(
            color: Colors.green,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 4),
        Text(
          "Saver Bike",
          style: TextStyle(color: Colors.white70, fontSize: 14),
        ),
      ],
    );
  }

  Widget _buildPassengerInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: const [
        Text(
          "Prim Winurach",
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 8),
        Text(
          "เซเว่น อีเลฟเว่น พหลโยธิน ซอย 8\n"
          "ถนนพหลโยธิน พญาไท กรุงเทพ 10400",
          style: TextStyle(color: Colors.white60, fontSize: 14),
        ),
        SizedBox(height: 12),
        Text(
          "฿39 • GrabPay",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }

  Widget _buildContactRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _bottomAction(Icons.chat_bubble_outline, "แชท"),
        _bottomAction(Icons.phone_outlined, "โทรฟรี"),
        _bottomAction(Icons.help_outline, "ช่วยเหลือ"),
        _bottomAction(Icons.more_horiz, "อื่นๆ"),
      ],
    );
  }

  Widget _bottomAction(IconData icon, String label) {
    return Column(
      children: [
        Icon(icon, color: Colors.white70),
        const SizedBox(height: 6),
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildArrivedButton() {
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        color: Colors.green,
        borderRadius: BorderRadius.circular(16),
      ),
      alignment: Alignment.center,
      child: const Text(
        "ถึงแล้ว",
        style: TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
