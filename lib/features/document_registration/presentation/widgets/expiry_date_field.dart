import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:massdrive/core/constants/app_typography.dart';
import 'package:massdrive/core/theme/brand_colors.dart';
import 'package:massdrive/core/utils/thai_date.dart';

import 'registration_ui.dart';

/// Optional "วันหมดอายุ" for a document that expires. Shows the date in the
/// Buddhist era; [onChanged] gets a plain Gregorian date (null when cleared),
/// which the API sends as `YYYY-MM-DD`.
class ExpiryDateField extends StatelessWidget {
  const ExpiryDateField({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final DateTime? value;
  final ValueChanged<DateTime?> onChanged;

  @override
  Widget build(BuildContext context) {
    final brand = context.brand;
    final date = value;
    return RegistrationField(
      label: 'วันหมดอายุ (ไม่บังคับ)',
      helper: 'ระบบจะเตือนก่อนเอกสารหมดอายุ',
      child: RegistrationFieldBox(
        onTap: () async {
          FocusManager.instance.primaryFocus?.unfocus();
          final picked = await showExpiryDatePicker(context, initial: date);
          if (picked != null) onChanged(picked);
        },
        child: Row(
          children: [
            Expanded(
              child: Text(
                date != null ? formatThaiDate(date) : 'เลือกวันหมดอายุ',
                style: date != null
                    ? registrationInputStyle(context)
                    : AppTypography.caption4.copyWith(color: brand.text3),
              ),
            ),
            if (date != null)
              GestureDetector(
                key: const ValueKey('expiry-clear'),
                behavior: HitTestBehavior.opaque,
                onTap: () => onChanged(null),
                child: Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Icon(
                    Icons.close_rounded,
                    size: 18,
                    color: brand.text2,
                  ),
                ),
              ),
            Icon(Icons.event_rounded, size: 18, color: brand.text2),
          ],
        ),
      ),
    );
  }
}

/// Years the picker offers: last year (a card that just ran out) up to 20
/// years ahead, inside the 2000–2100 the backend accepts.
List<int> expiryPickerYears(DateTime today) => [
  for (var y = today.year - 1; y <= (today.year + 20).clamp(2000, 2100); y++)
    if (y >= 2000) y,
];

/// Day / Thai month / Buddhist-era year wheels. Null when dismissed.
Future<DateTime?> showExpiryDatePicker(
  BuildContext context, {
  DateTime? initial,
}) async {
  final today = DateTime.now();
  final years = expiryPickerYears(today);
  final start = initial ?? DateTime(today.year + 1, today.month, today.day);
  var year = start.year.clamp(years.first, years.last);
  var month = start.month;
  var day = start.day;

  final yearCtrl = FixedExtentScrollController(
    initialItem: years.indexOf(year),
  );
  final monthCtrl = FixedExtentScrollController(initialItem: month - 1);
  final dayCtrl = FixedExtentScrollController(initialItem: day - 1);

  int daysIn(int y, int m) => DateTime(y, m + 1, 0).day;

  final picked = await showModalBottomSheet<DateTime>(
    context: context,
    // Sized to its content: the default 9/16 cap clips the wheels on a
    // small phone.
    isScrollControlled: true,
    backgroundColor: context.brand.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (sheetContext) {
      return StatefulBuilder(
        builder: (ctx, setSheet) {
          final maxDay = daysIn(year, month);
          if (day > maxDay) {
            day = maxDay;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (dayCtrl.hasClients) dayCtrl.jumpToItem(day - 1);
            });
          }
          final candidate = DateTime(year, month, day);

          Widget wheel({
            required FixedExtentScrollController controller,
            required int count,
            required String Function(int) label,
            required ValueChanged<int> onChanged,
            int flex = 1,
          }) {
            return Expanded(
              flex: flex,
              child: CupertinoPicker(
                scrollController: controller,
                itemExtent: 40,
                onSelectedItemChanged: (i) => setSheet(() => onChanged(i)),
                children: [
                  for (var i = 0; i < count; i++)
                    Center(
                      child: Text(
                        label(i),
                        style: AppTypography.label2.copyWith(
                          color: ctx.brand.text1,
                        ),
                      ),
                    ),
                ],
              ),
            );
          }

          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'วันหมดอายุ',
                    style: AppTypography.heading5.copyWith(
                      color: ctx.brand.text1,
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 200,
                    child: Row(
                      children: [
                        wheel(
                          controller: dayCtrl,
                          count: maxDay,
                          label: (i) => '${i + 1}',
                          onChanged: (i) => day = i + 1,
                        ),
                        wheel(
                          controller: monthCtrl,
                          count: 12,
                          label: (i) => thaiMonthsFull[i],
                          onChanged: (i) => month = i + 1,
                          flex: 2,
                        ),
                        wheel(
                          controller: yearCtrl,
                          count: years.length,
                          label: (i) => '${years[i] + 543}',
                          onChanged: (i) => year = years[i],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    formatThaiDate(candidate),
                    style: AppTypography.caption3.copyWith(
                      color: ctx.brand.text2,
                    ),
                  ),
                  const SizedBox(height: 16),
                  RegistrationPrimaryButton(
                    label: 'ตกลง',
                    onPressed: () => Navigator.pop(ctx, candidate),
                  ),
                ],
              ),
            ),
          );
        },
      );
    },
  );

  yearCtrl.dispose();
  monthCtrl.dispose();
  dayCtrl.dispose();
  return picked;
}
