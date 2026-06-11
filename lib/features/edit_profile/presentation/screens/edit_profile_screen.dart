import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:massdrive/common/widgets/appbar/base_appbar.dart';
import 'package:massdrive/core/constants/app_colors.dart';
import 'package:massdrive/core/constants/app_typography.dart';
import 'package:massdrive/core/utils/toast_util.dart';
import 'package:massdrive/core/utils/string_util.dart';
import 'package:massdrive/core/navigation/app_navigator.dart';
import 'package:massdrive/features/profile/presentation/controllers/profile_controller.dart';
import 'package:massdrive/features/document_registration/presentation/screens/registration_checklist_screen.dart';

class EditProfileScreen extends ConsumerWidget {
  const EditProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileState = ref.watch(profileControllerProvider);
    final profile = profileState.profile;

    if (profile == null) {
      return Scaffold(
        appBar: CommonAppBar(titleText: 'โปรไฟล์', showLeftIcon: true),
        backgroundColor: const Color(0xFF0F0F0F),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    String? profilePhotoUrl;
    for (final doc in profile.documents) {
      if (doc.type == 'profile_photo' || doc.type == 'profilePhoto') {
        profilePhotoUrl = doc.mediaUrl;
        break;
      }
    }

    return Scaffold(
      appBar: CommonAppBar(titleText: 'โปรไฟล์', showLeftIcon: true),
      backgroundColor: const Color(0xFF0F0F0F),
      body: Container(
        color: AppColors.semanticGrayNeutralFgHigh,
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          children: [
            const SizedBox(height: 12),

            _SectionHeader(title: "ข้อมูลส่วนตัว"),

            _ProfileImageTile(imageUrl: profilePhotoUrl),

            _InfoTile(
              title: "ชื่อ",
              value: profile.fullName.blindName(),
              showArrow: true,
              onTap: () {
                _showUpdateNameSheet(context, ref, profile.fullName);
              },
            ),

            _InfoTile(
              title: "หมายเลขโทรศัพท์มือถือ",
              value: profile.phone != null
                  ? profile.phone!.blindPhone()
                  : "ยังไม่ได้กรอกข้อมูล",
              showArrow: true,
              onTap: () {
                _showUpdatePhoneSheet(context, ref, profile.phone ?? "");
              },
            ),

            _InfoTile(
              title: "ที่อยู่อีเมล",
              value: profile.userId.blindEmailOrUuid(),
            ),

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

            if (profile.vehiclePlate != null && profile.vehicleModel != null)
              _VehicleTile(
                plate: profile.vehiclePlate!.blindPlate(),
                vehicle: profile.vehicleModel!,
                isPrimary: true,
                onTap: () {
                  _showUpdateVehicleSheet(
                    context,
                    ref,
                    profile.vehiclePlate!,
                    profile.vehicleModel!,
                  );
                },
              )
            else
              _VehicleTile(
                plate: "ไม่มีข้อมูล",
                vehicle: "กรุณาเพิ่มยานพาหนะ",
                hasWarning: true,
                onTap: () {
                  _showUpdateVehicleSheet(context, ref, "", "");
                },
              ),

            const SizedBox(height: 32),

            _SectionHeader(title: "เอกสาร"),

            _InfoTile(
              title: "",
              value: "เลือกเอกสารที่ต้องการอัปเดต",
              showArrow: true,
              onTap: () {
                AppNavigator.push(context, const RegistrationChecklistScreen());
              },
            ),

            const SizedBox(height: 24),

            _SectionHeader(title: "จัดการบัญชีของคุณ"),

            _DeleteAccountTile(),
          ],
        ),
      ),
    );
  }

