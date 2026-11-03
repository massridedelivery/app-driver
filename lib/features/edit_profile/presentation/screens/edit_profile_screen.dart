import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:massdrive/common/widgets/appbar/base_appbar.dart';
import 'package:massdrive/common/widgets/indicator/mass_loading_m.dart';
import 'package:massdrive/core/constants/app_colors.dart';
import 'package:massdrive/core/theme/app_palette.dart';
import 'package:massdrive/core/constants/app_routes.dart';
import 'package:massdrive/core/constants/app_typography.dart';
import 'package:massdrive/core/utils/toast_util.dart';
import 'package:massdrive/core/navigation/app_navigator.dart';
import 'package:massdrive/features/auth/presentation/controllers/auth_controller.dart';
import 'package:massdrive/features/document_registration/domain/models/driver_profile_info.dart';
import 'package:massdrive/features/document_registration/domain/models/registration_status.dart';
import 'package:massdrive/features/document_registration/domain/models/vehicle_info.dart';
import 'package:massdrive/features/document_registration/presentation/widgets/vehicle_fields.dart';
import 'package:massdrive/core/utils/thai_date.dart';
import 'package:massdrive/features/profile/domain/entities/driver_profile_entity.dart';
import 'package:massdrive/features/profile/presentation/controllers/profile_controller.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  @override
  void initState() {
    super.initState();
    // The profile controller is keepAlive: re-read on open so a photo an
    // admin just approved (a new avatar_url) shows here.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(profileControllerProvider.notifier).fetchProfile(silent: true);
    });
  }

  @override
  Widget build(BuildContext context) {
    final profileState = ref.watch(profileControllerProvider);
    final profile = profileState.profile;

    if (profile == null) {
      return Scaffold(
        appBar: CommonAppBar(titleText: 'โปรไฟล์', showLeftIcon: true),
        backgroundColor: context.palette.bg,
        body: const Center(child: MassLoadingM(size: 72)),
      );
    }

    final profilePhotoUrl = profile.photoUrl;

    return Scaffold(
      appBar: CommonAppBar(titleText: 'โปรไฟล์', showLeftIcon: true),
      backgroundColor: context.palette.bg,
      body: Container(
        color: context.palette.bg,
        child: ListView(
          // Clear the Android edge-to-edge system nav, with breathing room so
          // the last row (ลบบัญชี) doesn't sit flush on the bar.
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            bottom: 24 + MediaQuery.viewPaddingOf(context).bottom,
          ),
          children: [
            const SizedBox(height: 12),

            _SectionHeader(title: "ข้อมูลส่วนตัว"),

            _ProfileImageTile(
              imageUrl: profilePhotoUrl,
              onTap: () async {
                final notifier =
                    ref.read(profileControllerProvider.notifier);
                final oldUrl = profilePhotoUrl;
                // Re-use the existing document-upload flow/API to change the
                // driver's profile photo.
                await context.push(
                  AppRoutes.documentRegistrationUploadNamedPage,
                  extra: {
                    'type': DocumentType.profilePhoto,
                    'title': 'รูปถ่ายโปรไฟล์',
                  },
                );
                // A re-upload often reuses the same URL; NetworkImage caches by
                // URL, so evict it (app-wide cache) before refetching. The
                // refetch then rebuilds every avatar screen with fresh bytes.
                if (oldUrl != null && oldUrl.isNotEmpty) {
                  await NetworkImage(oldUrl).evict();
                }
                await notifier.fetchProfile();
              },
            ),

            // Name and date of birth come from registration Step 1 and are
            // read-only here: the backend rejects changes after approval (409),
            // so edits go through customer support.
            if ((profile.firstName?.isNotEmpty ?? false) ||
                (profile.lastName?.isNotEmpty ?? false)) ...[
              _InfoTile(
                title: "ชื่อ",
                value: profile.firstName ?? '-',
                locked: true,
              ),
              _InfoTile(
                title: "นามสกุล",
                value: profile.lastName ?? '-',
                locked: true,
              ),
            ] else
              _InfoTile(
                title: "ชื่อ - นามสกุล",
                value: profile.fullName,
                locked: true,
              ),
            _InfoTile(
              title: "วันเดือนปีเกิด",
              value: _dobText(profile.dateOfBirth),
              locked: true,
            ),
            Padding(
              padding: const EdgeInsets.only(top: 8, bottom: 4),
              child: Row(
                children: [
                  Icon(Icons.info_outline,
                      size: 14, color: context.palette.textSecondary),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'ติดต่อฝ่ายบริการลูกค้าเพื่อแก้ไข',
                      style: AppTypography.caption4.copyWith(
                        color: context.palette.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            _InfoTile(
              title: "หมายเลขโทรศัพท์มือถือ",
              value: profile.phone != null
                  ? profile.phone!
                  : "ยังไม่ได้กรอกข้อมูล",
              showArrow: true,
              onTap: () {
                _showUpdatePhoneSheet(context, ref, profile.phone ?? "");
              },
            ),

            _InfoTile(
              title: "ที่อยู่อีเมล",
              value: (profile.email?.isNotEmpty ?? false) ? profile.email! : '-',
            ),

            SizedBox(height: 24),

            _SectionHeader(title: "ข้อมูลของยานพาหนะ"),

            Builder(
              builder: (context) {
                final plate = profile.vehiclePlate?.trim() ?? '';
                if (plate.isEmpty) {
                  return _VehicleTile(
                    plate: "ไม่มีข้อมูล",
                    vehicle: "กรุณาเพิ่มยานพาหนะ",
                    hasWarning: true,
                    onTap: () => _showUpdateVehicleSheet(context, ref, null),
                  );
                }
                final saved = VehicleInfo(
                  vehicleType: 'motorcycle',
                  model: profile.vehicleModel ?? '',
                  year: profile.vehicleYear ?? 0,
                  licensePlate: plate,
                  province: profile.vehicleProvince ?? '',
                  color: profile.vehicleColor ?? '',
                );
                final details = [
                  if (saved.model.trim().isNotEmpty) saved.model.trim(),
                  if (saved.color.trim().isNotEmpty) 'สี${saved.color.trim()}',
                ].join(' · ');
                // Province or colour missing (signed up on an older app):
                // flag it so the driver fills them in.
                return _VehicleTile(
                  plate: plateWithProvince(saved.licensePlate, saved.province),
                  vehicle: saved.isComplete
                      ? details
                      : 'กรุณาระบุจังหวัดและสีรถ',
                  isPrimary: saved.isComplete,
                  hasWarning: !saved.isComplete,
                  onTap: () => _showUpdateVehicleSheet(context, ref, saved),
                );
              },
            ),

            const SizedBox(height: 32),

            _SectionHeader(title: "เอกสาร"),

            _InfoTile(
              title: "",
              value: "เลือกเอกสารที่ต้องการอัปเดต",
              showArrow: true,
              onTap: () {
                context.push(AppRoutes.documentRegistrationChecklistNamedPage);
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

  /// The same five fields as the sign-up vehicle step. Sends only what the
  /// driver changed, so an untouched field is never blanked.
  void _showUpdateVehicleSheet(
    BuildContext context,
    WidgetRef ref,
    VehicleInfo? saved,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.palette.sheet,
      builder: (sheetContext) => _VehicleSheet(saved: saved),
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
      backgroundColor: context.palette.sheet,
      builder: (sheetContext) {
        return Padding(
          padding: EdgeInsets.only(
            // Keyboard when it's up, otherwise the Android nav bar —
            // padding.bottom drops to 0 under the keyboard, so they never stack.
            bottom: MediaQuery.viewInsetsOf(sheetContext).bottom +
                MediaQuery.paddingOf(sheetContext).bottom,
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
                style: AppTypography.heading3.copyWith(color: context.palette.textPrimary),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: phoneController,
                style: TextStyle(color: context.palette.textPrimary),
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  labelText: "หมายเลขโทรศัพท์มือถือ",
                  labelStyle: TextStyle(color: context.palette.textSecondary),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: context.palette.border),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.foundationGreen600,
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
                  child: Text(
                    "บันทึก",
                    style: AppTypography.heading5.copyWith(
                      color: Colors.white,
                    ),
                  ),
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
          color: context.palette.textPrimary,
        ),
      ),
    );
  }
}

class _ProfileImageTile extends StatelessWidget {
  final String? imageUrl;
  final VoidCallback? onTap;
  const _ProfileImageTile({this.imageUrl, this.onTap});

  @override
  Widget build(BuildContext context) {
    final hasImage = imageUrl != null && imageUrl!.isNotEmpty;
    return Column(
      children: [
        ListTile(
          contentPadding: EdgeInsets.zero,
          onTap: onTap,
          title: Text(
            "รูปโปรไฟล์",
            style: AppTypography.caption3.copyWith(
              color: context.palette.textPrimary,
            ),
          ),
          subtitle: onTap != null
              ? Text(
                  "แตะเพื่อเปลี่ยนรูปโปรไฟล์",
                  style: AppTypography.caption4.copyWith(
                    color: context.palette.textSecondary,
                  ),
                )
              : null,
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: Colors.grey[800],
                backgroundImage: hasImage ? NetworkImage(imageUrl!) : null,
                child: !hasImage
                    ? Icon(Icons.person, color: context.palette.textSecondary, size: 24)
                    : null,
              ),
              if (onTap != null) ...[
                const SizedBox(width: 4),
                Icon(Icons.chevron_right, color: context.palette.textTertiary),
              ],
            ],
          ),
        ),
        Divider(color: context.palette.border, height: 1),
      ],
    );
  }
}

/// "17 พ.ค. 2533" from the backend's `YYYY-MM-DD`, or "-" when not set.
String _dobText(String? raw) {
  final d = DriverProfileInfo.parseApiDate(raw);
  return d == null ? '-' : formatThaiDate(d);
}

class _InfoTile extends StatelessWidget {
  final String title;
  final String value;
  final bool showArrow;
  final VoidCallback? onTap;

  /// Read-only field: shows a lock instead of an arrow and isn't tappable.
  final bool locked;

  const _InfoTile({
    required this.title,
    required this.value,
    this.showArrow = false,
    this.onTap,
    this.locked = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ListTile(
          contentPadding: EdgeInsets.zero,
          title: title.isNotEmpty
              ? Text(
                  title,
                  style: AppTypography.caption4.copyWith(
                    color: context.palette.textSecondary,
                  ),
                )
              : null,
          subtitle: Text(
            value,
            style: AppTypography.caption3.copyWith(
              color: context.palette.textPrimary,
            ),
          ),
          trailing: locked
              ? Icon(Icons.lock_outline,
                  size: 18, color: context.palette.textTertiary)
              : showArrow
                  ? Icon(Icons.chevron_right,
                      color: context.palette.textTertiary)
                  : null,
          onTap: locked ? null : onTap,
        ),
        Divider(color: context.palette.border, height: 1),
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
              color: context.palette.textPrimary,
            ),
          ),
          subtitle: Text(
            vehicle,
            style: TextStyle(color: context.palette.textSecondary),
          ),
          trailing: hasWarning
              ? const Icon(
                  Icons.error_outline,
                  color: AppColors.semanticErrorFgHigh,
                )
              : isPrimary
              ? const Icon(Icons.check, color: AppColors.semanticSuccessFgHigh)
              : Icon(Icons.chevron_right, color: context.palette.textTertiary),
          onTap: onTap,
        ),
        Divider(color: context.palette.border, height: 1),
      ],
    );
  }
}

class _DeleteAccountTile extends ConsumerWidget {
  const _DeleteAccountTile();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
              color: context.palette.textPrimary,
            ),
          ),
          trailing: Icon(Icons.chevron_right, color: context.palette.textTertiary),
          onTap: () => _showDeleteDialog(context, ref),
        ),
        Divider(color: context.palette.border, height: 1),
      ],
    );
  }

  void _showDeleteDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: context.palette.surface,
        title: Text(
          "ยืนยันการลบบัญชี",
          style: AppTypography.caption3.copyWith(
            color: context.palette.textPrimary,
          ),
        ),
        content: Text(
          "คุณแน่ใจหรือไม่ว่าต้องการลบบัญชี?\nการดำเนินการนี้ไม่สามารถย้อนกลับได้",
          style: AppTypography.caption4.copyWith(
            color: context.palette.textSecondary,
          ),
        ),
        actions: [
          TextButton(
            child: Text(
              "ยกเลิก",
              style: AppTypography.caption3.copyWith(
                color: context.palette.textSecondary,
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
              Navigator.pop(context); // close the confirm dialog
              _performDelete(context, ref);
            },
          ),
        ],
      ),
    );
  }

  /// Deletes the account server-side then returns to login. Shows a blocking
  /// loader during the call; on failure the error is surfaced (never silent)
  /// and the driver stays signed in.
  Future<void> _performDelete(BuildContext context, WidgetRef ref) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: MassLoadingM(size: 56)),
    );
    try {
      await ref.read(authControllerProvider.notifier).deleteAccount();
      if (!context.mounted) return;
      // Clear every imperative route (this screen sits on top of the go_router
      // stack), then land on login — same teardown as logout.
      Navigator.of(context, rootNavigator: true)
          .popUntil((route) => route.isFirst);
      AppNavigator.go(context, AppRoutes.loginNamedPage);
    } catch (e) {
      if (!context.mounted) return;
      Navigator.of(context, rootNavigator: true).pop(); // dismiss the loader
      ToastUtil.showErrorToast(
        'ลบบัญชีไม่สำเร็จ: ${e.toString().replaceFirst('Exception: ', '')}',
      );
    }
  }
}

