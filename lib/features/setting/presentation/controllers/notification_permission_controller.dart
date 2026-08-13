import 'package:massdrive/core/services/push_token_registrar.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'notification_permission_controller.g.dart';

/// Current OS notification-permission status, for the Settings screen's
/// notification tile. Re-checked on demand via [refresh] — the app resuming
/// from the system Settings screen (after the driver toggles it there) is
/// the only way this can change while the app is alive, since neither
/// platform lets an app query this reactively.
@riverpod
class NotificationPermissionController extends _$NotificationPermissionController {
  @override
  Future<PermissionStatus> build() {
    return Permission.notification.status;
  }

  /// Re-read the status, and register for push if the driver just granted it.
  ///
  /// The registration retry matters as much as the status: while permission
  /// was denied the registrar bailed out without ever getting a token, and
  /// nothing else would drive it again until the next cold start — so without
  /// this the driver turns notifications on and still receives nothing.
  Future<void> refresh() async {
    state = await AsyncValue.guard(() => Permission.notification.status);
    if (state.value?.isGranted ?? false) {
      await PushTokenRegistrar.instance.retry();
    }
  }
}
