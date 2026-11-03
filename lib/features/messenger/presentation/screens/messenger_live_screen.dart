import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:massdrive/common/widgets/indicator/mass_loading_m.dart';
import 'package:massdrive/common/widgets/slide_to_confirm.dart';
import 'package:massdrive/core/constants/app_colors.dart';
import 'package:massdrive/core/constants/app_typography.dart';
import 'package:massdrive/core/theme/app_palette.dart';
import 'package:massdrive/core/utils/map_marker_providers.dart';
import 'package:massdrive/core/navigation/app_navigator.dart';
import 'package:massdrive/features/call/domain/call_kind.dart';
import 'package:massdrive/features/call/presentation/widgets/call_customer_button.dart';
import 'package:massdrive/features/chat/domain/entities/chat_vertical.dart';
import 'package:massdrive/features/chat/presentation/screens/chat_screen.dart';
import 'package:massdrive/features/job_live/presentation/widgets/ride_flow_widgets.dart';
import 'package:massdrive/features/messenger/domain/models/messenger_order.dart';
import 'package:massdrive/features/messenger/domain/parcel_payment_label.dart';
import 'package:massdrive/features/messenger/domain/models/messenger_status.dart';
import 'package:massdrive/features/messenger/presentation/controllers/messenger_controller.dart';
import 'package:massdrive/features/support/presentation/widgets/support_actions.dart';
import 'package:massdrive/core/utils/baht.dart';

/// Active messenger delivery — advances arrived → picked-up → delivered via the
/// per-vertical REST actions (SCRUM-41 §7).
class MessengerLiveScreen extends ConsumerWidget {
  const MessengerLiveScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Surface action failures (e.g. a rejected "ส่งสำเร็จ"/delivered call) instead
    // of swallowing them — otherwise the button just appears to "do nothing".
    ref.listen(
      messengerControllerProvider.select((s) => s.errorMessage),
      (prev, next) {
        if (next.isNotEmpty && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(next),
              backgroundColor: AppColors.semanticErrorBgHigh,
            ),
          );
        }
      },
    );

    final state = ref.watch(messengerControllerProvider);
    final order = state.activeOrder;

    if (order == null) {
      return const Scaffold(
        backgroundColor: AppColors.semanticGrayNeutralFgWhite,
        body: Center(child: MassLoadingM(size: 72)),
      );
    }

    // Before pickup the driver heads to the pickup point; after, to dropoff.
    final headingToDropoff = order.statusEnum == MessengerStatus.pickedUp;
    final target = headingToDropoff
        ? LatLng(order.dropoffLat, order.dropoffLng)
        : LatLng(order.pickupLat, order.pickupLng);

    return Scaffold(
      backgroundColor: AppColors.semanticGrayNeutralFgWhite,
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(target: target, zoom: 16),
            markers: {
              Marker(
                markerId: MarkerId(headingToDropoff ? 'dropoff' : 'pickup'),
                position: target,
                // Same custom pins as the ride flow: green = pickup,
                // red = dropoff (fall back to hue until the bitmap is ready).
                icon:
                    (headingToDropoff
                        ? ref.watch(dropoffMarkerProvider).value
                        : ref.watch(pickupMarkerProvider).value) ??
                    BitmapDescriptor.defaultMarkerWithHue(
                      headingToDropoff
                          ? BitmapDescriptor.hueRed
                          : BitmapDescriptor.hueGreen,
                    ),
              ),
            },
            myLocationEnabled: true,
            zoomControlsEnabled: false,
            myLocationButtonEnabled: false,
          ),
          // The ride's green bar on top: the step, where to, นำทาง.
          Positioned(
            top: MediaQuery.paddingOf(context).top + 8,
            left: 12,
            right: 12,
            child: RideNavBanner(
              step: switch (order.statusEnum) {
                MessengerStatus.arrivedAtPickup => '1 · ถึงจุดรับแล้ว',
                MessengerStatus.pickedUp => '2 · ไปส่งพัสดุ',
                _ => '1 · ไปรับพัสดุ',
              },
              address:
                  (headingToDropoff
                      ? order.dropoffAddress
                      : order.pickupAddress) ??
                  '-',
              headline: order.statusEnum == MessengerStatus.arrivedAtPickup
                  ? 'รอรับพัสดุ'
                  : '',
              onNavigate: () => _openNavigation(context, target),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: MessengerLiveSheet(
              order: order,
              isSubmitting: state.isSubmitting,
            ),
          ),
        ],
      ),
    );
  }

  /// Opens Google Maps turn-by-turn navigation to [dest] (Android navigation
  /// scheme, with a universal web fallback for iOS).
  Future<void> _openNavigation(BuildContext context, LatLng dest) async {
    final navUri = Uri.parse(
        'google.navigation:q=${dest.latitude},${dest.longitude}&mode=d');
    final fallbackUri = Uri.parse(
        'https://www.google.com/maps/dir/?api=1&destination=${dest.latitude},${dest.longitude}&travelmode=driving');
    try {
      if (await canLaunchUrl(navUri)) {
        await launchUrl(navUri, mode: LaunchMode.externalApplication);
      } else {
        await launchUrl(fallbackUri, mode: LaunchMode.externalApplication);
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('ไม่สามารถเปิดแอปนำทางได้')),
        );
      }
    }
  }
}