  void _showUpdateVehicleSheet(
    BuildContext context,
    WidgetRef ref,
    String currentPlate,
    String currentModel,
  ) {
    final plateController = TextEditingController(text: currentPlate);
    final modelController = TextEditingController(text: currentModel);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1E2F38),
      builder: (_) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 24,
            right: 24,
            top: 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "อัปเดตข้อมูลยานพาหนะ",
                style: AppTypography.heading3.copyWith(color: Colors.white),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: plateController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: "ป้ายทะเบียน",
                  labelStyle: TextStyle(color: Colors.white70),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.white24),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: modelController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: "รุ่น/ยี่ห้อ (เช่น HONDA CLICK)",
                  labelStyle: TextStyle(color: Colors.white70),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.white24),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.foundationOrange600,
                  ),
                  onPressed: () async {
                    Navigator.pop(context);
                    final success = await ref
                        .read(profileControllerProvider.notifier)
                        .updateProfile({
                          "vehicle_plate": plateController.text,
                          "vehicle_model": modelController.text,
                        });
                    if (success) {
                      ToastUtil.showSuccessToast("อัปเดตข้อมูลสำเร็จ");
                    } else {
                      ToastUtil.showErrorToast("ไม่สามารถอัปเดตข้อมูลได้");
                    }
                  },
                  child: const Text("บันทึก"),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }

  void _showUpdateNameSheet(
    BuildContext context,
    WidgetRef ref,
    String currentName,
  ) {
    final nameController = TextEditingController(text: currentName);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1E2F38),
      builder: (_) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 24,
            right: 24,
            top: 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "อัปเดตชื่อ",
                style: AppTypography.heading3.copyWith(color: Colors.white),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: nameController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: "ชื่อ - นามสกุล",
                  labelStyle: TextStyle(color: Colors.white70),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.white24),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.foundationOrange600,
                  ),
                  onPressed: () async {
                    Navigator.pop(context);
                    final success = await ref
                        .read(profileControllerProvider.notifier)
                        .updateProfile({
                      "full_name": nameController.text,
                    });
                    if (success) {
                      ToastUtil.showSuccessToast("อัปเดตข้อมูลสำเร็จ");
                    } else {
                      ToastUtil.showErrorToast("ไม่สามารถอัปเดตข้อมูลได้");
                    }
                  },
                  child: const Text("บันทึก"),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }

  void _showUpdatePhoneSheet(
    BuildContext context,
    WidgetRef ref,
    String currentPhone,
  ) {
    final phoneController = TextEditingController(text: currentPhone);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1E2F38),
      builder: (_) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 24,
            right: 24,
            top: 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "อัปเดตหมายเลขโทรศัพท์มือถือ",
                style: AppTypography.heading3.copyWith(color: Colors.white),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: phoneController,
                style: const TextStyle(color: Colors.white),
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: "หมายเลขโทรศัพท์มือถือ",
                  labelStyle: TextStyle(color: Colors.white70),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.white24),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.foundationOrange600,
                  ),
                  onPressed: () async {
                    Navigator.pop(context);
                    final success = await ref
                        .read(profileControllerProvider.notifier)
                        .updateProfile({
                      "phone": phoneController.text,
                    });
                    if (success) {
                      ToastUtil.showSuccessToast("อัปเดตข้อมูลสำเร็จ");
                    } else {
                      ToastUtil.showErrorToast("ไม่สามารถอัปเดตข้อมูลได้");
                    }
                  },
                  child: const Text("บันทึก"),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
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
  final String? imageUrl;
  const _ProfileImageTile({this.imageUrl});

  @override
  Widget build(BuildContext context) {
    final hasImage = imageUrl != null && imageUrl!.isNotEmpty;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(
        "รูปโปรไฟล์",
        style: AppTypography.caption3.copyWith(
          color: AppColors.semanticGrayNeutralBgWhite,
        ),
      ),
      trailing: CircleAvatar(
        radius: 24,
        backgroundColor: Colors.grey[800],
        backgroundImage: hasImage ? NetworkImage(imageUrl!) : null,
        child: !hasImage
            ? const Icon(
                Icons.person,
                color: Colors.white70,
                size: 24,
              )
            : null,
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final String title;
  final String value;
  final bool showArrow;
  final IconData? leadingIcon;
  final VoidCallback? onTap;

  const _InfoTile({
    required this.title,
    required this.value,
    this.showArrow = false,
    this.leadingIcon,
    this.onTap,
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
          onTap: onTap,
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
  final VoidCallback? onTap;

  const _VehicleTile({
    required this.plate,
    required this.vehicle,
    this.isPrimary = false,
    this.hasWarning = false,
    this.onTap,
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
          onTap: onTap,
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
