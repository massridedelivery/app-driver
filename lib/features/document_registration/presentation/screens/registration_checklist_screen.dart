import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:massdrive/features/referral/presentation/widgets/referral_code_field.dart';
import 'package:massdrive/common/widgets/indicator/mass_loading_m.dart';

import 'package:massdrive/core/theme/brand_colors.dart';
import '../../../../core/constants/app_typography.dart';
import 'package:massdrive/core/utils/thai_date.dart';
import 'package:massdrive/features/profile/domain/profile_updates.dart';
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
  AppLifecycleListener? _lifecycle;

  /// Documents the re-upload view has shown since this screen opened.
  final Set<DocumentType> _tracked = {};
  bool _left = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _refresh());
    // Read again when the driver comes back to the app, and when a review
    // lands (`document_status` push → ProfileUpdates).
    _lifecycle = AppLifecycleListener(onResume: _refresh);
    ProfileUpdates.instance.addListener(_refresh);
  }

  @override
  void dispose() {
    ProfileUpdates.instance.removeListener(_refresh);
    _lifecycle?.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    if (!mounted) return;
    await ref.read(registrationControllerProvider.notifier).fetchStatus();
  }

  void _onState(RegistrationState? prev, RegistrationState next) {
    if (next.overallStatus != RegistrationStateStatus.approved) return;
    _tracked.addAll(openReuploads(next.remoteDocuments).map((d) => d.type));
    _maybeLeave();
  }

  /// Every document sent back has been approved: say so and go home.
  void _maybeLeave() {
    if (_left || _tracked.isEmpty || !mounted) return;
    final state = ref.read(registrationControllerProvider);
    if (state.overallStatus != RegistrationStateStatus.approved ||
        openReuploads(state.remoteDocuments).isNotEmpty) {
      return;
    }
    _left = true;
    final messenger = ScaffoldMessenger.of(context);
    final brand = context.brand;
    _goHome(context);
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          'เอกสารครบแล้ว',
          style: AppTypography.label2.copyWith(color: brand.bg),
        ),
        backgroundColor: brand.text1,
      ),
    );
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
    ref.listen(registrationControllerProvider, _onState);

    // Only show the approved screen when the backend has confirmed is_verified = true.
    // For all other statuses (inReview, pending, rejected), show the checklist
    // so the driver can see the status of each document.
    // An approved driver can still have documents sent back (the admin asks
    // for a re-upload, the account stays verified): show those, or the push
    // "เอกสารถูกปฏิเสธ" would open a screen with no way to fix them.
    // Sent back documents stay on this screen until they are approved:
    // rejected (tap to upload again), then "รอตรวจสอบ" once sent.
    if (state.overallStatus == RegistrationStateStatus.approved) {
      // Approved documents are not shown: only rejected and pending ones.
      final rows = openReuploads(state.remoteDocuments);
      if (rows.isEmpty) {
        return _ApprovedView(
          approved: [
            for (final type in approvedDocuments(state.remoteDocuments))
              (type: type, expiry: state.remoteDocuments[type]?.expiryDay),
          ],
        );
      }
      return _ReuploadView(
        rows: rows,
        onOpen: (type) => _openDocument(context, type),
        onRefresh: _refresh,
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
      onRefresh: _refresh,
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

/// An approved account with documents sent back: only those rows. A rejected
/// one is re-uploaded from here; once sent it waits as "รอตรวจสอบ" until it is
/// reviewed (approved → gone, rejected → red again). The driver keeps taking
/// jobs meanwhile.
class _ReuploadView extends StatelessWidget {
  const _ReuploadView({
    required this.rows,
    required this.onOpen,
    required this.onRefresh,
  });

  final List<ReuploadItem> rows;
  final void Function(DocumentType type) onOpen;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    bool any(ReuploadState s) => rows.any((r) => r.state == s);
    return RegistrationScaffold(
      icon: Icons.upload_file_rounded,
      title: 'อัปโหลดเอกสารใหม่',
      // The account keeps working whatever is listed here.
      subtitle: any(ReuploadState.rejected)
          ? 'บัญชีของคุณยังรับงานได้ตามปกติ กรุณาอัปโหลดเอกสารต่อไปนี้ใหม่'
          : any(ReuploadState.expiring)
          ? 'เอกสารใกล้หมดอายุ อัปโหลดฉบับใหม่ได้เลย บัญชีของคุณยังรับงานได้ตามปกติ'
          : 'ส่งเอกสารแล้ว รอเจ้าหน้าที่ตรวจสอบ บัญชีของคุณยังรับงานได้ตามปกติ',
      onBack: () => _goHome(context),
      onRefresh: onRefresh,
      bottom: RegistrationPrimaryButton(
        label: 'ไปหน้ารับงาน',
        onPressed: () => _goHome(context),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < rows.length; i++) _row(context, i + 1, rows[i]),
        ],
      ),
    );
  }

  Widget _row(BuildContext context, int number, ReuploadItem item) {
    final title = documentTitle(item.type);
    return switch (item.state) {
      ReuploadState.rejected => RegistrationStatusRow(
        number: number,
        title: title,
        status: RegistrationRowStatus.rejected,
        statusLines: [rejectedLine(item), 'แตะเพื่ออัปโหลดใหม่'],
        underlineLine: 1,
        onTap: () => onOpen(item.type),
      ),
      ReuploadState.pending => RegistrationStatusRow(
        number: number,
        title: title,
        status: RegistrationRowStatus.todo,
        statusLines: const ['รอตรวจสอบ'],
        onTap: () => _toast(context, 'ส่งแล้ว รอเจ้าหน้าที่ตรวจ'),
      ),
      // Uploading early is fine: the new copy replaces this one once approved.
      ReuploadState.expiring => RegistrationStatusRow(
        number: number,
        title: title,
        status: RegistrationRowStatus.review,
        statusLines: [expiringLine(item)],
        onTap: () => onOpen(item.type),
      ),
      // Never listed: openReuploads drops approved documents.
      ReuploadState.approved => const SizedBox.shrink(),
    };
  }

  static void _toast(BuildContext context, String message) {
    final brand = context.brand;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          duration: const Duration(seconds: 2),
          content: Text(
            message,
            style: AppTypography.label2.copyWith(color: brand.bg),
          ),
          backgroundColor: brand.text1,
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

/// Every document approved: what passed, and the way to the jobs.
class _ApprovedView extends StatelessWidget {
  const _ApprovedView({required this.approved});

  /// The approved documents, in checklist order.
  final List<({DocumentType type, DateTime? expiry})> approved;

  @override
  Widget build(BuildContext context) {
    final brand = context.brand;
    return RegistrationScaffold(
      icon: Icons.fact_check_rounded,
      title: 'เอกสารของคุณ',
      showBack: false,
      bottom: RegistrationPrimaryButton(
        label: 'ไปหน้ารับงาน',
        // Reached as an imperative route too (Edit Profile, a push): pop
        // those first, then land on Home.
        onPressed: () => _goHome(context),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(Icons.check_circle_rounded, size: 32, color: brand.ok),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ผ่านการอนุมัติครบแล้ว',
                      style: AppTypography.heading5.copyWith(
                        color: brand.text1,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'คุณสามารถเริ่มรับงานได้ทันที',
                      style: AppTypography.body2.copyWith(color: brand.text2),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (approved.isNotEmpty) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: brand.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: brand.line),
              ),
              child: Column(
                children: [
                  for (final (:type, :expiry) in approved)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 9),
                      child: Row(
                        children: [
                          Icon(Icons.check_rounded, size: 20, color: brand.ok),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              documentTitle(type),
                              style: AppTypography.body2.copyWith(
                                color: brand.text1,
                              ),
                            ),
                          ),
                          if (expiry != null)
                            Text(
                              'หมดอายุ ${formatThaiDate(expiry)}',
                              style: AppTypography.caption4.copyWith(
                                color: brand.text2,
                              ),
                            ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ],
        ],
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
