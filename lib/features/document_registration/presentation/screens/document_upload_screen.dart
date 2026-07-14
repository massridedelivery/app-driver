import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../features/dependency_injection.dart';
import '../../domain/models/registration_status.dart';
import '../../domain/repositories/document_registration_repository.dart';
import '../controllers/registration_controller.dart';

class DocumentUploadScreen extends ConsumerStatefulWidget {
  final DocumentType type;
  final String title;

  const DocumentUploadScreen({
    super.key,
    required this.type,
    required this.title,
  });

  @override
  ConsumerState<DocumentUploadScreen> createState() =>
      _DocumentUploadScreenState();
}

class _DocumentUploadScreenState extends ConsumerState<DocumentUploadScreen> {
  File? _selectedImage;
  final ImagePicker _picker = ImagePicker();
  final _formKey = GlobalKey<FormState>();
  final _docNumberController = TextEditingController();

  String? _remoteImageUrl;
  bool _isLoadingRemoteImage = false;

  bool get _needsDocNumber =>
      widget.type == DocumentType.idCard ||
      widget.type == DocumentType.drivingLicense ||
      widget.type == DocumentType.publicDrivingLicense;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final state = ref.read(registrationControllerProvider);
      final remoteDoc = state.remoteDocuments[widget.type];
      
      if (remoteDoc != null && remoteDoc.imageUrl.isNotEmpty) {
        setState(() {
          _isLoadingRemoteImage = true;
        });
        try {
          final repository = getIt<DocumentRegistrationRepository>();
          final viewUrl = await repository.getTemporaryViewUrl(remoteDoc.imageUrl);
          if (mounted) {
            setState(() {
              _remoteImageUrl = viewUrl;
              if (remoteDoc.docNumber != null) {
                _docNumberController.text = remoteDoc.docNumber!;
              }
            });
          }
        } catch (e) {
          debugPrint('Error fetching remote view url: $e');
        } finally {
          if (mounted) {
            setState(() {
              _isLoadingRemoteImage = false;
            });
          }
        }
      }

