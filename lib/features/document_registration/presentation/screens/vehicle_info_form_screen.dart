import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:massdrive/features/document_registration/domain/document_photo.dart';
import 'package:massdrive/common/widgets/image_source_sheet.dart';
import 'package:massdrive/core/theme/brand_colors.dart';
import 'package:massdrive/features/document_registration/domain/models/registration_status.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_typography.dart';
import '../controllers/registration_controller.dart';
import '../widgets/expiry_date_field.dart';
import '../widgets/registration_ui.dart';
import '../widgets/vehicle_fields.dart';

class VehicleInfoFormScreen extends ConsumerStatefulWidget {
  const VehicleInfoFormScreen({super.key});

  @override
  ConsumerState<VehicleInfoFormScreen> createState() =>
      _VehicleInfoFormScreenState();
}

class _VehicleInfoFormScreenState extends ConsumerState<VehicleInfoFormScreen> {
  final _formKey = GlobalKey<FormState>();
  VehicleFieldsController _fields = VehicleFieldsController();

  File? _selectedImage;
  final ImagePicker _picker = ImagePicker();

  /// Optional expiry of the registration, sent with a new book photo.
  DateTime? _registrationExpiry;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final state = ref.read(registrationControllerProvider);
      final vehicleInfo = state.vehicleInfo;
      if (vehicleInfo != null) {
        final old = _fields;
        setState(() => _fields = VehicleFieldsController(initial: vehicleInfo));
        old.dispose();
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
    _fields.dispose();
    super.dispose();
  }

  /// Ask camera vs gallery, then pick.
  Future<void> _chooseAndPickImage() async {
    final source = await showImageSourceSheet(context);
    if (source == null) return;
    // Shrunk on pick (see docPhotoMaxSide): fast on mobile data, still
    // readable; also turns an iPhone HEIC into a JPEG.
    final pickedFile = await _picker.pickImage(
      source: source,
      maxWidth: docPhotoMaxSide.toDouble(),
      maxHeight: docPhotoMaxSide.toDouble(),
      imageQuality: docPhotoQuality,
    );
    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  /// The registration book is already on the backend (e.g. a driver who saved
  /// only a plate on an older app version and is finishing the step now).
  bool get _bookOnFile => ref
      .read(registrationControllerProvider)
      .remoteDocuments
      .containsKey(DocumentType.vehicleRegistration);

  void _submit() async {
    FocusManager.instance.primaryFocus?.unfocus();
    if (_formKey.currentState?.validate() ?? false) {
      if (_selectedImage == null && !_bookOnFile) {
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

      final info = _fields.value;

      final success = await ref
          .read(registrationControllerProvider.notifier)
          .submitVehicleDetails(
            info,
            _selectedImage,
            registrationExpiry: _registrationExpiry,
          );

      if (mounted) {
        if (success) {
          context.pop();
        } else {
          final error = ref.read(registrationControllerProvider).errorMessage;
          // Refused as too large: drop the photo so the driver takes it again.
          if (ref.read(registrationControllerProvider.notifier).lastUploadTooLarge) {
            setState(() => _selectedImage = null);
          }
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
            VehicleFields(controller: _fields),
            const SizedBox(height: 4),
            RegistrationUploadBox(
              label: 'รูปถ่ายหน้าสมุดคู่มือจดทะเบียนรถ',
              preview: _selectedImage != null
                  ? Image.file(_selectedImage!, fit: BoxFit.cover)
                  : state.remoteDocuments.containsKey(
                      DocumentType.vehicleRegistration,
                    )
                  ? const _BookOnFile()
                  : null,
              previewHeight: 150,
              onTap: _chooseAndPickImage,
            ),
            ExpiryDateField(
              value: _registrationExpiry,
              onChanged: (d) => setState(() => _registrationExpiry = d),
            ),
          ],
        ),
      ),
    );
  }
}

/// Upload-box preview when the registration book is already uploaded and no
/// new photo was picked: tap the box to replace it.
class _BookOnFile extends StatelessWidget {
  const _BookOnFile();

  @override
  Widget build(BuildContext context) {
    final brand = context.brand;
    return ColoredBox(
      color: brand.fill,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle_rounded, color: brand.ok, size: 32),
            const SizedBox(height: 6),
            Text(
              'อัปโหลดแล้ว · แตะเพื่อเปลี่ยนรูป',
              style: AppTypography.caption4.copyWith(color: brand.text2),
            ),
          ],
        ),
      ),
    );
  }
}
