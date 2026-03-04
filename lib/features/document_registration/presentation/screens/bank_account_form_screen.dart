import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_typography.dart';
import '../../domain/models/bank_account_info.dart';
import '../controllers/registration_controller.dart';

class BankAccountFormScreen extends ConsumerStatefulWidget {
  const BankAccountFormScreen({super.key});

  @override
  ConsumerState<BankAccountFormScreen> createState() => _BankAccountFormScreenState();
}

class _BankAccountFormScreenState extends ConsumerState<BankAccountFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _bankNameController = TextEditingController();
  final _accountNameController = TextEditingController();
  final _accountNumberController = TextEditingController();
  
  File? _selectedImage;
  final ImagePicker _picker = ImagePicker();

  @override
  void dispose() {
    _bankNameController.dispose();
    _accountNameController.dispose();
    _accountNumberController.dispose();
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
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('กรุณาอัปโหลดรูปสมุดบัญชีธนาคาร')));
        return;
      }
      
      final info = BankAccountInfo(
        bankName: _bankNameController.text.trim(),
        accountName: _accountNameController.text.trim(),
        accountNumber: _accountNumberController.text.trim(),
      );

      final success = await ref.read(registrationControllerProvider.notifier)
          .submitBankDetails(info, _selectedImage);
          
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
        title: Text('8. ข้อมูลบัญชีธนาคาร', style: AppTypography.heading3.copyWith(color: AppColors.semanticGrayNeutralFgHigh)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.semanticGrayNeutralFgHigh),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(24.0),
          children: [
            _buildTextField('ธนาคาร (Bank Name)', _bankNameController),
            const SizedBox(height: 16),
            _buildTextField('ชื่อบัญชี (Account Name)', _accountNameController),
            const SizedBox(height: 16),
            _buildTextField('หมายเลขบัญชี (Account Number)', _accountNumberController, isNumber: true),
            const SizedBox(height: 24),
            Text('รูปสมุดบัญชีธนาคารหน้าแรก', style: AppTypography.caption1.copyWith(color: AppColors.semanticGrayNeutralFgHigh)),
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
