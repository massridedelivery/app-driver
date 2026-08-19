import 'package:flutter/material.dart';
import 'package:massdrive/core/constants/app_colors.dart';
import 'package:massdrive/core/constants/app_spacing.dart';
import 'package:massdrive/core/constants/app_typography.dart';

/// Shared accept/decline footer for every incoming-job offer sheet (ride, food,
/// messenger) so all three share one flow: an auto-accept/auto-cancel caption,
/// a depleting progress bar, and the large cancel/accept pills — with the
/// remaining seconds shown on whichever action fires when the window closes.
///
/// Purely presentational: the parent owns the countdown timer and the
/// accept/decline callbacks. Green accept + red cancel match the ride flow.
class JobOfferActionBar extends StatelessWidget {
  /// Seconds left in the accept window; drives the caption, bar and countdown.
  final int remaining;

  /// Full window length, so the progress bar can render a 0..1 fraction.
  final int totalSeconds;

  /// When true, the window closing accepts the job; otherwise it cancels.
  final bool autoAccept;

  final VoidCallback onAccept;
  final VoidCallback onDecline;

  /// Disables both buttons and shows a spinner on accept (network in flight).
  final bool isSubmitting;

  const JobOfferActionBar({
    super.key,
    required this.remaining,
    required this.totalSeconds,
    required this.autoAccept,
    required this.onAccept,
    required this.onDecline,
    this.isSubmitting = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // What happens when the countdown hits 0, driven by the auto-accept
        // preference.
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              autoAccept ? Icons.bolt : Icons.timer_outlined,
              color: autoAccept
                  ? AppColors.semanticSuccessBgHigh
                  : AppColors.foundationAlphaWhite500,
              size: 16,
            ),
            const SizedBox(width: 4),
            Text(
              autoAccept
                  ? 'รับงานอัตโนมัติใน $remaining วินาที'
                  : 'ยกเลิกอัตโนมัติใน $remaining วินาที',
              style: AppTypography.caption4.copyWith(
                color: AppColors.foundationAlphaWhite500,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.s2),

        // Accept window progress bar — depletes as the countdown runs.
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: totalSeconds == 0 ? 0 : remaining / totalSeconds,
            minHeight: 4,
            backgroundColor: Colors.white12,
            valueColor: AlwaysStoppedAnimation<Color>(
              remaining <= 5
                  ? AppColors.semanticSupportRedBgHigh
                  : AppColors.semanticSuccessBgHigh,
            ),
          ),
        ),

        const SizedBox(height: AppSpacing.s3),

        // Action buttons — large, thumb-friendly pills.
        Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 60,
                child: ElevatedButton(
                  onPressed: isSubmitting ? null : onDecline,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.semanticSupportRedBgHigh,
                    disabledBackgroundColor: AppColors.semanticSupportRedBgHigh,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppSpacing.s5),
                    ),
                  ),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      // Countdown sits on whichever action fires at 0: the cancel
                      // button when auto-accept is off. Keep it on one line — the
                      // narrow cancel button otherwise wraps onto two lines.
                      autoAccept ? 'ยกเลิก' : 'ยกเลิก ($remaining)',
                      maxLines: 1,
                      softWrap: false,
                      style: AppTypography.heading5.copyWith(
                        color: AppColors.semanticGrayNeutralFgWhite,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.s3),
            Expanded(
              flex: 2,
              child: SizedBox(
                height: 60,
                child: ElevatedButton(
                  onPressed: isSubmitting ? null : onAccept,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.semanticSuccessBgHigh,
                    disabledBackgroundColor: AppColors.semanticSuccessBgHigh,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppSpacing.s5),
                    ),
                  ),
                  child: isSubmitting
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            // Countdown shows here only when auto-accept is on
                            // (this is the action that fires at 0).
                            autoAccept ? 'รับงาน ($remaining)' : 'รับงาน',
                            maxLines: 1,
                            softWrap: false,
                            style: AppTypography.heading5.copyWith(
                              color: AppColors.semanticGrayNeutralFgWhite,
                            ),
                          ),
                        ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
