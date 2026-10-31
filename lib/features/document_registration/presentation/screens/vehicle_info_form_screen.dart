import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:massdrive/common/widgets/image_source_sheet.dart';
import 'package:massdrive/features/document_registration/domain/models/registration_status.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_typography.dart';
import '../../domain/models/vehicle_info.dart';
import '../controllers/registration_controller.dart';
import '../widgets/registration_ui.dart';

class VehicleInfoFormScreen extends ConsumerStatefulWidget {
  const VehicleInfoFormScreen({super.key});

  @override
  ConsumerState<VehicleInfoFormScreen> createState() =>
      _VehicleInfoFormScreenState();
}

class _VehicleInfoFormScreenState extends ConsumerState<VehicleInfoFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _brandController = TextEditingController();
  final _modelController = TextEditingController();
  final _yearController = TextEditingController();
  final _plateController = TextEditingController();

  File? _selectedImage;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final state = ref.read(registrationControllerProvider);
      final vehicleInfo = state.vehicleInfo;
      if (vehicleInfo != null) {
        _brandController.text = vehicleInfo.brand;
        _modelController.text = vehicleInfo.model;
        _yearController.text = vehicleInfo.year.toString();
        _plateController.text = vehicleInfo.licensePlate;
      }

      final savedDocumentPath =
          state.uploadedDocuments[DocumentType.vehicleRegistration];
      if (savedDocumentPath != null && savedDocumentPath.isNotEmpty) {
        setState(() {
          _selectedImage = File(savedDocumentPath);
        });
      }
    });
  }

  @override
  void dispose() {
    _brandController.dispose();
    _modelController.dispose();
    _yearController.dispose();
    _plateController.dispose();
    super.dispose();
  }

  /// Ask camera vs gallery, then pick.
  Future<void> _chooseAndPickImage() async {
    final source = await showImageSourceSheet(context);
    if (source == null) return;
    final pickedFile = await _picker.pickImage(source: source);
    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  void _submit() async {
    FocusManager.instance.primaryFocus?.unfocus();
    if (_formKey.currentState?.validate() ?? false) {
      if (_selectedImage == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.foundationRed800,
            content: Text(
              'กรุณาอัปโหลดรูปสมุดคู่มือรถ',
              style: AppTypography.caption3.copyWith(
                color: AppColors.semanticGrayNeutralFgWhite,
              ),
            ),
          ),
        );
        return;
      }

      final info = VehicleInfo(
        vehicleType: 'motorcycle',
        brand: _brandController.text.trim(),
        model: _modelController.text.trim(),
        year: int.tryParse(_yearController.text.trim()) ?? 0,
        licensePlate: _plateController.text.trim(),
      );

      final success = await ref
          .read(registrationControllerProvider.notifier)
          .submitVehicleDetails(info, _selectedImage);

      if (mounted) {
        if (success) {
          context.pop();
        } else {
          final error = ref.read(registrationControllerProvider).errorMessage;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: AppColors.foundationRed800,
              content: Text(
                error ?? 'เกิดข้อผิดพลาดในการบันทึกข้อมูล',
                style: AppTypography.caption3.copyWith(
                  color: AppColors.semanticGrayNeutralFgWhite,
                ),
              ),
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(registrationControllerProvider);

    return RegistrationScaffold(
      icon: Icons.two_wheeler_rounded,
      title: 'ข้อมูลรถ และ สมุดคู่มือ',
      step: registrationStepNumber(
        state.selectedTier,
        RegistrationItem.vehicle,
      ),
      total: state.selectedTier == null
          ? null
          : registrationTotalSteps(state.selectedTier!),
      bottom: RegistrationPrimaryButton(
        label: 'บันทึก',
        loading: state.isLoading,
        onPressed: state.isLoading ? null : _submit,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _buildTextField(
                    'ยี่ห้อ (Brand)',
                    _brandController,
                    hint: 'เช่น Honda',
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildTextField(
                    'รุ่น (Model)',
                    _modelController,
                    hint: 'เช่น Wave 110i',
                  ),
                ),
              ],
            ),
            _buildTextField(
              'ปีจดทะเบียน (Year)',
              _yearController,
              isNumber: true,
              hint: 'เช่น 2023',
            ),
            _buildTextField(
              'เลขทะเบียนรถ (License Plate)',
              _plateController,
              hint: 'เช่น 1กข 1234 กทม.',
            ),
            const SizedBox(height: 4),
            RegistrationUploadBox(
              label: 'รูปถ่ายหน้าสมุดคู่มือจดทะเบียนรถ',
              preview: _selectedImage != null
                  ? Image.file(_selectedImage!, fit: BoxFit.cover)
                  : null,
              previewHeight: 150,
              onTap: _chooseAndPickImage,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller, {
    bool isNumber = false,
    String? hint,
  }) {
    return RegistrationField(
      label: label,
      child: TextFormField(
        controller: controller,
        keyboardType: isNumber ? TextInputType.number : TextInputType.text,
        style: registrationInputStyle(context),
        decoration: registrationInputDecoration(context, hint: hint),
        validator: (value) => (value == null || value.trim().isEmpty)
            ? 'กรุณากรอกข้อมูลให้ครบถ้วน'
            : null,
      ),
    );
  }
}