class _VehicleSheet extends ConsumerStatefulWidget {
  const _VehicleSheet({required this.saved});

  final VehicleInfo? saved;

  @override
  ConsumerState<_VehicleSheet> createState() => _VehicleSheetState();
}

class _VehicleSheetState extends ConsumerState<_VehicleSheet> {
  final _formKey = GlobalKey<FormState>();
  late final _fields = VehicleFieldsController(initial: widget.saved);

  @override
  void dispose() {
    _fields.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final changes = _fields.value.changesFrom(widget.saved);
    Navigator.pop(context);
    if (changes.isEmpty) return;
    final success = await ref
        .read(profileControllerProvider.notifier)
        .updateProfile(changes);
    if (success) {
      ToastUtil.showSuccessToast("อัปเดตข้อมูลสำเร็จ");
    } else {
      ToastUtil.showErrorToast("ไม่สามารถอัปเดตข้อมูลได้");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        // Keyboard when it's up, otherwise the Android nav bar —
        // padding.bottom drops to 0 under the keyboard, so they never stack.
        bottom: MediaQuery.viewInsetsOf(context).bottom +
            MediaQuery.paddingOf(context).bottom,
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.85,
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  "อัปเดตข้อมูลยานพาหนะ",
                  style: AppTypography.heading3.copyWith(
                    color: context.palette.textPrimary,
                  ),
                ),
                const SizedBox(height: 16),
                VehicleFields(controller: _fields),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    key: const Key('vehicle-save'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.foundationGreen600,
                    ),
                    onPressed: _save,
                    child: Text(
                      "บันทึก",
                      style: AppTypography.heading5.copyWith(
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
