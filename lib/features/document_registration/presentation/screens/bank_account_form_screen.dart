import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../features/dependency_injection.dart';
import '../../domain/models/bank_account_info.dart';
import '../../domain/models/registration_status.dart';
import '../../domain/repositories/document_registration_repository.dart';
import '../../../income/presentation/controllers/wallet_controller.dart';
import '../controllers/registration_controller.dart';

class BankAccountFormScreen extends ConsumerStatefulWidget {
  const BankAccountFormScreen({super.key});

  @override
  ConsumerState<BankAccountFormScreen> createState() =>
      _BankAccountFormScreenState();
}

class _BankAccountFormScreenState extends ConsumerState<BankAccountFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _bankNameController = TextEditingController();
  final _accountNameController = TextEditingController();
  final _accountNumberController = TextEditingController();

  File? _selectedImage;
  String? _remoteImageUrl;
  bool _isLoadingRemoteImage = false;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // 1. Fetch the latest status which includes the payout method from /api/driver/payouts/method
      await ref.read(registrationControllerProvider.notifier).fetchStatus();
      if (!mounted) return;

      final state = ref.read(registrationControllerProvider);
      
      // 2. Pre-populate form text fields with registered bank details
      final bankInfo = state.bankAccountInfo;
      if (bankInfo != null) {
        _bankNameController.text = bankInfo.bankName;
        _accountNameController.text = bankInfo.accountName;
        _accountNumberController.text = bankInfo.accountNumber;
      }

      // 3. Check for existing remote passbook image and retrieve temporary S3 view URL
      final remoteDoc = state.remoteDocuments[DocumentType.bankPassbook];
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
            });
          }
        } catch (e) {
          debugPrint('Error fetching remote passbook URL: $e');
        } finally {
          if (mounted) {
            setState(() {
              _isLoadingRemoteImage = false;
            });
          }
        }
      }

      // 4. Restore local temporary path if file physically exists
      final savedDocumentPath =
          state.uploadedDocuments[DocumentType.bankPassbook];
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
      if (_selectedImage == null && _remoteImageUrl == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.foundationRed800,
            content: Text(
              'กรุณาอัปโหลดรูปสมุดบัญชีธนาคาร',
              style: AppTypography.caption3.copyWith(
                color: AppColors.semanticGrayNeutralFgWhite,
              ),
            ),
          ),
        );
        return;
      }

      final info = BankAccountInfo(
        bankName: _bankNameController.text.trim(),
        accountName: _accountNameController.text.trim(),
        accountNumber: _accountNumberController.text.trim(),
      );

      final success = await ref
          .read(registrationControllerProvider.notifier)
          .submitBankDetails(info, _selectedImage);

      if (mounted) {
        if (success) {
          // Re-fetch payouts / balance on wallet controller if available
          ref.invalidate(walletControllerProvider);
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

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          'ข้อมูลบัญชีธนาคาร',
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
              'ธนาคาร (Bank Name)',
              _bankNameController,
              hint: 'เช่น กสิกรไทย (KBank)',
            ),
            const SizedBox(height: 16),
            _buildTextField(
              'ชื่อบัญชี (Account Name)',
              _accountNameController,
              hint: 'เช่น นาย สมชาย ใจดี',
            ),
            const SizedBox(height: 16),
            _buildTextField(
              'หมายเลขบัญชี (Account Number)',
              _accountNumberController,
              isNumber: true,
              hint: 'เช่น 0123456789',
            ),
            const SizedBox(height: 24),
            Text(
              'รูปสมุดบัญชีธนาคารหน้าแรก',
              style: AppTypography.caption2.copyWith(
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
                    : _remoteImageUrl != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.network(_remoteImageUrl!, fit: BoxFit.cover),
                          )
                        : _isLoadingRemoteImage
                            ? const Center(child: CircularProgressIndicator())
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