      // Only restore local temp path if:
      // 1. No remote image is already shown (prefer remote)
      // 2. The file still physically exists (temp files can be deleted by OS)
      final savedDocumentPath = state.uploadedDocuments[widget.type];
      if (savedDocumentPath != null &&
          savedDocumentPath.isNotEmpty &&
          _selectedImage == null &&
          _remoteImageUrl == null) {
        final tempFile = File(savedDocumentPath);
        if (await tempFile.exists()) {
          setState(() {
            _selectedImage = tempFile;
          });
        }
      }
    });
  }

  @override
  void dispose() {
    _docNumberController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    final pickedFile = await _picker.pickImage(source: source);
    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  void _submit() async {
    if (_needsDocNumber && !(_formKey.currentState?.validate() ?? false)) {
      return;
    }
    if (_selectedImage == null && _remoteImageUrl == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('กรุณาเลือกหรือถ่ายรูปภาพก่อนบันทึก')),
      );
      return;
    }

    if (_selectedImage == null) {
      // No new image selected, only potential doc number update.
      context.pop();
      return;
    }

    debugPrint('[Upload] Starting upload for ${widget.type}...');
    final success = await ref
        .read(registrationControllerProvider.notifier)
        .uploadDocument(
          _selectedImage!,
          widget.type,
          docNumber: _needsDocNumber ? _docNumberController.text.trim() : null,
        );

    if (!mounted) return;

    if (success) {
      debugPrint('[Upload] Success for ${widget.type}');
      context.pop();
    } else {
      // Show error from controller state
      final errorMsg = ref.read(registrationControllerProvider).errorMessage
          ?? 'เกิดข้อผิดพลาด กรุณาลองใหม่อีกครั้ง';
      debugPrint('[Upload] Failed for ${widget.type}: $errorMsg');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMsg),
          backgroundColor: Colors.red.shade700,
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(registrationControllerProvider);

    Widget previewWidget;
    if (_selectedImage != null) {
      previewWidget = ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Image.file(_selectedImage!, fit: BoxFit.cover),
      );
    } else if (_isLoadingRemoteImage) {
      previewWidget = const Center(child: CircularProgressIndicator());
    } else if (_remoteImageUrl != null && _remoteImageUrl!.isNotEmpty) {
      previewWidget = ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Image.network(
          _remoteImageUrl!,
          fit: BoxFit.cover,
          loadingBuilder: (context, child, progress) {
            if (progress == null) return child;
            return const Center(child: CircularProgressIndicator());
          },
          errorBuilder: (context, error, stackTrace) {
            debugPrint('Remote image load error: $error');
            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.broken_image_outlined,
                  size: 48,
                  color: AppColors.semanticGrayNeutralFgLowOnWhite,
                ),
                const SizedBox(height: 8),
                Text(
                  'ไม่สามารถโหลดรูปภาพได้',
                  style: AppTypography.caption4.copyWith(
                    color: AppColors.semanticGrayNeutralFgLowOnWhite,
                  ),
                ),
              ],
            );
          },
        ),
      );
    } else {
      previewWidget = Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.cloud_upload_outlined,
            size: 64,
            color: AppColors.semanticGrayNeutralFgLowOnWhite,
          ),
          const SizedBox(height: 16),
          Text(
            'แตะเพื่ออัปโหลดรูปภาพ',
            style: AppTypography.caption3.copyWith(
              color: AppColors.semanticGrayNeutralFgLowOnWhite,
            ),
          ),
        ],
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          widget.title,
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
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'กรุณาอัปโหลดรูปภาพที่ชัดเจนที่สุดเพื่อไม่ให้การลงทะเบียนล่าช้า',
                style: AppTypography.caption2.copyWith(
                  color: AppColors.semanticGrayNeutralFgHigh,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              GestureDetector(
                onTap: () => _pickImage(ImageSource.gallery),
                child: Container(
                  height: 250,
                  decoration: BoxDecoration(
                    color: AppColors.semanticGrayNeutralBgLightgray,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppColors.semanticGrayNeutralBorderLightgray,
                    ),
                  ),
                  child: previewWidget,
                ),
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: () => _pickImage(ImageSource.camera),
                icon: const Icon(
                  Icons.camera_alt,
                  color: AppColors.semanticGrayNeutralFgHigh,
                ),
                label: Text(
                  'ถ่ายรูป',
                  style: AppTypography.label2.copyWith(
                    color: AppColors.semanticGrayNeutralFgHigh,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  side: const BorderSide(
                    color: AppColors.semanticGrayNeutralFgHigh,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
              if (_needsDocNumber) ...[
                const SizedBox(height: 24),
                Text(
                  widget.type == DocumentType.idCard
                      ? 'หมายเลขบัตรประชาชน (ID Card Number)'
                      : 'หมายเลขใบขับขี่ (License Number)',
                  style: AppTypography.label2.copyWith(
                    color: AppColors.semanticGrayNeutralFgHigh,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _docNumberController,
                  keyboardType: TextInputType.number,
                  style: AppTypography.caption3,
                  decoration: InputDecoration(
                    hintText: widget.type == DocumentType.idCard
                        ? 'เลขบัตรประชาชน 13 หลัก'
                        : 'เลขที่ใบอนุญาตขับรถ',
                    filled: true,
                    fillColor: AppColors.semanticGrayNeutralBgLightgray,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'กรุณากรอกหมายเลขเอกสาร';
                    }
                    if (widget.type == DocumentType.idCard &&
                        value.trim().length != 13) {
                      return 'กรุณากรอกเลขบัตรประชาชนให้ครบ 13 หลัก';
                    }
                    return null;
                  },
                ),
              ],
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
      ),
    );
  }
}
