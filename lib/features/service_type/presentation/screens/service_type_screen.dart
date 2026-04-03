import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:massdrive/common/widgets/appbar/base_appbar.dart';
import 'package:massdrive/core/constants/app_colors.dart';
import 'package:massdrive/features/profile/presentation/controllers/profile_controller.dart';
import 'package:massdrive/features/service_type/presentation/widget/service_toggle_tile.dart';

class ServiceTypeScreen extends ConsumerWidget {
  const ServiceTypeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileState = ref.watch(profileControllerProvider);
    final vehicleTypes = profileState.profile?.vehicleTypes ?? [];
    print('vehicleTypes : $vehicleTypes');

    return Scaffold(
      appBar: CommonAppBar(titleText: 'ประเภทการบริการ', showLeftIcon: true),
      body: Container(
        color: AppColors.semanticGrayNeutralFgHigh,
        child: profileState.isLoading || profileState.profile == null
            ? const Center(child: CircularProgressIndicator())
            : ListView.separated(
                itemCount: vehicleTypes.length,
                separatorBuilder: (context, index) => const Divider(
                  color: AppColors.semanticGrayNeutralFgLowOnGray,
                  height: 1,
                ),
                itemBuilder: (context, index) {
                  final service = vehicleTypes[index];

                  return ServiceToggleTile(
                    title: service.displayName,
                    description: service.description,
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
