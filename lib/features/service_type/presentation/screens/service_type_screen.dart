import 'package:flutter/material.dart';
import 'package:massdrive/common/widgets/appbar/base_appbar.dart';
import 'package:massdrive/core/constants/app_colors.dart';
import 'package:massdrive/features/service_type/data/repositories/service_repository_impl.dart';
import 'package:massdrive/features/service_type/domain/usecase/toggle_service_use_case.dart';
import 'package:massdrive/features/service_type/presentation/controller/service_controller.dart';
import 'package:massdrive/features/service_type/presentation/widget/service_toggle_tile.dart';
import 'package:provider/provider.dart';

class ServiceTypeScreen extends StatelessWidget {
  const ServiceTypeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final repository = ServiceRepositoryImpl();
    final toggleUseCase = ToggleServiceUseCase(repository);

    return ChangeNotifierProvider(
      create: (_) => ServiceController(
        repository: repository,
        toggleUseCase: toggleUseCase,
      )..load(),
      child: const _ServiceTypeView(),
    );
  }
}

class _ServiceTypeView extends StatelessWidget {
  const _ServiceTypeView();

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<ServiceController>();
    final state = controller.state;

    return Scaffold(
      appBar: CommonAppBar(titleText: 'ประเภทการบริการ', showLeftIcon: true),
      body: Container(
        color: AppColors.semanticGrayNeutralFgHigh,
        child: state.isLoading
            ? const Center(child: CircularProgressIndicator())
            : ListView.separated(
                itemCount: state.services.length,
                separatorBuilder: (_, __) => const Divider(
                  color: AppColors.semanticGrayNeutralFgLowOnGray,
                  height: 1,
                ),
                itemBuilder: (context, index) {
                  final service = state.services[index];

                  return ServiceToggleTile(
                    title: service.name,
                    isEnabled: service.isEnabled,
                    onToggle: () => controller.toggle(service.id),
                  );
                },
              ),
      ),
    );
  }
}
