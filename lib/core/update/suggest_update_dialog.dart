import 'package:flutter/material.dart';
import 'package:massdrive/core/constants/app_colors.dart';
import 'package:massdrive/core/constants/app_typography.dart';
import 'package:massdrive/core/theme/app_palette.dart';
import 'package:massdrive/core/update/force_update_screen.dart';
import 'package:massdrive/core/update/update_check.dart';
import 'package:massdrive/core/update/update_strings.dart';

/// "A new version is available": update now or later. Never blocks.
Future<void> showSuggestUpdateDialog(
  BuildContext context,
  UpdatePrompt prompt,
) {
  return showDialog<void>(
    context: context,
    builder: (dialogContext) => SuggestUpdateDialog(prompt: prompt),
  );
}

class SuggestUpdateDialog extends StatelessWidget {
  const SuggestUpdateDialog({super.key, required this.prompt});

  final UpdatePrompt prompt;

  @override
  Widget build(BuildContext context) {
    final s = UpdateStrings.of(context);
    final body = prompt.messageFor(thai: s.thai) ?? s.suggestBody;
    final latest = prompt.latestVersion;

    return AlertDialog(
      backgroundColor: context.palette.surface,
      icon: const Icon(
        Icons.system_update_rounded,
        color: AppColors.foundationOrange600,
        size: 40,
      ),
      title: Text(
        s.suggestTitle,
        textAlign: TextAlign.center,
        style: AppTypography.heading5.copyWith(
          color: context.palette.textPrimary,
        ),
      ),
      content: Text(
        latest == null ? body : '$body\n${s.newVersionLabel} $latest',
        textAlign: TextAlign.center,
        style: AppTypography.caption3.copyWith(
          color: context.palette.textSecondary,
          height: 1.5,
        ),
      ),
      actionsAlignment: MainAxisAlignment.center,
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(
            s.later,
            style: AppTypography.caption3.copyWith(
              color: context.palette.textTertiary,
            ),
          ),
        ),
        ElevatedButton.icon(
          onPressed: () {
            Navigator.pop(context);
            startUpdate(prompt);
          },
          icon: const Icon(
            Icons.download_rounded,
            size: 18,
            color: Colors.white,
          ),
          label: Text(
            s.updateButton,
            style: AppTypography.caption3.copyWith(color: Colors.white),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.foundationOrange600,
            elevation: 0,
          ),
        ),
      ],
    );
  }
}