/// The ride's live card (JobLiveScreen) for a parcel: the stop being driven
/// to with the fee pill, the other stop, the contact row, how the fee is
/// paid, and the step's slide.
class MessengerLiveSheet extends ConsumerWidget {
  final MessengerOrder order;
  final bool isSubmitting;

  const MessengerLiveSheet({
    super.key,
    required this.order,
    required this.isSubmitting,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(messengerControllerProvider.notifier);
    final p = context.palette;
    final card = RideCardColors.of(context);
    final status = order.statusEnum;
    final toDropoff = status == MessengerStatus.pickedUp;
    final (label, slide, color, action) = _stage(status, controller);
    final pickup = order.pickupAddress ?? '-';
    final dropoff = order.dropoffAddress ?? '-';
    final size = order.packageSizeTier.isEmpty
        ? 'พัสดุ'
        : 'พัสดุขนาด ${order.packageSizeTier}';

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: card.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 16)],
      ),
      // Reserve the system nav-bar inset so the slide clears the Android
      // 3-button bar (viewPadding.bottom).
      padding: EdgeInsets.fromLTRB(
        16,
        8,
        16,
        16 + MediaQuery.viewPaddingOf(context).bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: p.border,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          const SizedBox(height: 10),
          RideNextStopCard(
            label: label,
            amount: order.fare,
            address: toDropoff ? dropoff : pickup,
            toDropoff: toDropoff,
            facts: '$size · ${order.packageWeightKg.toStringAsFixed(0)} กก.',
          ),
          const SizedBox(height: 8),
          RideThenLine(
            text: toDropoff ? 'รับพัสดุแล้ว · $pickup' : 'จากนั้นส่งที่ $dropoff',
            toDropoff: toDropoff,
          ),
          const SizedBox(height: 10),
          _contactRow(context),
          const SizedBox(height: 10),
          Row(
            children: [
              RideTag(text: _feeLine(order)),
              if (order.isCod && order.codAmount > 0) ...[
                const SizedBox(width: 6),
                RideTag(text: 'COD ${formatBaht(order.codAmount)}'),
              ],
            ],
          ),
          const SizedBox(height: 12),
          // "แสดง QR รับเงิน" — rider presents the PromptPay QR to the sender (at
          // pickup) or recipient (at drop-off) when the fee is QR and unpaid.
          if (_showQrButton(order)) ...[
            SizedBox(
              height: 52,
              child: OutlinedButton.icon(
                onPressed: isSubmitting ? null : () => controller.collectFeeQr(),
                icon: Icon(Icons.qr_code_2, color: p.textPrimary),
                label: Text(
                  'แสดง QR รับเงิน (${formatBaht(order.feeDue)})',
                  style: AppTypography.caption3.copyWith(
                    color: p.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: card.line),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(28),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
          ],
          SlideToConfirm(
            key: ValueKey(status),
            label: slide,
            color: color,
            enabled: action != null,
            loading: isSubmitting,
            onConfirmed: action ?? () {},
          ),
        ],
      ),
    );
  }

  /// The person on this order + แชท / โทรฟรี / ช่วยเหลือ (นำทาง is in the
  /// top bar, as on a ride).
  Widget _contactRow(BuildContext context) {
    final p = context.palette;
    final name = (order.recipientName ?? '').isEmpty
        ? 'ผู้รับพัสดุ'
        : order.recipientName!;
    return Container(
      padding: const EdgeInsets.only(top: 10),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: RideCardColors.of(context).line)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: RideCardColors.of(context).chip,
            child: Icon(Icons.person, color: p.textSecondary),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.caption3.copyWith(
                    color: p.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  'ผู้รับพัสดุ',
                  style: AppTypography.caption5.copyWith(
                    color: p.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          // Chat is available once ACCEPTED — there is a counterparty.
          RideIconButton(
            icon: Icons.chat_bubble_outline,
            tooltip: 'แชท',
            onTap: () => AppNavigator.push(
              context,
              ChatScreen(
                jobId: order.id,
                passengerName: order.recipientName ?? 'ลูกค้า',
                vertical: ChatVertical.messenger,
              ),
            ),
          ),
          const SizedBox(width: 8),
          // No customer name: the customer is the sender, not the recipient
          // this card shows — the call brings their name.
          CallCustomerButton(
            kind: CallKind.messenger,
            jobId: order.id,
            status: order.status,
            finishedAt: order.deliveredAt,
            builder: (context, onCall) => Padding(
              padding: const EdgeInsets.only(right: 8),
              child: RideIconButton(
                icon: Icons.phone_outlined,
                tooltip: 'โทรฟรี',
                onTap: onCall,
              ),
            ),
          ),
          RideIconButton(
            icon: Icons.help_outline,
            tooltip: 'ช่วยเหลือ',
            onTap: () => showHelpSheet(
              context,
              customer: HelpSheetCall(
                kind: CallKind.messenger,
                jobId: order.id,
                status: order.status,
                finishedAt: order.deliveredAt,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// "QR พร้อมเพย์ · ผู้รับจ่าย", or "ค่าส่งจ่ายแล้ว" once it's settled.
  static String _feeLine(MessengerOrder order) => order.isFeePaid
      ? 'ค่าส่งจ่ายแล้ว'
      : 'ค่าส่ง ${parcelPaymentLabel(order.paymentMethod, recipientPays: order.isRecipientPays)}';

  /// (card label, slide label, slide colour, action) for the current status —
  /// the ride's steps: orange to the pickup, green after.
  (String, String, Color, VoidCallback?) _stage(
    MessengerStatus status,
    MessengerController controller,
  ) {
    switch (status) {
      case MessengerStatus.accepted:
        return (
          'กำลังไป · จุดรับพัสดุ',
          'เลื่อนเมื่อถึงจุดรับ',
          AppColors.foundationOrange700,
          controller.arrived,
        );
      case MessengerStatus.arrivedAtPickup:
        return (
          'ถึงจุดรับแล้ว · รอรับพัสดุ',
          'เลื่อนเมื่อรับพัสดุแล้ว',
          AppColors.foundationMint600,
          controller.pickedUp,
        );
      case MessengerStatus.pickedUp:
        return (
          'กำลังไป · จุดส่งพัสดุ',
          'เลื่อนเมื่อส่งพัสดุแล้ว',
          AppColors.foundationMint600,
          controller.delivered,
        );
      default:
        return (
          'กำลังดำเนินการ',
          'รอสักครู่',
          AppColors.foundationMint600,
          null,
        );
    }
  }

  /// Show the "แสดง QR รับเงิน" button only for an unpaid PromptPay fee, at the
  /// stage where the driver is with the payer: SENDER at pickup
  /// (ARRIVED/PICKED_UP), RECIPIENT at drop-off (PICKED_UP, before delivered).
  bool _showQrButton(MessengerOrder order) {
    if (order.paymentMethod.toUpperCase() != 'PROMPTPAY' || order.isFeePaid) {
      return false;
    }
    final s = order.statusEnum;
    return order.isRecipientPays
        ? s == MessengerStatus.pickedUp
        : (s == MessengerStatus.arrivedAtPickup ||
            s == MessengerStatus.pickedUp);
  }
}
