// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'notification_permission_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Current OS notification-permission status, for the Settings screen's
/// notification tile. Re-checked on demand via [refresh] — the app resuming
/// from the system Settings screen (after the driver toggles it there) is
/// the only way this can change while the app is alive, since neither
/// platform lets an app query this reactively.

@ProviderFor(NotificationPermissionController)
const notificationPermissionControllerProvider =
    NotificationPermissionControllerProvider._();

/// Current OS notification-permission status, for the Settings screen's
/// notification tile. Re-checked on demand via [refresh] — the app resuming
/// from the system Settings screen (after the driver toggles it there) is
/// the only way this can change while the app is alive, since neither
/// platform lets an app query this reactively.
final class NotificationPermissionControllerProvider
    extends
        $AsyncNotifierProvider<
          NotificationPermissionController,
          PermissionStatus
        > {
  /// Current OS notification-permission status, for the Settings screen's
  /// notification tile. Re-checked on demand via [refresh] — the app resuming
  /// from the system Settings screen (after the driver toggles it there) is
  /// the only way this can change while the app is alive, since neither
  /// platform lets an app query this reactively.
  const NotificationPermissionControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'notificationPermissionControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$notificationPermissionControllerHash();

  @$internal
  @override
  NotificationPermissionController create() =>
      NotificationPermissionController();
}

String _$notificationPermissionControllerHash() =>
    r'96a942deefbcc127babf3f060fa1958c876aa524';

/// Current OS notification-permission status, for the Settings screen's
/// notification tile. Re-checked on demand via [refresh] — the app resuming
/// from the system Settings screen (after the driver toggles it there) is
/// the only way this can change while the app is alive, since neither
/// platform lets an app query this reactively.

abstract class _$NotificationPermissionController
    extends $AsyncNotifier<PermissionStatus> {
  FutureOr<PermissionStatus> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref =
        this.ref as $Ref<AsyncValue<PermissionStatus>, PermissionStatus>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<PermissionStatus>, PermissionStatus>,
              AsyncValue<PermissionStatus>,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}
