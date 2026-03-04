import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_typography.dart';
import '../../domain/models/vehicle_info.dart';
import '../controllers/registration_controller.dart';

class VehicleInfoFormScreen extends ConsumerStatefulWidget {
  const VehicleInfoFormScreen({super.key});

  @override
  ConsumerState<VehicleInfoFormScreen> createState() => _VehicleInfoFormScreenState();
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
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('กรุณาอัปโหลดรูปสมุดคู่มือรถ')));
        return;
      }
      
      final info = VehicleInfo(
        vehicleType: 'motorcycle',
        brand: _brandController.text.trim(),
        model: _modelController.text.trim(),
        year: int.tryParse(_yearController.text.trim()) ?? 0,
        licensePlate: _plateController.text.trim(),
      );

      final success = await ref.read(registrationControllerProvider.notifier)
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
        title: Text('5. ข้อมูลรถ และ สมุดคู่มือ', style: AppTypography.heading3.copyWith(color: AppColors.semanticGrayNeutralFgHigh)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.semanticGrayNeutralFgHigh),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(24.0),
          children: [
            _buildTextField('ยี่ห้อ (Brand)', _brandController),
            const SizedBox(height: 16),
            _buildTextField('รุ่น (Model)', _modelController),
            const SizedBox(height: 16),
            _buildTextField('ปีจดทะเบียน (Year)', _yearController, isNumber: true),
            const SizedBox(height: 16),
            _buildTextField('เลขทะเบียนรถ (License Plate)', _plateController),
            const SizedBox(height: 24),
            Text('รูปถ่ายหน้าสมุดคู่มือจดทะเบียนรถ', style: AppTypography.caption1.copyWith(color: AppColors.semanticGrayNeutralFgHigh)),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                height: 150,
                decoration: BoxDecoration(
                  color: AppColors.semanticGrayNeutralBgLightgray,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.semanticGrayNeutralBorderLightgray),
                ),
                child: _selectedImage != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.file(_selectedImage!, fit: BoxFit.cover),
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.photo_library, size: 40, color: AppColors.semanticGrayNeutralFgLowOnWhite),
                          const SizedBox(height: 8),
                          Text('แตะเพื่อเลือกรูปภาพจากคลัง', style: AppTypography.caption2.copyWith(color: AppColors.semanticGrayNeutralFgLowOnWhite)),
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
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: state.isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text('บันทึก', style: AppTypography.label1.copyWith(color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, {bool isNumber = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTypography.caption1.copyWith(color: AppColors.semanticGrayNeutralFgHigh)),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: isNumber ? TextInputType.number : TextInputType.text,
          style: AppTypography.label2,
          decoration: InputDecoration(
            filled: true,
            fillColor: AppColors.semanticGrayNeutralBgLightgray,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          ),
          validator: (value) => (value == null || value.trim().isEmpty) ? 'กรุณากรอกข้อมูล' : null,
        ),
      ],
    );
  }
}
