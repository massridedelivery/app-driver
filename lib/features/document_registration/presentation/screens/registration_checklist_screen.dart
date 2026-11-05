import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:massdrive/features/referral/presentation/widgets/referral_code_field.dart';
import 'package:massdrive/common/widgets/indicator/mass_loading_m.dart';

import 'package:massdrive/core/theme/brand_colors.dart';
import '../../../../core/constants/app_typography.dart';
import '../../domain/document_reupload.dart';
import '../../domain/models/registration_status.dart';
import '../controllers/registration_controller.dart';
import '../states/registration_state.dart';
import '../widgets/registration_ui.dart';

class RegistrationChecklistScreen extends ConsumerStatefulWidget {
  const RegistrationChecklistScreen({super.key});

  @override
  ConsumerState<RegistrationChecklistScreen> createState() =>
      _RegistrationChecklistScreenState();
}

/// One checklist row: number, title, backend status and where it leads.
typedef _StepSpec = ({
  RegistrationItem item,
  String title,
  String? status,
  String? rejectionReason,
  VoidCallback onTap,
});

class _RegistrationChecklistScreenState
    extends ConsumerState<RegistrationChecklistScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(registrationControllerProvider.notifier).fetchStatus();
    });
  }

  /// Where a document is (re)uploaded: the vehicle and bank steps are forms
  /// that carry their document, the rest is the plain upload screen.
  void _openDocument(BuildContext context, DocumentType type) {
    switch (type) {
      case DocumentType.vehicleRegistration:
        context.push('/document-registration/vehicle-info');
      case DocumentType.bankPassbook:
        context.push('/document-registration/bank-account');
      default:
        context.push(
          '/document-registration/upload-document',
          extra: {'type': type, 'title': _uploadTitle(type)},
        );
    }
  }

  static String _uploadTitle(DocumentType type) =>
      type == DocumentType.insurance ? 'พ.ร.บ. / ประกัน' : documentTitle(type);

  List<_StepSpec> _steps(BuildContext context, RegistrationState state) {
    _StepSpec doc(
      RegistrationItem item,
      DocumentType type,
      String title,
      String routeTitle,
    ) {
      return (
        item: item,
        title: title,
        status: state.remoteDocuments[type]?.status,
        rejectionReason: state.remoteDocuments[type]?.rejectionReason,
        onTap: () => context.push(
          '/document-registration/upload-document',
          extra: {'type': type, 'title': routeTitle},
        ),
      );
    }

    final steps = <RegistrationItem, _StepSpec>{
      RegistrationItem.profile: (
        item: RegistrationItem.profile,
        title: 'ข้อมูลส่วนตัว',
        status: state.isProfileComplete ? 'approved' : null,
        rejectionReason: null,
        onTap: () => context.push('/document-registration/basic-profile'),
      ),
      RegistrationItem.profilePhoto: doc(
        RegistrationItem.profilePhoto,
        DocumentType.profilePhoto,
        'รูปถ่ายโปรไฟล์',
        'รูปถ่ายโปรไฟล์',
      ),
      RegistrationItem.idCard: doc(
        RegistrationItem.idCard,
        DocumentType.idCard,
        'บัตรประชาชน',
        'บัตรประชาชน',
      ),
      // Driving License (Core - always shown)
      RegistrationItem.drivingLicense: doc(
        RegistrationItem.drivingLicense,
        DocumentType.drivingLicense,
        'ใบขับขี่',
        'ใบขับขี่',
      ),
      RegistrationItem.publicDrivingLicense: doc(
        RegistrationItem.publicDrivingLicense,
        DocumentType.publicDrivingLicense,
        'ใบขับขี่สาธารณะ',
        'ใบขับขี่สาธารณะ',
      ),
      RegistrationItem.vehicle: (
        item: RegistrationItem.vehicle,
        title: 'ข้อมูลรถ และ สมุดคู่มือ',
        // Use vehicleRegistration doc status; fall back to 'approved' if
        // profile data filled but no doc yet.
        status:
            state.remoteDocuments[DocumentType.vehicleRegistration]?.status ??
            (state.isVehicleInfoComplete ? 'approved' : null),
        rejectionReason: state
            .remoteDocuments[DocumentType.vehicleRegistration]
            ?.rejectionReason,
        onTap: () => context.push('/document-registration/vehicle-info'),
      ),
      RegistrationItem.vehiclePhoto: doc(
        RegistrationItem.vehiclePhoto,
        DocumentType.vehiclePhoto,
        'รูปถ่ายตัวรถ',
        'รูปถ่ายตัวรถ',
      ),
      RegistrationItem.insurance: doc(
        RegistrationItem.insurance,
        DocumentType.insurance,
        'พ.ร.บ. รถจักรยานยนต์ / ประกัน',
        'พ.ร.บ. / ประกัน',
      ),
      RegistrationItem.bank: (
        item: RegistrationItem.bank,
        title: 'ข้อมูลบัญชีธนาคาร',
        status: state.remoteDocuments[DocumentType.bankPassbook]?.status,
        rejectionReason:
            state.remoteDocuments[DocumentType.bankPassbook]?.rejectionReason,
        onTap: () => context.push('/document-registration/bank-account'),
      ),
    };
    return [
      for (final i in registrationItemsFor(state.selectedTier!)) steps[i]!,
    ];
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(registrationControllerProvider);

    // Only show the approved screen when the backend has confirmed is_verified = true.
    // For all other statuses (inReview, pending, rejected), show the checklist
    // so the driver can see the status of each document.
    // An approved driver can still have documents sent back (the admin asks
    // for a re-upload, the account stays verified): show those, or the push
    // "เอกสารถูกปฏิเสธ" would open a screen with no way to fix them.
    if (state.overallStatus == RegistrationStateStatus.approved) {
      final rejected = rejectedDocuments(state.remoteDocuments.values);
      if (rejected.isEmpty) return const _ApprovedView();
      return _ReuploadView(
        rejected: rejected,
        onOpen: (type) => _openDocument(context, type),
      );
    }

    if (state.selectedTier == null) {
      return const _TierSelectionView();
    }

    final steps = _steps(context, state);
    final completed = steps
        .where((s) => s.status == 'approved' || s.status == 'pending')
        .length;
    final loading = state.isLoading && !state.isProfileComplete;

    return RegistrationScaffold(
      icon: Icons.checklist_rounded,
      title: 'ลงทะเบียนเอกสาร',
      subtitle:
          'กรุณาเตรียมและอัปโหลดเอกสารต่อไปนี้ให้ครบถ้วน สำหรับประเภท: ${state.selectedTier == KycTier.food
              ? "อาหาร"
              : state.selectedTier == KycTier.ride
              ? "รับส่งคน"
              : "ทั้งสองประเภท"}',
      step: completed,
      total: steps.length,
      onBack: () =>
          ref.read(registrationControllerProvider.notifier).setTier(null),
      bottom: loading
          ? null
          : RegistrationPrimaryButton(
              label: 'ดำเนินการต่อ',
              onPressed: state.isAllStepsExceptConsentCompleted
                  ? () => context.push('/document-registration/consent')
                  : null,
            ),
      scrollable: !loading,
      child: loading
          ? const SizedBox.expand(child: Center(child: MassLoadingM(size: 72)))
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var i = 0; i < steps.length; i++)
                  _buildStepItem(context, number: i + 1, spec: steps[i]),
                // Optional: whoever referred this driver. Offered before and
                // after the documents are sent, while the backend allows it.
                const ReferralCodeCard(padding: EdgeInsets.only(top: 16)),
              ],
            ),
    );
  }

  Widget _buildStepItem(
    BuildContext context, {
    required int number,
    required _StepSpec spec,
  }) {
    final status = spec.status;
    var rowStatus = RegistrationRowStatus.todo;
    var lines = const ['ยังไม่ได้ทำ'];
    int? underline;
    bool isInteractive = true;

    if (status == 'approved') {
      rowStatus = RegistrationRowStatus.done;
      lines = const ['ผ่านการอนุมัติแล้ว'];
      isInteractive = false;
    } else if (status == 'pending') {
      rowStatus = RegistrationRowStatus.review;
      lines = const ['อยู่ระหว่างการตรวจสอบ'];
      isInteractive = false;
    } else if (status == 'rejected') {
      rowStatus = RegistrationRowStatus.rejected;
      lines = [
        'ถูกปฏิเสธ: ${spec.rejectionReason ?? "กรุณาแก้ไขข้อมูล"}',
        'แตะเพื่ออัปโหลดใหม่',
      ];
      underline = 1;
      isInteractive = true;
    }

    return RegistrationStatusRow(
      number: number,
      title: spec.title,
      status: rowStatus,
      statusLines: lines,
      underlineLine: underline,
      onTap: isInteractive
          ? spec.onTap
          : () {
              final brand = context.brand;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  duration: const Duration(seconds: 2),
                  content: Text(
                    status == 'approved'
                        ? 'เอกสารนี้ผ่านการอนุมัติแล้ว ไม่สามารถแก้ไขได้'
                        : 'เอกสารอยู่ระหว่างการตรวจสอบ ไม่สามารถแก้ไขได้',
                    style: AppTypography.label2.copyWith(color: brand.bg),
                  ),
                  backgroundColor: brand.text1,
                ),
              );
            },
    );
  }
}

