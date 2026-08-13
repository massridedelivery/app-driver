import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:massdrive/core/services/push_token_registrar.dart';
import 'package:permission_handler/permission_handler.dart';

/// Whether the OS currently lets the app post notifications.
///
/// A driver who declines the permission prompt silently stops receiving job
/// alerts — the app can't re-prompt after a denial, only send them to system
/// settings. The setting screen watches this to show that nudge.
class NotificationPermissionController extends AsyncNotifier<bool> {
  @override
  Future<bool> build() => _read();

  Future<bool> _read() async {
    try {
      return await Permission.notification.isGranted;
    } catch (e) {
      // Platform channel unavailable (e.g. an unsupported platform). Assume
      // granted rather than nag the driver about something we can't verify.
      debugPrint('Notification permission check failed: $e');
      return true;
    }
  }

  /// Re-read the status — call after returning from system settings.
  ///
  /// Registration is retried on the way up: the driver was push-blind until
  /// now, so the startup attempt bailed out before it ever got a token.
  Future<void> refresh() async {
    final granted = await _read();
    state = AsyncData(granted);
    if (granted) {
      await PushTokenRegistrar.instance.retry();
    }
  }

  /// Open the app's OS settings page, where notifications can be re-enabled.
  Future<void> openSettings() => openAppSettings();
}

final notificationPermissionProvider =
    AsyncNotifierProvider<NotificationPermissionController, bool>(
      NotificationPermissionController.new,
    );
