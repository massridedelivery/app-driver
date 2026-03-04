import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_typography.dart';
import '../../domain/models/registration_status.dart';
import '../controllers/registration_controller.dart';

class DocumentUploadScreen extends ConsumerStatefulWidget {
  final DocumentType type;
  final String title;

  const DocumentUploadScreen({super.key, required this.type, required this.title});

  @override
  ConsumerState<DocumentUploadScreen> createState() => _DocumentUploadScreenState();
}

class _DocumentUploadScreenState extends ConsumerState<DocumentUploadScreen> {
  File? _selectedImage;
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage(ImageSource source) async {
    final pickedFile = await _picker.pickImage(source: source);
    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  void _submit() async {
    if (_selectedImage == null) return;
    final success = await ref.read(registrationControllerProvider.notifier).uploadDocument(_selectedImage!, widget.type);
    if (success && mounted) {
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(registrationControllerProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          widget.title,
          style: AppTypography.heading3.copyWith(color: AppColors.semanticGrayNeutralFgHigh),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.semanticGrayNeutralFgHigh),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'กรุณาอัปโหลดรูปภาพที่ชัดเจนที่สุดเพื่อไม่ให้การลงทะเบียนล่าช้า',
              style: AppTypography.caption1.copyWith(color: AppColors.semanticGrayNeutralFgHigh),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            GestureDetector(
              onTap: () => _pickImage(ImageSource.gallery),
              child: Container(
                height: 250,
                decoration: BoxDecoration(
                  color: AppColors.semanticGrayNeutralBgDefault,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.semanticGrayNeutralBorderLightgray),
                ),
                child: _selectedImage != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image.file(_selectedImage!, fit: BoxFit.cover),
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.cloud_upload_outlined, size: 64, color: AppColors.semanticGrayNeutralFgLow),
                          const SizedBox(height: 16),
                          Text('แตะเพื่ออัปโหลดรูปภาพ', style: AppTypography.subtitle2.copyWith(color: AppColors.semanticGrayNeutralFgLow)),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: () => _pickImage(ImageSource.camera),
              icon: const Icon(Icons.camera_alt, color: AppColors.semanticGrayNeutralFgHigh),
              label: Text('ถ่ายรูป', style: AppTypography.subtitle2.copyWith(color: AppColors.semanticGrayNeutralFgHigh)),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                side: const BorderSide(color: AppColors.semanticGrayNeutralFgHigh),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
            const Spacer(),
            SizedBox(
              height: 56,
              child: ElevatedButton(
                onPressed: (_selectedImage == null || state.isLoading) ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.semanticGrayNeutralFgHigh,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: state.isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text('บันทึก', style: AppTypography.subtitle1.copyWith(color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
