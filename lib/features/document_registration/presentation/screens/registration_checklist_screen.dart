import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:massdrive/common/widgets/indicator/mass_loading_m.dart';

import 'package:massdrive/core/theme/brand_colors.dart';
import '../../../../core/constants/app_typography.dart';
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
    if (state.overallStatus == RegistrationStateStatus.approved) {
      return const _ApprovedView();
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