// ignore: unused_element
class _InReviewView extends StatelessWidget {
  const _InReviewView();

  @override
  Widget build(BuildContext context) {
    return RegistrationScaffold(
      icon: Icons.hourglass_top_rounded,
      title: 'ลงทะเบียนเอกสาร',
      onBack: () => context.go('/home'),
      child: const Padding(
        padding: EdgeInsets.only(top: 22),
        child: RegistrationResultContent(
          icon: Icons.hourglass_top_rounded,
          waiting: true,
          title: 'เอกสารของคุณกำลังอยู่ระหว่างการตรวจสอบ',
          body: 'เราจะแจ้งผลให้คุณทราบเร็วๆนี้',
          extra: RegistrationTimeline(),
        ),
      ),
    );
  }
}

/// An approved account with documents sent back: only those rows, each
/// re-uploadable. The driver keeps taking jobs meanwhile.
class _ReuploadView extends StatelessWidget {
  const _ReuploadView({required this.rejected, required this.onOpen});

  final List<RejectedDocument> rejected;
  final void Function(DocumentType type) onOpen;

  @override
  Widget build(BuildContext context) {
    return RegistrationScaffold(
      icon: Icons.upload_file_rounded,
      title: 'อัปโหลดเอกสารใหม่',
      subtitle: 'บัญชีของคุณยังรับงานได้ตามปกติ กรุณาอัปโหลดเอกสารต่อไปนี้ใหม่',
      onBack: () => _goHome(context),
      bottom: RegistrationPrimaryButton(
        label: 'ไปหน้ารับงาน',
        onPressed: () => _goHome(context),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < rejected.length; i++)
            RegistrationStatusRow(
              number: i + 1,
              title: documentTitle(rejected[i].type),
              status: RegistrationRowStatus.rejected,
              statusLines: [
                'ถูกปฏิเสธ: ${rejected[i].reason ?? "กรุณาอัปโหลดใหม่"}',
                'แตะเพื่ออัปโหลดใหม่',
              ],
              underlineLine: 1,
              onTap: () => onOpen(rejected[i].type),
            ),
        ],
      ),
    );
  }
}

