import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:massdrive/common/widgets/appbar/base_appbar.dart';
import 'package:massdrive/common/widgets/indicator/mass_loading_m.dart';
import 'package:massdrive/core/theme/app_palette.dart';
import 'package:massdrive/features/profile/presentation/controllers/profile_controller.dart';
import 'package:massdrive/features/service_type/presentation/widget/service_toggle_tile.dart';

/// Thai copy for the service types. The backend sends English display
/// names/descriptions, so map the known values to Thai here; anything not in
/// the map falls back to whatever the API sent.
const Map<String, String> _serviceLabelTh = {
  // Names
  'Motorcycle (Ride Only)': 'มอเตอร์ไซค์ (รับส่งคน)',
  'Motorcycle (Food Only)': 'มอเตอร์ไซค์ (ส่งอาหาร)',
  'Messenger Bike': 'มอเตอร์ไซค์รับส่งของ',
  'Messenger Car': 'รถยนต์รับส่งของ',
  'Comfort Car': 'รถยนต์คอมฟอร์ต',
  'Economy Car': 'รถยนต์อีโคโนมี',
  'Tuk-Tuk': 'ตุ๊กตุ๊ก',
  'Van': 'รถตู้',
  // Descriptions
  'Standard motorcycle taxi for passenger rides only. Public transport license required.':
      'มอเตอร์ไซค์รับจ้างสำหรับรับส่งผู้โดยสารเท่านั้น ต้องมีใบอนุญาตขับขี่สาธารณะ',
  'Standard motorcycle for food delivery only. No public transport license required.':
      'มอเตอร์ไซค์สำหรับส่งอาหารเท่านั้น ไม่ต้องมีใบอนุญาตขับขี่สาธารณะ',
  'Motorcycle courier for small-to-medium packages':
      'รับส่งพัสดุขนาดเล็กถึงกลาง',
  'Car courier for larger or bulky packages':
      'รถยนต์รับส่งพัสดุขนาดใหญ่หรือของหนัก',
  'Spacious sedan with premium comfort':
      'รถเก๋งกว้างขวาง นั่งสบายระดับพรีเมียม',
  'Affordable compact car for everyday rides':
      'รถเก๋งประหยัด เหมาะสำหรับการเดินทางทั่วไป',
  'Traditional Thai three-wheeler experience': 'รถสามล้อไทยสไตล์ดั้งเดิม',
  'Large vehicle for groups up to 6 passengers':
      'รถคันใหญ่ รองรับผู้โดยสารสูงสุด 6 คน',
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
        color: context.palette.bg,
        child: profileState.isLoading || profileState.profile == null
            ? const Center(child: MassLoadingM(size: 72))
            : ListView.separated(
                // Clear the Android edge-to-edge system nav.
                padding: EdgeInsets.only(
                  bottom: MediaQuery.viewPaddingOf(context).bottom + 16,
                ),
                itemCount: vehicleTypes.length,
                separatorBuilder: (context, index) => Divider(
                  color: context.palette.border,
                  height: 1,
                ),
                itemBuilder: (context, index) {
                  final service = vehicleTypes[index];

                  return ServiceToggleTile(
                    title: _th(service.displayName),
                    description: _th(service.description),
                    // vehicleTypes use displayName from backend
                    isEnabled: service.isEnabled,
                    onToggle: () async {
                      final ok = await ref
                          .read(profileControllerProvider.notifier)
                          .toggleVehicleType(service.id, !service.isEnabled);
                      if (!ok && context.mounted) {
                        // Backend rejects enabling a type that doesn't belong to
                        // the driver's physical vehicle (cross-kind) — it comes
                        // back as a 500, so show a clear message instead of a
                        // silent no-op.
                        final msg = ref
                            .read(profileControllerProvider)
                            .errorMessage;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              (msg != null && msg.trim().isNotEmpty)
                                  ? msg
                                  : 'เปลี่ยนประเภทบริการไม่สำเร็จ — เลือกได้เฉพาะประเภทที่อยู่บนรถคันเดียวกัน',
                            ),
                          ),
                        );
                      }
                    },
                  );
                },
              ),
      ),
    );
  }
}
