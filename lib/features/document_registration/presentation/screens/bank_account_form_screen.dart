import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:massdrive/common/widgets/image_source_sheet.dart';
import 'package:massdrive/common/widgets/indicator/mass_loading_m.dart';
import 'package:massdrive/common/widgets/bank_logo_avatar.dart';

import '../../../../core/constants/app_colors.dart';
import 'package:massdrive/core/constants/thai_banks.dart';
import 'package:massdrive/core/theme/app_palette.dart';
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
  final _accountNameController = TextEditingController();
  final _accountNumberController = TextEditingController();

  ThaiBank? _selectedBank;
  bool _bankError = false;

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
      
      // 2. Pre-populate form fields with registered bank details. Resolve the
      // stored bank_name string back to a ThaiBank so the selector pre-selects.
      final bankInfo = state.bankAccountInfo;
      if (bankInfo != null) {
        setState(() {
          _selectedBank = findThaiBank(bankInfo.bankName);
        });
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
    _accountNameController.dispose();
    _accountNumberController.dispose();
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
    // Validate the bank selector alongside the text fields.
    final fieldsValid = _formKey.currentState?.validate() ?? false;
    if (_selectedBank == null) {
      setState(() => _bankError = true);
    }
    if (fieldsValid && _selectedBank != null) {
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
        bankName: _selectedBank!.nameLong,
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
      backgroundColor: context.palette.bg,
      appBar: AppBar(
        title: Text(
          'ข้อมูลบัญชีธนาคาร',
          style: AppTypography.heading4.copyWith(
            color: context.palette.textPrimary,
          ),
        ),
        backgroundColor: context.palette.bg,
        elevation: 0,
        iconTheme: IconThemeData(
          color: context.palette.textPrimary,
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          // Clear the Android edge-to-edge system nav so the submit button
          // isn't hidden behind it.
          padding: EdgeInsets.fromLTRB(
            24,
            24,
            24,
            24 + MediaQuery.viewPaddingOf(context).bottom,
          ),
          children: [
            _buildBankSelector(),
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
                color: context.palette.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: _chooseAndPickImage,
              child: Container(
                height: 150,
                decoration: BoxDecoration(
                  color: context.palette.surfaceAlt,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: context.palette.border,
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
                            ? const Center(child: MassLoadingM(size: 56))
                            : Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.cloud_upload_outlined,
                                    size: 40,
                                    color: context.palette.textSecondary,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'แตะเพื่ออัปโหลดรูปภาพ',
                                    style: AppTypography.caption3.copyWith(
                                      color: context.palette.textSecondary,
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
                  backgroundColor: context.palette.textPrimary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: state.isLoading
                    ? CircularProgressIndicator(color: context.palette.bg)
                    : Text(
                        'บันทึก',
                        style: AppTypography.label1.copyWith(
                          color: context.palette.bg,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Bank selector: a tappable field that opens a searchable bank picker.
  Widget _buildBankSelector() {
    final bank = _selectedBank;
    final borderColor = _bankError ? AppColors.foundationRed800 : null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'ธนาคาร (Bank)',
          style: AppTypography.label2.copyWith(
            color: context.palette.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: _openBankPicker,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: context.palette.surfaceAlt,
              borderRadius: BorderRadius.circular(12),
              border: borderColor != null
                  ? Border.all(color: borderColor)
                  : null,
            ),
            child: Row(
              children: [
                if (bank != null) ...[
                  BankLogoAvatar(bank: bank, size: 36),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      bank.nameLong,
                      style: AppTypography.caption3.copyWith(
                        color: context.palette.textPrimary,
                      ),
                    ),
                  ),
                ] else
                  Expanded(
                    child: Text(
                      'เลือกธนาคาร',
                      style: AppTypography.caption3.copyWith(
                        color: context.palette.textSecondary,
                      ),
                    ),
                  ),
                Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: context.palette.textSecondary,
                ),
              ],
            ),
          ),
        ),
        if (_bankError)
          Padding(
            padding: const EdgeInsets.only(top: 6, left: 4),
            child: Text(
              'กรุณาเลือกธนาคาร',
              style: AppTypography.caption4.copyWith(
                color: AppColors.foundationRed800,
              ),
            ),
          ),
      ],
    );
  }

  /// Bottom-sheet bank picker with a search box and logo + name list.
  Future<void> _openBankPicker() async {
    final selected = await showModalBottomSheet<ThaiBank>(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.palette.bg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        String query = '';
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            final q = query.trim().toLowerCase();
            final banks = q.isEmpty
                ? kThaiBanks
                : kThaiBanks
                    .where((b) =>
                        b.name.toLowerCase().contains(q) ||
                        b.nameLong.toLowerCase().contains(q) ||
                        b.nameEn.toLowerCase().contains(q) ||
                        b.code.toLowerCase().contains(q))
                    .toList();
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.viewInsetsOf(ctx).bottom,
              ),
              child: SizedBox(
                height: MediaQuery.sizeOf(ctx).height * 0.75,
                child: Column(
                  children: [
                    const SizedBox(height: 12),
                    Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: context.palette.border,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                      child: Text(
                        'เลือกธนาคาร',
                        style: AppTypography.heading5.copyWith(
                          color: context.palette.textPrimary,
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                      child: TextField(
                        autofocus: false,
                        style: AppTypography.caption3.copyWith(
                          color: context.palette.textPrimary,
                        ),
                        onChanged: (v) => setSheetState(() => query = v),
                        decoration: InputDecoration(
                          hintText: 'ค้นหาธนาคาร',
                          hintStyle: AppTypography.caption3.copyWith(
                            color: context.palette.textSecondary,
                          ),
                          prefixIcon: Icon(
                            Icons.search,
                            color: context.palette.textSecondary,
                          ),
                          filled: true,
                          fillColor: context.palette.surfaceAlt,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: banks.isEmpty
                          ? Center(
                              child: Text(
                                'ไม่พบธนาคาร',
                                style: AppTypography.caption3.copyWith(
                                  color: context.palette.textSecondary,
                                ),
                              ),
                            )
                          : ListView.separated(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                              ),
                              itemCount: banks.length,
                              separatorBuilder: (_, _) => Divider(
                                height: 1,
                                color: context.palette.border,
                              ),
                              itemBuilder: (_, i) {
                                final b = banks[i];
                                final isSel = _selectedBank?.code == b.code;
                                return ListTile(
                                  leading: BankLogoAvatar(bank: b, size: 40),
                                  title: Text(
                                    b.nameLong,
                                    style: AppTypography.caption3.copyWith(
                                      color: context.palette.textPrimary,
                                    ),
                                  ),
                                  subtitle: Text(
                                    b.nameEn,
                                    style: AppTypography.caption4.copyWith(
                                      color: context.palette.textSecondary,
                                    ),
                                  ),
                                  trailing: isSel
                                      ? Icon(
                                          Icons.check_circle,
                                          color: AppColors.foundationOrange600,
                                        )
                                      : null,
                                  onTap: () => Navigator.pop(ctx, b),
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    if (selected != null) {
      setState(() {
        _selectedBank = selected;
        _bankError = false;
      });
    }
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
            color: context.palette.textPrimary,
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
              color: context.palette.textSecondary,
            ),
            filled: true,
            fillColor: context.palette.surfaceAlt,
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
