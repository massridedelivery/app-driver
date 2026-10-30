import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:in_app_update/in_app_update.dart';
import 'package:massdrive/core/constants/app_colors.dart';
import 'package:massdrive/core/constants/app_typography.dart';
import 'package:massdrive/core/theme/app_palette.dart';
import 'package:massdrive/core/update/update_check.dart';
import 'package:massdrive/core/update/update_strings.dart';
import 'package:url_launcher/url_launcher.dart';

/// Starts the update: Play's own full-screen update on Android when it is
/// allowed, else the store page. False if neither could open.
Future<bool> startUpdate(UpdatePrompt prompt) async {
  if (prompt.playImmediate && !kIsWeb && Platform.isAndroid) {
    try {
      final result = await InAppUpdate.performImmediateUpdate();
      if (result == AppUpdateResult.success) return true;
    } catch (_) {
      // Fall through to the store page.
    }
  }
  try {
    return await launchUrl(
      Uri.parse(prompt.storeUrl),
      mode: LaunchMode.externalApplication,
    );
  } catch (_) {
    return false;
  }
}

/// Blocks the app while the backend says this version must update. There is
/// no way past it except updating; the router keeps every route here and the
/// back button does nothing.
class ForceUpdateScreen extends StatelessWidget {
  const ForceUpdateScreen({super.key, this.prompt});

  /// Defaults to [UpdateCheck.forced]; set by tests.
  final UpdatePrompt? prompt;

  Future<void> _update(BuildContext context, UpdatePrompt prompt) async {
    final s = UpdateStrings.of(context);
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (await startUpdate(prompt)) return;
    messenger?.showSnackBar(SnackBar(content: Text(s.openStoreFailed)));
  }

  @override
  Widget build(BuildContext context) {
    final s = UpdateStrings.of(context);
    final p = prompt ?? UpdateCheck.instance.forced;
    final message = p?.messageFor(thai: s.thai) ?? s.forceBody;

    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: context.palette.bg,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
            child: Column(
              children: [
                const Spacer(),
                Container(
                  width: 96,
                  height: 96,
                  decoration: const BoxDecoration(
                    color: AppColors.foundationOrange100,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.system_update_rounded,
                    size: 48,
                    color: AppColors.foundationOrange600,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  s.forceTitle,
                  textAlign: TextAlign.center,
                  style: AppTypography.heading3.copyWith(
                    color: context.palette.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: AppTypography.caption3.copyWith(
                    color: context.palette.textSecondary,
                    height: 1.6,
                  ),
                ),
                if (p?.latestVersion case final latest?) ...[
                  const SizedBox(height: 20),
                  Text(
                    '${s.newVersionLabel} $latest',
                    textAlign: TextAlign.center,
                    style: AppTypography.label2.copyWith(
                      color: context.palette.textPrimary,
                    ),
                  ),
                ],
                const Spacer(),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton.icon(
                    onPressed: p == null ? null : () => _update(context, p),
                    icon: const Icon(
                      Icons.download_rounded,
                      color: Colors.white,
                    ),
                    label: Text(
                      s.updateButton,
                      style: AppTypography.label1.copyWith(color: Colors.white),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.foundationOrange600,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(28),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
