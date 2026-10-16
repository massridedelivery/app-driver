import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:massdrive/common/widgets/indicator/mass_loading_m.dart';

import 'package:massdrive/core/theme/brand_colors.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../features/dependency_injection.dart';
import '../../domain/models/registration_status.dart';
import '../../domain/repositories/document_registration_repository.dart';
import '../controllers/registration_controller.dart';
import '../widgets/registration_ui.dart';

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
          final viewUrl = await repository.getTemporaryViewUrl(
            remoteDoc.imageUrl,
          );
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
    FocusManager.instance.primaryFocus?.unfocus();
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
      final errorMsg =
          ref.read(registrationControllerProvider).errorMessage ??
          'เกิดข้อผิดพลาด กรุณาลองใหม่อีกครั้ง';
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

  IconData get _headerIcon => switch (widget.type) {
    DocumentType.idCard ||
    DocumentType.drivingLicense ||
    DocumentType.publicDrivingLicense => Icons.credit_card_rounded,
    _ => Icons.photo_camera_rounded,
  };

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(registrationControllerProvider);
    final brand = context.brand;

    Widget? previewWidget;
    if (_selectedImage != null) {
      previewWidget = Image.file(_selectedImage!, fit: BoxFit.cover);
    } else if (_isLoadingRemoteImage) {
      previewWidget = const Center(child: MassLoadingM(size: 56));
    } else if (_remoteImageUrl != null && _remoteImageUrl!.isNotEmpty) {
      previewWidget = Image.network(
        _remoteImageUrl!,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
          return const Center(child: MassLoadingM(size: 56));
        },
        errorBuilder: (context, error, stackTrace) {
          debugPrint('Remote image load error: $error');
          return Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.broken_image_outlined, size: 48, color: brand.text3),
              const SizedBox(height: 8),
              Text(
                'ไม่สามารถโหลดรูปภาพได้',
                style: AppTypography.caption5.copyWith(color: brand.text2),
              ),
            ],
          );
        },
      );
    }

    return RegistrationScaffold(
      icon: _headerIcon,
      title: widget.title,
      subtitle:
          'กรุณาอัปโหลดรูปภาพที่ชัดเจนที่สุดเพื่อไม่ให้การลงทะเบียนล่าช้า',
      step: registrationStepNumber(
        state.selectedTier,
        RegistrationItem.fromDocument(widget.type),
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
            RegistrationUploadBox(
              preview: previewWidget,
              label: 'แตะเพื่ออัปโหลดรูปภาพ',
              previewHeight: 200,
              onTap: () => _pickImage(ImageSource.gallery),
              onCamera: () => _pickImage(ImageSource.camera),
              onGallery: () => _pickImage(ImageSource.gallery),
            ),
            if (_needsDocNumber)
              RegistrationField(
                label: widget.type == DocumentType.idCard
                    ? 'หมายเลขบัตรประชาชน (ID Card Number)'
                    : 'หมายเลขใบขับขี่ (License Number)',
                child: TextFormField(
                  controller: _docNumberController,
                  keyboardType: TextInputType.number,
                  style: registrationInputStyle(context),
                  decoration: registrationInputDecoration(
                    context,
                    hint: widget.type == DocumentType.idCard
                        ? 'เลขบัตรประชาชน 13 หลัก'
                        : 'เลขที่ใบอนุญาตขับรถ',
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
              ),
          ],
        ),
      ),
    );
  }
}