/// Back to Home from a checklist that may sit on imperative routes (e.g.
/// opened from Edit Profile or a push), which `context.go` alone won't clear.
void _goHome(BuildContext context) {
  Navigator.of(context, rootNavigator: true).popUntil((route) => route.isFirst);
  context.go('/home');
}

class _ApprovedView extends StatelessWidget {
  const _ApprovedView();

  @override
  Widget build(BuildContext context) {
    return RegistrationScaffold(
      icon: Icons.task_alt_rounded,
      title: 'ลงทะเบียนเอกสาร',
      showBack: false,
      bottom: RegistrationPrimaryButton(
        label: 'ไปหน้ารับงาน',
        onPressed: () {
          // This screen can be reached as an imperative route (e.g.
          // from Edit Profile), which context.go alone won't clear —
          // it would leave this screen covering Home. Pop every
          // imperative route first, then land on Home.
          Navigator.of(
            context,
            rootNavigator: true,
          ).popUntil((route) => route.isFirst);
          context.go('/home');
        },
      ),
      child: const Padding(
        padding: EdgeInsets.only(top: 22),
        child: RegistrationResultContent(
          icon: Icons.task_alt_rounded,
          title: 'เอกสารของคุณผ่านการอนุมัติแล้ว',
          body: 'คุณสามารถเริ่มรับงานได้ทันที',
        ),
      ),
    );
  }
}

class _TierSelectionView extends ConsumerWidget {
  const _TierSelectionView();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(
      registrationControllerProvider.select((s) => s.selectedTier),
    );
    return RegistrationScaffold(
      icon: Icons.route_rounded,
      title: 'เลือกประเภทการขับขี่',
      subtitle: 'ข้อมูลเอกสารที่ต้องใช้จะแตกต่างกันตามประเภทที่คุณเลือก',
      onBack: () {
        if (context.canPop()) {
          context.pop();
        } else {
          context.go('/home');
        }
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildTierCard(
            ref: ref,
            tier: KycTier.food,
            selected: selected,
            title: 'ส่งอาหาร (FOOD)',
            description:
                'ใช้เพียงบัตรประชาชน ใบขับขี่ทั่วไป และรูปเซลฟี่\n(ขับรับส่งอาหารเท่านั้น)',
            icon: Icons.restaurant_rounded,
          ),
          _buildTierCard(
            ref: ref,
            tier: KycTier.ride,
            selected: selected,
            title: 'รับส่งคน (RIDE)',
            description:
                'เพิ่มเอกสารรถ พ.ร.บ. ประกัน และใบขับขี่สาธารณะ\n(ขับรับส่งผู้โดยสารเท่านั้น)',
            icon: Icons.two_wheeler_rounded,
          ),
          _buildTierCard(
            ref: ref,
            tier: KycTier.both,
            selected: selected,
            title: 'ขับทั้งคู่ (BOTH)',
            description: 'เตรียมเอกสารจัดเต็ม รับงานได้ทุกประเภท',
            icon: Icons.star_rounded,
          ),
        ],
      ),
    );
  }

  Widget _buildTierCard({
    required WidgetRef ref,
    required KycTier tier,
    required KycTier? selected,
    required String title,
    required String description,
    required IconData icon,
  }) {
    return RegistrationOptionCard(
      icon: icon,
      title: title,
      subtitle: description,
      badge: '${registrationTotalSteps(tier)} ขั้นตอน',
      selected: selected == tier,
      onTap: () {
        ref.read(registrationControllerProvider.notifier).setTier(tier);
      },
    );
  }
}
