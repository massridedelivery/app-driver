import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:massdrive/core/constants/app_colors.dart';
import 'package:massdrive/core/constants/app_typography.dart';
import 'package:massdrive/core/navigation/app_navigator.dart';
import 'package:massdrive/features/chat/domain/entities/chat_vertical.dart';
import 'package:massdrive/features/chat/presentation/screens/chat_screen.dart';
import 'package:massdrive/features/messenger/domain/models/messenger_order.dart';
import 'package:massdrive/features/messenger/domain/models/messenger_status.dart';
import 'package:massdrive/features/messenger/presentation/controllers/messenger_controller.dart';

/// Active messenger delivery — advances arrived → picked-up → delivered via the
/// per-vertical REST actions (SCRUM-41 §7).
class MessengerLiveScreen extends ConsumerWidget {
  const MessengerLiveScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(messengerControllerProvider);
    final order = state.activeOrder;

    if (order == null) {
      return const Scaffold(
        backgroundColor: AppColors.semanticGrayNeutralFgWhite,
        body: Center(child: CircularProgressIndicator()),
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
                icon: BitmapDescriptor.defaultMarkerWithHue(
                  headingToDropoff
                      ? BitmapDescriptor.hueRed
                      : BitmapDescriptor.hueOrange,
                ),
              ),
            },
            myLocationEnabled: true,
            zoomControlsEnabled: false,
            myLocationButtonEnabled: false,
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: _LiveSheet(order: order, isSubmitting: state.isSubmitting),
          ),
        ],
      ),
    );
  }
}

class _LiveSheet extends ConsumerWidget {
  final MessengerOrder order;
  final bool isSubmitting;

  const _LiveSheet({required this.order, required this.isSubmitting});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(messengerControllerProvider.notifier);
    final (headerText, buttonText, action) = _stage(order.statusEnum, controller);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
      decoration: const BoxDecoration(
        color: AppColors.semanticGrayNeutralFgMidOnBlack,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            headerText,
            style: AppTypography.heading4
                .copyWith(color: AppColors.semanticSuccessBgHigh),
          ),
          const SizedBox(height: 4),
          Text(
            'พัสดุขนาด ${order.packageSizeTier} · ${order.packageWeightKg.toStringAsFixed(0)} กก.',
            style: AppTypography.body2.copyWith(color: Colors.white70),
          ),
          const SizedBox(height: 16),
          if ((order.recipientName ?? '').isNotEmpty)
            Text(order.recipientName!,
                style: AppTypography.heading5.copyWith(color: Colors.white)),
          Text(
            order.statusEnum == MessengerStatus.pickedUp
                ? (order.dropoffAddress ?? '-')
                : (order.pickupAddress ?? '-'),
            style: AppTypography.caption3.copyWith(color: Colors.white70),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Text('฿${order.fare.toStringAsFixed(0)}',
                  style: AppTypography.heading3.copyWith(color: Colors.white)),
              const SizedBox(width: 12),
              Text(order.isCod ? 'COD ฿${order.codAmount.toInt()}' : 'เงินสด',
                  style: AppTypography.heading6.copyWith(color: Colors.white70)),
              const Spacer(),
              // Chat is available once ACCEPTED — there is a counterparty.
              IconButton(
                onPressed: () => AppNavigator.push(
                  context,
                  ChatScreen(
                    jobId: order.id,
                    passengerName: order.recipientName ?? 'ลูกค้า',
                    vertical: ChatVertical.messenger,
                  ),
                ),
                icon: const Icon(Icons.chat_bubble_outline, color: Colors.white),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: (isSubmitting || action == null) ? null : action,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.semanticSuccessBgHigh,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: isSubmitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : Text(buttonText,
                      style:
                          AppTypography.heading5.copyWith(color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }

  /// (header, button label, action) for the current status.
  (String, String, VoidCallback?) _stage(
    MessengerStatus status,
    MessengerController controller,
  ) {
    switch (status) {
      case MessengerStatus.accepted:
        return ('กำลังไปรับพัสดุ', 'ถึงจุดรับแล้ว', controller.arrived);
      case MessengerStatus.arrivedAtPickup:
        return ('ถึงจุดรับแล้ว', 'รับพัสดุแล้ว', controller.pickedUp);
      case MessengerStatus.pickedUp:
        return ('กำลังไปส่งพัสดุ', 'ส่งสำเร็จ', controller.delivered);
      default:
        return ('กำลังดำเนินการ', 'รอสักครู่', null);
    }
  }
}
