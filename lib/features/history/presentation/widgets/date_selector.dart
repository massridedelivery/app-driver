import 'package:flutter/material.dart';
import 'package:massdrive/core/constants/app_colors.dart';
import 'package:massdrive/core/constants/app_typography.dart';
import 'package:massdrive/core/theme/app_palette.dart';

/// Horizontal date filter for the history list: an "ทั้งหมด" (all) chip plus the
/// most recent days. Selecting a day filters the list to that day; "ทั้งหมด"
/// clears the date filter. [selectedDate] null = all.
class DateSelector extends StatelessWidget {
  final DateTime? selectedDate;
  final ValueChanged<DateTime?> onSelected;

  /// How many recent days to offer.
  final int dayCount;

  const DateSelector({
    super.key,
    required this.selectedDate,
    required this.onSelected,
    this.dayCount = 14,
  });

  static const _weekdayTh = ['จ', 'อ', 'พ', 'พฤ', 'ศ', 'ส', 'อา'];

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final days = List.generate(
      dayCount,
      (i) => DateTime(today.year, today.month, today.day)
          .subtract(Duration(days: i)),
    );

    return SizedBox(
      height: 72,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: days.length + 1,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          if (index == 0) {
            return _Chip(
              top: '',
              label: 'ทั้งหมด',
              selected: selectedDate == null,
              onTap: () => onSelected(null),
            );
          }
          final day = days[index - 1];
          return _Chip(
            top: _weekdayTh[day.weekday - 1],
            label: '${day.day}',
            selected: selectedDate != null && _sameDay(selectedDate!, day),
            onTap: () => onSelected(day),
          );
        },
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String top;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _Chip({
    required this.top,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bg = selected
        ? AppColors.foundationOrange500
        : context.palette.surfaceAlt;
    final fg = selected ? Colors.white : context.palette.textSecondary;
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Container(
        width: top.isEmpty ? 64 : 52,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (top.isNotEmpty)
              Text(
                top,
                style: AppTypography.caption5.copyWith(
                  color: fg.withValues(alpha: 0.85),
                ),
              ),
            if (top.isNotEmpty) const SizedBox(height: 2),
            Text(
              label,
              style: AppTypography.label2.copyWith(
                color: fg,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
