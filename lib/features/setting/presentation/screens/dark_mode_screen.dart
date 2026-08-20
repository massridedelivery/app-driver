import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:massdrive/core/constants/app_typography.dart';
import 'package:massdrive/core/theme/theme_controller.dart';

/// "โหมดสี" — a day/night chooser for the app theme. Theme-aware (reads the
/// active ColorScheme) so it renders correctly in both light and dark.
class DarkModeScreen extends ConsumerWidget {
  const DarkModeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = ref.watch(darkModeProvider);
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'โหมดสี',
          style: AppTypography.heading5.copyWith(color: cs.onSurface),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          children: [
            Text(
              'โหมดสี',
              style: AppTypography.heading6.copyWith(color: cs.onSurface),
            ),
            const SizedBox(height: 8),
            Text(
              'เลือกโหมดแสดงผลของแอป โหมดกลางคืนช่วยถนอมสายตาและอายุแบตเตอรี่ '
              'ให้นานยิ่งขึ้น และแผนที่จะปรับเป็นสีเข้มด้วย',
              style: AppTypography.caption4.copyWith(
                color: cs.onSurfaceVariant,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            _OptionRow(
              label: 'โหมดกลางคืน',
              selected: isDark,
              onTap: () => ref.read(darkModeProvider.notifier).setEnabled(true),
            ),
            Divider(color: cs.outlineVariant, height: 1),
            _OptionRow(
              label: 'โหมดกลางวัน',
              selected: !isDark,
              onTap: () => ref.read(darkModeProvider.notifier).setEnabled(false),
            ),
            Divider(color: cs.outlineVariant, height: 1),
          ],
        ),
      ),
    );
  }
}

class _OptionRow extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _OptionRow({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 18),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: AppTypography.body1.copyWith(color: cs.onSurface),
              ),
            ),
            Icon(
              selected
                  ? Icons.radio_button_checked
                  : Icons.radio_button_unchecked,
              color: selected ? cs.primary : cs.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }
}
