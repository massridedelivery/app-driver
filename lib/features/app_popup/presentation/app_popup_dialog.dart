import 'package:flutter/material.dart';
import 'package:massdrive/core/constants/app_colors.dart';
import 'package:massdrive/core/constants/app_typography.dart';
import 'package:massdrive/features/app_popup/domain/app_popup.dart';

/// The full-image card. The dimmed backdrop and Android back close it like
/// ✕, with the checkbox as it stands.
Future<PopupOutcome> showAppPopup(BuildContext context, AppPopup popup) async {
  final dontShow = ValueNotifier(false);
  try {
    final result = await showDialog<PopupOutcome>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.6),
      builder: (_) => AppPopupCard(popup: popup, dontShowAgain: dontShow),
    );
    return result ?? PopupOutcome(dontShowAgain: dontShow.value);
  } finally {
    dontShow.dispose();
  }
}

class AppPopupCard extends StatelessWidget {
  const AppPopupCard({
    super.key,
    required this.popup,
    required this.dontShowAgain,
  });

  final AppPopup popup;
  final ValueNotifier<bool> dontShowAgain;

  void _close(BuildContext context, {bool tapped = false}) => Navigator.of(
    context,
  ).pop(PopupOutcome(dontShowAgain: dontShowAgain.value, tapped: tapped));

  @override
  Widget build(BuildContext context) {
    final action = popup.action;
    final buttonText = action?.buttonText;
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 380),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Flexible(
              child: Stack(
                children: [
                  GestureDetector(
                    onTap: action == null
                        ? null
                        : () => _close(context, tapped: true),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: AspectRatio(
                        aspectRatio: 3 / 4,
                        child: Image.network(
                          popup.imageUrl,
                          fit: BoxFit.cover,
                          semanticLabel: 'ป๊อปอัปโปรโมชัน',
                          errorBuilder: (_, _, _) =>
                              const ColoredBox(color: Colors.black12),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Material(
                      color: Colors.black.withValues(alpha: 0.45),
                      shape: const CircleBorder(),
                      child: IconButton(
                        tooltip: 'ปิด',
                        visualDensity: VisualDensity.compact,
                        icon: const Icon(Icons.close, color: Colors.white),
                        onPressed: () => _close(context),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (buttonText != null) ...[
              const SizedBox(height: 12),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.semanticSupportMintBgHigh,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () => _close(context, tapped: true),
                child: Text(
                  buttonText,
                  style: AppTypography.label2.copyWith(color: Colors.white),
                ),
              ),
            ],
            const SizedBox(height: 8),
            ValueListenableBuilder<bool>(
              valueListenable: dontShowAgain,
              builder: (_, checked, _) => InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: () => dontShowAgain.value = !checked,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 24,
                        height: 24,
                        child: Checkbox(
                          value: checked,
                          onChanged: (v) => dontShowAgain.value = v ?? false,
                          side: const BorderSide(
                            color: Colors.white,
                            width: 1.5,
                          ),
                          checkColor: Colors.white,
                          activeColor: AppColors.semanticSupportMintBgHigh,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'ไม่แสดงหน้านี้ในครั้งถัดไป',
                        style: AppTypography.caption4.copyWith(
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
