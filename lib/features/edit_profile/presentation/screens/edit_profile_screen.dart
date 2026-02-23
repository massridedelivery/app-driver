import 'package:flutter/material.dart';
import 'package:massdrive/common/widgets/appbar/base_appbar.dart';
import 'package:massdrive/core/constants/app_colors.dart';
import 'package:massdrive/core/constants/app_typography.dart';

class EditProfileScreen extends StatelessWidget {
  const EditProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonAppBar(titleText: 'โปรไฟล์', showLeftIcon: true),
      backgroundColor: const Color(0xFF0F0F0F),
      body: Container(
        color: AppColors.semanticGrayNeutralFgHigh,
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          children: const [
            SizedBox(height: 12),

            _SectionHeader(title: "ข้อมูลส่วนตัว"),

            _ProfileImageTile(),

            _InfoTile(title: "ชื่อ", value: "(GB) ธนนันต์ อนุรักษ์ศิลปกุล"),

            _InfoTile(
              title: "หมายเลขโทรศัพท์มือถือ",
              value: "+66 892616445",
              showArrow: true,
            ),

            _InfoTile(title: "ที่อยู่อีเมล", value: "bankzapse@gmail.com"),

            _InfoTile(
              title: "รายชื่อผู้ติดต่อฉุกเฉิน",
              value: "ได้ตั้งค่ารายชื่อผู้ติดต่อจำนวน 1 จาก 3 รายการแล้ว",
              showArrow: true,
            ),

            SizedBox(height: 24),

            _SectionHeader(title: "หากคุณย้ายไปที่ใหม่"),

            _InfoTile(
              title: "",
              value: "เลือกประเภทพื้นที่/บริการใหม่",
              showArrow: true,
              leadingIcon: Icons.map,
            ),

            SizedBox(height: 24),

            _SectionHeader(title: "ข้อมูลของยานพาหนะ"),

            _VehicleTile(
              plate: "8กส418",
              vehicle: "YAMAHA GRAND FILANO",
              isPrimary: true,
            ),

            _VehicleTile(
              plate: "5ขง 933",
              vehicle: "HONDA CLICK",
              hasWarning: true,
            ),

            SizedBox(height: 32),

            _SectionHeader(title: "เอกสาร"),

            _InfoTile(
              title: "",
              value: "เลือกเอกสารที่ต้องการอัปเดต",
              showArrow: true,
            ),

            const SizedBox(height: 24),

            _SectionHeader(title: "จัดการบัญชีของคุณ"),

            _DeleteAccountTile(),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: AppTypography.caption3.copyWith(
          color: AppColors.semanticGrayNeutralBgWhite,
        ),
      ),
    );
  }
}

class _ProfileImageTile extends StatelessWidget {
  const _ProfileImageTile();

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(
        "รูปโปรไฟล์",
        style: AppTypography.caption3.copyWith(
          color: AppColors.semanticGrayNeutralBgWhite,
        ),
      ),
      trailing: const CircleAvatar(
        radius: 24,
        backgroundImage: NetworkImage("https://i.pravatar.cc/150?img=3"),
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final String title;
  final String value;
  final bool showArrow;
  final IconData? leadingIcon;

  const _InfoTile({
    required this.title,
    required this.value,
    this.showArrow = false,
    this.leadingIcon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: leadingIcon != null
              ? Icon(leadingIcon, color: AppColors.foundationAlphaWhite400)
              : null,
          title: title.isNotEmpty
              ? Text(
                  title,
                  style: AppTypography.caption4.copyWith(
                    color: AppColors.foundationAlphaWhite400,
                  ),
                )
              : null,
          subtitle: Text(
            value,
            style: AppTypography.caption3.copyWith(
              color: AppColors.semanticGrayNeutralBgWhite,
            ),
          ),
          trailing: showArrow
              ? const Icon(
                  Icons.chevron_right,
                  color: AppColors.semanticGrayNeutralFgLowOnGray,
                )
              : null,
        ),
        const Divider(color: Colors.white12, height: 1),
      ],
    );
  }
}

class _VehicleTile extends StatelessWidget {
  final String plate;
  final String vehicle;
  final bool isPrimary;
  final bool hasWarning;

  const _VehicleTile({
    required this.plate,
    required this.vehicle,
    this.isPrimary = false,
    this.hasWarning = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(
            plate,
            style: AppTypography.caption3.copyWith(
              color: AppColors.semanticGrayNeutralBgWhite,
            ),
          ),
          subtitle: Text(
            vehicle,
            style: const TextStyle(color: Colors.white70),
          ),
          trailing: hasWarning
              ? const Icon(
                  Icons.error_outline,
                  color: AppColors.semanticErrorFgHigh,
                )
              : isPrimary
              ? const Icon(Icons.check, color: AppColors.semanticSuccessFgHigh)
              : const Icon(
                  Icons.chevron_right,
                  color: AppColors.semanticGrayNeutralFgLowOnGray,
                ),
        ),
        const Divider(color: Colors.white12, height: 1),
      ],
    );
  }
}

class _DeleteAccountTile extends StatelessWidget {
  const _DeleteAccountTile();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(
            "ลบบัญชี",
            style: AppTypography.caption3.copyWith(
              color: AppColors.semanticErrorFgHigh,
            ),
          ),
          subtitle: Text(
            "ข้อมูลทั้งหมดในบัญชีจะถูกลบออก",
            style: AppTypography.caption5.copyWith(
              color: AppColors.semanticGrayNeutralBgWhite,
            ),
          ),
          trailing: const Icon(
            Icons.chevron_right,
            color: AppColors.semanticGrayNeutralFgLowOnGray,
          ),
          onTap: () {
            _showDeleteDialog(context);
          },
        ),
        const Divider(color: Colors.white12, height: 1),
      ],
    );
  }

  void _showDeleteDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: Text(
          "ยืนยันการลบบัญชี",
          style: AppTypography.caption3.copyWith(
            color: AppColors.semanticGrayNeutralBgWhite,
          ),
        ),
        content: Text(
          "คุณแน่ใจหรือไม่ว่าต้องการลบบัญชี?\nการดำเนินการนี้ไม่สามารถย้อนกลับได้",
          style: AppTypography.caption4.copyWith(
            color: AppColors.semanticGrayNeutralFgLowOnWhite,
          ),
        ),
        actions: [
          TextButton(
            child: Text(
              "ยกเลิก",
              style: AppTypography.caption3.copyWith(
                color: AppColors.semanticGrayNeutralFgLowOnWhite,
              ),
            ),
            onPressed: () => Navigator.pop(context),
          ),
          TextButton(
            child: Text(
              "ลบบัญชี",
              style: AppTypography.caption3.copyWith(
                color: AppColors.semanticErrorFgHigh,
              ),
            ),
            onPressed: () {
              Navigator.pop(context);
              // TODO: call delete API
            },
          ),
        ],
      ),
    );
  }
}
