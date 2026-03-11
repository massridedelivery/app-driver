import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:massdrive/features/document_registration/domain/models/registration_status.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_typography.dart';
import '../../domain/models/vehicle_info.dart';
import '../controllers/registration_controller.dart';

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

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  void _submit() async {
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

      if (success && mounted) {
        context.pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(registrationControllerProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          'ข้อมูลรถ และ สมุดคู่มือ',
          style: AppTypography.heading4.copyWith(
            color: AppColors.semanticGrayNeutralFgHigh,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(
          color: AppColors.semanticGrayNeutralFgHigh,
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(24.0),
          children: [
            _buildTextField(
              'ยี่ห้อ (Brand)',
              _brandController,
              hint: 'เช่น Honda',
            ),
            const SizedBox(height: 16),
            _buildTextField(
              'รุ่น (Model)',
              _modelController,
              hint: 'เช่น Wave 110i',
            ),
            const SizedBox(height: 16),
            _buildTextField(
              'ปีจดทะเบียน (Year)',
              _yearController,
              isNumber: true,
              hint: 'เช่น 2023',
            ),
            const SizedBox(height: 16),
            _buildTextField(
              'เลขทะเบียนรถ (License Plate)',
              _plateController,
              hint: 'เช่น 1กข 1234 กทม.',
            ),
            const SizedBox(height: 24),
            Text(
              'รูปถ่ายหน้าสมุดคู่มือจดทะเบียนรถ',
              style: AppTypography.label2.copyWith(
                color: AppColors.semanticGrayNeutralFgHigh,
              ),
            ),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                height: 150,
                decoration: BoxDecoration(
                  color: AppColors.semanticGrayNeutralBgLightgray,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.semanticGrayNeutralBorderLightgray,
                  ),
                ),
                child: _selectedImage != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.file(_selectedImage!, fit: BoxFit.cover),
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.cloud_upload_outlined,
                            size: 40,
                            color: AppColors.semanticGrayNeutralFgLowOnWhite,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'แตะเพื่ออัปโหลดรูปภาพ',
                            style: AppTypography.caption3.copyWith(
                              color: AppColors.semanticGrayNeutralFgLowOnWhite,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 40),
            SizedBox(
              height: 56,
              child: ElevatedButton(
                onPressed: state.isLoading ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.semanticGrayNeutralFgHigh,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: state.isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(
                        'บันทึก',
                        style: AppTypography.label1.copyWith(
                          color: Colors.white,
                        ),
                      ),
              ),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTypography.label2.copyWith(
            color: AppColors.semanticGrayNeutralFgHigh,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: isNumber ? TextInputType.number : TextInputType.text,
          style: AppTypography.caption3,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: AppTypography.caption3.copyWith(
              color: AppColors.semanticGrayNeutralFgLowOnWhite,
            ),
            filled: true,
            fillColor: AppColors.semanticGrayNeutralBgLightgray,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            errorStyle: AppTypography.caption4.copyWith(
              color: AppColors.foundationRed800,
            ),
          ),
          validator: (value) => (value == null || value.trim().isEmpty)
              ? 'กรุณากรอกข้อมูลให้ครบถ้วน'
              : null,
        ),
      ],
    );
  }
}
