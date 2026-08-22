import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:massdrive/common/widgets/appbar/base_appbar.dart';
import 'package:massdrive/common/widgets/image_source_sheet.dart';
import 'package:massdrive/core/constants/app_colors.dart';
import 'package:massdrive/core/theme/app_palette.dart';
import 'package:massdrive/core/constants/app_typography.dart';
import 'package:massdrive/features/income/presentation/controllers/wallet_controller.dart';

class SettleDebtSlipFormScreen extends ConsumerStatefulWidget {
  final String intentId;
  final double amount;
  final Map<String, dynamic> bankDetails;

  const SettleDebtSlipFormScreen({
    super.key,
    required this.intentId,
    required this.amount,
    required this.bankDetails,
  });

  @override
  ConsumerState<SettleDebtSlipFormScreen> createState() => _SettleDebtSlipFormScreenState();
}

class _SettleDebtSlipFormScreenState extends ConsumerState<SettleDebtSlipFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _bankAccountNameController = TextEditingController();

  DateTime _transferAt = DateTime.now();
  File? _selectedImage;
  final ImagePicker _picker = ImagePicker();
  bool _isSubmitting = false;
  Map<String, dynamic>? _result;

  @override
  void dispose() {
    _bankAccountNameController.dispose();
    super.dispose();
  }

  /// Ask camera vs gallery, then pick. A transfer slip is usually a banking-app
  /// screenshot (gallery), but a paper counter slip can be photographed.
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

  Future<void> _selectDateTime() async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _transferAt,
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now().add(const Duration(days: 1)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: (Theme.of(context).brightness == Brightness.dark ? const ColorScheme.dark() : const ColorScheme.light()).copyWith(
              primary: AppColors.foundationOrange600,
              onPrimary: Colors.white,
              surface: context.palette.bg,
              onSurface: context.palette.textPrimary,
            ),
            dialogTheme: DialogThemeData(
              backgroundColor: context.palette.bg,
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedDate == null || !mounted) return;

    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_transferAt),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: (Theme.of(context).brightness == Brightness.dark ? const ColorScheme.dark() : const ColorScheme.light()).copyWith(
              primary: AppColors.foundationOrange600,
              onPrimary: Colors.white,
              surface: context.palette.bg,
              onSurface: context.palette.textPrimary,
            ),
            dialogTheme: DialogThemeData(
              backgroundColor: context.palette.bg,
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedTime == null) return;

    setState(() {
      _transferAt = DateTime(
        pickedDate.year,
        pickedDate.month,
        pickedDate.day,
        pickedTime.hour,
        pickedTime.minute,
      );
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'กรุณาอัปโหลดรูปภาพสลิปการโอนเงิน',
            style: AppTypography.label2.copyWith(color: Colors.white),
          ),
          backgroundColor: AppColors.semanticErrorBgHigh,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    final bankAccountName = _bankAccountNameController.text.trim();

    final result = await ref.read(walletControllerProvider.notifier).submitSettlementSlip(
          intentId: widget.intentId,
          slipFile: _selectedImage!,
          bankAccountName: bankAccountName,
          transferAt: _transferAt,
        );

    if (!mounted) return;
    setState(() {
      _isSubmitting = false;
      _result = result;
    });

    if (result == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'ส่งข้อมูลไม่สำเร็จ กรุณาลองใหม่อีกครั้ง',
            style: AppTypography.label2.copyWith(color: Colors.white),
          ),
          backgroundColor: AppColors.semanticErrorBgHigh,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_result != null) {
      return _buildSuccessScreen(_result!);
    }

    final bankName = widget.bankDetails['bank_name']?.toString() ?? 'ธนาคารกสิกรไทย (KBANK)';
    final accountNumber = widget.bankDetails['account_number']?.toString() ?? '012-3-45678-9';
    final accountName = widget.bankDetails['account_name']?.toString() ?? 'บริษัท แมสไดรฟ์ จำกัด';

    return Scaffold(
      appBar: CommonAppBar(titleText: 'แจ้งยอดโอนเงิน', showLeftIcon: true),
      backgroundColor: context.palette.bg,
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              // Company Bank Info Box
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: context.palette.surfaceAlt,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.foundationOrange700.withValues(alpha: 0.3),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'โอนเงินเพื่อชำระหนี้ค้างชำระ',
                      style: AppTypography.caption3.copyWith(
                        color: AppColors.foundationOrange500,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildBankInfoRow('ธนาคาร:', bankName),
                    _buildBankInfoRow('เลขที่บัญชี:', accountNumber),
                    _buildBankInfoRow('ชื่อบัญชี:', accountName),
                    _buildBankInfoRow('จำนวนเงิน:', '฿${widget.amount.toStringAsFixed(0)}'),
                    _buildBankInfoRow('หมายเลขรายการ:', widget.intentId),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Image Upload Container
              Text(
                'รูปภาพสลิปการโอนเงิน',
                style: AppTypography.caption3.copyWith(
                  color: context.palette.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              GestureDetector(
                onTap: _chooseAndPickImage,
                child: Container(
                  height: 180,
                  decoration: BoxDecoration(
                    color: context.palette.surfaceAlt,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: context.palette.border,
                      style: BorderStyle.solid,
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
                              Icons.add_photo_alternate_outlined,
                              size: 48,
                              color: AppColors.foundationOrange500,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'แตะเพื่อเลือกรูปภาพสลิป',
                              style: AppTypography.caption3.copyWith(
                                color: context.palette.textSecondary,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 24),

              // Bank Account Name
              Text(
                'ชื่อบัญชีผู้โอน (ภาษาอังกฤษ หรือ ภาษาไทย)',
                style: AppTypography.caption3.copyWith(
                  color: context.palette.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _bankAccountNameController,
                style: AppTypography.body1.copyWith(color: context.palette.textPrimary),
                decoration: InputDecoration(
                  hintText: 'เช่น Nutchaphut Doe',
                  hintStyle: AppTypography.body1.copyWith(
                    color: context.palette.textTertiary,
                  ),
                  filled: true,
                  fillColor: context.palette.surfaceAlt,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 18,
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'กรุณากรอกชื่อบัญชีผู้โอน';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // Transfer date & time
              Text(
                'วันและเวลาที่โอน',
                style: AppTypography.caption3.copyWith(
                  color: context.palette.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              GestureDetector(
                onTap: _selectDateTime,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 18,
                  ),
                  decoration: BoxDecoration(
                    color: context.palette.surfaceAlt,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        DateFormat('dd/MM/yyyy HH:mm').format(_transferAt),
                        style: AppTypography.body1.copyWith(color: context.palette.textPrimary),
                      ),
                      const Icon(
                        Icons.calendar_today_rounded,
                        color: AppColors.foundationOrange500,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 40),

              // Action Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.foundationOrange600,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28),
                    ),
                    elevation: 0,
                  ),
                  child: _isSubmitting
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(
                          'ส่งหลักฐานการชำระเงิน',
                          style: AppTypography.heading5.copyWith(
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

  Widget _buildBankInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: AppTypography.caption4.copyWith(
                color: context.palette.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: AppTypography.caption3.copyWith(
                color: context.palette.textPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessScreen(Map<String, dynamic> result) {
    final intentId = result['intent_id']?.toString() ?? widget.intentId;
    final status = result['status']?.toString() ?? 'PENDING_REVIEW';
    final message = result['message']?.toString() ?? 'ส่งหลักฐานการชำระเงินสำเร็จแล้ว อยู่ระหว่างการตรวจสอบโดยผู้ดูแลระบบ';

    return Scaffold(
      appBar: CommonAppBar(titleText: 'ผลการส่งหลักฐาน', showLeftIcon: false),
      backgroundColor: context.palette.bg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),
              const CircleAvatar(
                radius: 40,
                backgroundColor: AppColors.foundationGreen100,
                child: Icon(
                  Icons.check_circle_rounded,
                  size: 60,
                  color: AppColors.foundationGreen600,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'ส่งหลักฐานสำเร็จ',
                style: AppTypography.heading3.copyWith(color: context.palette.textPrimary),
              ),
              const SizedBox(height: 12),
              Text(
                message,
                textAlign: TextAlign.center,
                style: AppTypography.body1.copyWith(
                  color: context.palette.textSecondary,
                ),
              ),
              const SizedBox(height: 32),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: context.palette.surfaceAlt,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'เลขที่รายการ:',
                          style: AppTypography.body2.copyWith(
                            color: context.palette.textSecondary,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            intentId,
                            textAlign: TextAlign.end,
                            style: AppTypography.body1.copyWith(
                              color: context.palette.textPrimary,
                              fontWeight: FontWeight.bold,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    Divider(color: context.palette.surfaceAlt, height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'สถานะ:',
                          style: AppTypography.body2.copyWith(
                            color: context.palette.textSecondary,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.semanticWarningBgHigh.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            status,
                            style: AppTypography.caption3.copyWith(
                              color: AppColors.semanticWarningBgHigh,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () {
                    // Navigate back to credit wallet screen
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.foundationOrange600,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    'กลับหน้ากระเป๋าเงิน',
                    style: AppTypography.heading5.copyWith(color: Colors.white),
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
