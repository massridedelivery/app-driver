import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:massdrive/core/constants/app_colors.dart';
import 'package:massdrive/core/constants/app_typography.dart';
import 'package:massdrive/core/theme/app_palette.dart';
import 'package:massdrive/core/utils/baht.dart';
import 'package:massdrive/features/payment/domain/extra_charge.dart';

/// Asks for a toll or another cost as the job's total (prefilled with what
/// the server has). Returns what to send, or null when dismissed.
Future<({double amount, String note})?> showExtraChargeSheet(
  BuildContext context, {
  required ExtraCharge kind,
  double current = 0,
  String? currentNote,
}) {
  return showModalBottomSheet<({double amount, String note})>(
    context: context,
    isScrollControlled: true,
    backgroundColor: context.palette.sheet,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => _ExtraChargeSheet(
      kind: kind,
      current: current,
      currentNote: currentNote,
    ),
  );
}

class _ExtraChargeSheet extends StatefulWidget {
  const _ExtraChargeSheet({
    required this.kind,
    required this.current,
    this.currentNote,
  });

  final ExtraCharge kind;
  final double current;
  final String? currentNote;

  @override
  State<_ExtraChargeSheet> createState() => _ExtraChargeSheetState();
}

class _ExtraChargeSheetState extends State<_ExtraChargeSheet> {
  late final TextEditingController _amount = TextEditingController(
    text: widget.current > 0 ? formatBahtNumber(widget.current) : '',
  );
  late final TextEditingController _note = TextEditingController(
    text: widget.currentNote ?? '',
  );
  String? _error;

  bool get _isOther => widget.kind == ExtraCharge.other;

  @override
  void dispose() {
    _amount.dispose();
    _note.dispose();
    super.dispose();
  }

  void _save() {
    final text = _amount.text.replaceAll(',', '').trim();
    final amount = text.isEmpty ? (_isOther ? 0.0 : null) : double.tryParse(text);
    final error = extraChargeError(
      widget.kind,
      amount: amount,
      note: _note.text,
    );
    if (error != null) {
      setState(() => _error = error);
      return;
    }
    Navigator.of(context).pop((amount: amount!, note: _note.text.trim()));
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final title = _isOther ? 'ค่าอื่นๆ' : 'ค่าทางด่วน';
    InputDecoration field(String label, {String? hint, String? prefix}) =>
        InputDecoration(
          labelText: label,
          hintText: hint,
          prefixText: prefix,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        );

    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        12,
        20,
        16 +
            MediaQuery.viewInsetsOf(context).bottom +
            MediaQuery.viewPaddingOf(context).bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: p.border,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: AppTypography.heading5.copyWith(color: p.textPrimary),
          ),
          const SizedBox(height: 4),
          Text(
            _isOther
                ? 'ยอดรวมของงานนี้ ไม่ใช่ยอดที่บวกเพิ่ม · ใส่ 0 เพื่อล้าง · สูงสุด ฿500'
                : 'ยอดรวมของงานนี้ ไม่ใช่ยอดที่บวกเพิ่ม · สูงสุด ฿500',
            style: AppTypography.caption4.copyWith(color: p.textSecondary),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _amount,
            autofocus: true,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
            ],
            style: AppTypography.body1.copyWith(color: p.textPrimary),
            decoration: field('จำนวนเงิน', prefix: '฿ '),
            onChanged: (_) => setState(() => _error = null),
          ),
          if (_isOther) ...[
            const SizedBox(height: 12),
            TextField(
              controller: _note,
              maxLength: 200,
              style: AppTypography.body1.copyWith(color: p.textPrimary),
              decoration: field('เป็นค่าอะไร', hint: 'เช่น ค่าจอดรถ'),
              onChanged: (_) => setState(() => _error = null),
            ),
          ],
          if (_error != null) ...[
            const SizedBox(height: 4),
            Text(
              _error!,
              style: AppTypography.caption3.copyWith(
                color: AppColors.semanticErrorFgHigh,
              ),
            ),
          ],
          const SizedBox(height: 16),
          SizedBox(
            height: 52,
            child: FilledButton(
              onPressed: _save,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.foundationGreen700,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(28),
                ),
              ),
              child: Text(
                'บันทึก',
                style: AppTypography.heading6.copyWith(color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
