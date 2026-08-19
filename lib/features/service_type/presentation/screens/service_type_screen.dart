import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:massdrive/common/widgets/appbar/base_appbar.dart';
import 'package:massdrive/common/widgets/indicator/mass_loading_m.dart';
import 'package:massdrive/core/constants/app_colors.dart';
import 'package:massdrive/features/profile/presentation/controllers/profile_controller.dart';
import 'package:massdrive/features/service_type/presentation/widget/service_toggle_tile.dart';

/// Thai copy for the service types. The backend sends English display
/// names/descriptions, so map the known values to Thai here; anything not in
/// the map falls back to whatever the API sent.
const Map<String, String> _serviceLabelTh = {
  'Motorcycle (Ride Only)': 'มอเตอร์ไซค์ (รับส่งคน)',
  'Standard motorcycle taxi for passenger rides only. Public transport license required.':
      'มอเตอร์ไซค์รับจ้างสำหรับรับส่งผู้โดยสารเท่านั้น ต้องมีใบอนุญาตขับขี่สาธารณะ',
  'Motorcycle (Food Only)': 'มอเตอร์ไซค์ (ส่งอาหาร)',
  'Standard motorcycle for food delivery only. No public transport license required.':
      'มอเตอร์ไซค์สำหรับส่งอาหารเท่านั้น ไม่ต้องมีใบอนุญาตขับขี่สาธารณะ',
  'Messenger Bike': 'มอเตอร์ไซค์รับส่งของ',
  'Motorcycle courier for small-to-medium packages':
      'รับส่งพัสดุขนาดเล็กถึงกลาง',
};

String _th(String? value) =>
    value == null ? '' : (_serviceLabelTh[value.trim()] ?? value);

class ServiceTypeScreen extends ConsumerWidget {
  const ServiceTypeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileState = ref.watch(profileControllerProvider);
    final vehicleTypes = profileState.profile?.vehicleTypes ?? [];

    return Scaffold(
      appBar: CommonAppBar(titleText: 'ประเภทการบริการ', showLeftIcon: true),
      body: Container(
        color: AppColors.semanticGrayNeutralFgHigh,
        child: profileState.isLoading || profileState.profile == null
            ? const Center(child: MassLoadingM(size: 72))
            : ListView.separated(
                // Clear the Android edge-to-edge system nav.
                padding: EdgeInsets.only(
                  bottom: MediaQuery.viewPaddingOf(context).bottom + 16,
                ),
                itemCount: vehicleTypes.length,
                separatorBuilder: (context, index) => const Divider(
                  color: AppColors.semanticGrayNeutralFgLowOnGray,
                  height: 1,
                ),
                itemBuilder: (context, index) {
                  final service = vehicleTypes[index];

                  return ServiceToggleTile(
                    title: _th(service.displayName),
                    description: _th(service.description),
                    // vehicleTypes use displayName from backend
                    isEnabled: service.isEnabled,
                    onToggle: () {
                      ref
                          .read(profileControllerProvider.notifier)
                          .toggleVehicleType(service.id, !service.isEnabled);
                    },
                  );
                },
              ),
      ),
    );
  }
}
