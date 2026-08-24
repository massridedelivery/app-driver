import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get_storage/get_storage.dart';
import 'package:permission_handler/permission_handler.dart' as ph;
import 'package:massdrive/core/constants/app_routes.dart';
import 'package:massdrive/core/services/fcm_debug_log.dart';
import 'package:massdrive/router/app_routes.dart';

/// Requests notification permission and returns the resulting iOS/Firebase
/// [AuthorizationStatus] name for display. Shared by app startup and the FCM
/// debug screen's manual "request permission" action.
///
/// On Android 13+ (API 33+), POST_NOTIFICATIONS is a runtime permission that
/// FirebaseMessaging.requestPermission() alone does not reliably prompt for
/// on every plugin/OS combination — a silent no-op there leaves the OS
/// blocking every notification with no dialog ever shown, and the app has no
/// way to ask again later. permission_handler's request() is the version
/// Android actually guarantees shows the system dialog when the permission
/// has never been decided.
Future<String> requestNotificationPermission() async {
  if (defaultTargetPlatform == TargetPlatform.android) {
    final status = await ph.Permission.notification.status;
    FcmDebugLog.log('Android notification permission (before): $status');
    if (!status.isGranted) {
      final requested = await ph.Permission.notification.request();
      FcmDebugLog.log('Android notification permission (after request): $requested');
    }
  }

  final settings = await FirebaseMessaging.instance.requestPermission(
    alert: true,
    badge: true,
    sound: true,
  );
  FcmDebugLog.setPermissionStatus(settings.authorizationStatus.name);
  FcmDebugLog.log('Permission: ${settings.authorizationStatus.name}');
  return settings.authorizationStatus.name;
}

/// Generic channel for ordinary notifications (system-drawn by FCM in the
/// background). The id MUST match `default_notification_channel_id` in
/// AndroidManifest.xml.
const AndroidNotificationChannel _androidChannel = AndroidNotificationChannel(
  'high_importance_channel',
  'Notifications',
  description: 'ใช้สำหรับการแจ้งเตือนสำคัญ',
  importance: Importance.high,
);

/// Dedicated channel for job offers — loud custom sound (res/raw/job_alert),
/// max importance, vibration, and heads-up (full-screen) so a driver notices a
/// new job like Grab/LineMan. The channel id is versioned because a channel's
/// sound is immutable once created: bump `_vN` to roll out a new sound.
const AndroidNotificationChannel _jobChannel = AndroidNotificationChannel(
  'job_offer_channel_v2',
  'งานเข้าใหม่',
  description: 'แจ้งเตือนเมื่อมีงานเข้าใหม่ (เสียงดังพิเศษ)',
  importance: Importance.max,
  sound: RawResourceAndroidNotificationSound('job_alert'),
  playSound: true,
  enableVibration: true,
  audioAttributesUsage: AudioAttributesUsage.alarm,
);

final FlutterLocalNotificationsPlugin _localNotifications =
    FlutterLocalNotificationsPlugin();

/// Routes that represent a new job/ride/messenger *offer* — these ring with
/// the loud, custom-sound job-alert channel. Other routes (e.g. `/job-live`,
/// already-accepted work) use the default channel/sound. Mirrors the "Allowed
/// route values" table in fcm_push_notification_spec.md.
const _jobOfferRoutes = {AppRoutes.incomingJobNamedPage, '/messenger-offer'};

/// True when a push is a job/offer that should ring with the loud alert.
/// `data.route` is the only data key the backend contract guarantees (see
/// fcm_push_notification_spec.md), so detection keys off that.
bool _isJobOffer(RemoteMessage message) {
  return _jobOfferRoutes.contains(message.data['route']);
}

/// Builds the loud job-offer AndroidNotificationDetails.
AndroidNotificationDetails _jobAndroidDetails() {
  return AndroidNotificationDetails(
    _jobChannel.id,
    _jobChannel.name,
    channelDescription: _jobChannel.description,
    icon: 'ic_stat_notification',
    importance: Importance.max,
    priority: Priority.max,
    category: AndroidNotificationCategory.call,
    fullScreenIntent: true,
    sound: const RawResourceAndroidNotificationSound('job_alert'),
    playSound: true,
    audioAttributesUsage: AudioAttributesUsage.alarm,
  );
}

/// Draws the loud job-offer notification (heads-up, alarm sound, full-screen
/// intent). A fixed id means a repeat replaces rather than stacks. Title/body
/// default to generic Thai copy when not supplied.
Future<void> _showJobNotification(
  FlutterLocalNotificationsPlugin plugin, {
  String? title,
  String? body,
  String? route,
}) async {
  await plugin.show(
    id: 0x10B, // stable job-alert id (shared by WS + FCM foreground paths)
    title: title ?? 'มีงานเข้าใหม่',
    body: body ?? 'แตะเพื่อดูรายละเอียดงาน',
    notificationDetails: NotificationDetails(
      android: _jobAndroidDetails(),
      iOS: const DarwinNotificationDetails(
        sound: 'job_alert.caf',
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        interruptionLevel: InterruptionLevel.timeSensitive,
      ),
    ),
    payload: route ?? AppRoutes.incomingJobNamedPage,
  );
}

/// Handles messages delivered while the app is in the background or terminated.
///
/// This MUST be a top-level (or static) function so the AOT tree-shaker keeps
/// it, and it runs in its own isolate. Per fcm_push_notification_spec.md the
/// backend always sends a `notification` block and sets
/// `android.notification.channel_id` / `apns.payload.aps.sound` directly on
/// the FCM message, so the OS renders the (correctly loud, for offers) push
/// itself while backgrounded/terminated — this handler only needs to run for
/// side effects (logging, future data-sync work), never to draw a
/// notification, or the driver would see the job offer twice. Registered from
/// [main] via [FirebaseMessaging.onBackgroundMessage].
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('FCM(bg): id=${message.messageId} data=${message.data}');
  // This isolate never runs main(), so GetStorage needs its own init before
  // FcmDebugLog (backed by GetStorage) can persist an entry here.
  try {
    await GetStorage.init();
  } catch (_) {}
  FcmDebugLog.log(
    'Background message received: id=${message.messageId} data=${message.data}',
  );
}

/// Wires up foreground / tap / launch message handling and the local
/// notification used to display foreground messages on Android. Token
/// registration is handled separately in the app-startup controller.
class PushNotificationService {
  PushNotificationService._();

  static final PushNotificationService instance = PushNotificationService._();

  bool _initialized = false;

  // De-dupe for the loud alert: the in-app WebSocket offer path and a
  // foreground FCM push can both fire for the same offer. Whichever lands
  // first rings; a matching second one within the window is swallowed.
  DateTime? _lastAlertAt;
  String? _lastAlertKey;

  /// Rings the loud job-offer alert locally (Android heads-up on the alarm
  /// channel; iOS alert sound). Called by BOTH the in-app WebSocket offer
  /// path — so a foregrounded driver hears the alert even when NO FCM push is
  /// delivered — and the foreground-FCM path. De-duped by [key] within a short
  /// window so the two paths never double-ring for the same offer.
  Future<void> alertJobOffer({
    String? key,
    String? title,
    String? body,
    String? route,
  }) async {
    final now = DateTime.now();
    final recent = _lastAlertAt != null &&
        now.difference(_lastAlertAt!) < const Duration(seconds: 6);
    final sameOrUnkeyed =
        key == null || _lastAlertKey == null || key == _lastAlertKey;
    if (recent && sameOrUnkeyed) return;
    _lastAlertAt = now;
    _lastAlertKey = key;
    try {
      await _showJobNotification(
        _localNotifications,
        title: title,
        body: body,
        route: route,
      );
    } catch (e) {
      debugPrint('PushNotificationService: alertJobOffer failed: $e');
    }
  }

  /// Clears every delivered notification for this app — which also stops the
  /// ~10s job-alert sound if it is still ringing. Called when the driver acts
  /// on a job offer (accept/decline), so the alert doesn't keep playing under
  /// the live screen. Cancels both locally-drawn notifications (foreground
  /// path) and OS-drawn FCM ones (background path).
  Future<void> cancelJobAlerts() async {
    try {
      await _localNotifications.cancelAll();
    } catch (e) {
      debugPrint('PushNotificationService: cancelJobAlerts failed: $e');
    }
  }

  /// Set up message listeners. Safe to call once after Firebase is initialized;
  /// repeat calls are no-ops.
  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;

    final messaging = FirebaseMessaging.instance;

    await _initLocalNotifications();

    // iOS: present alert/badge/sound even while the app is in the foreground
    // (no-op on Android, which is handled by the local notification below).
    await messaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    // Message received while the app is open and foregrounded.
    FirebaseMessaging.onMessage.listen(_onForegroundMessage);

    // User tapped a notification while the app was backgrounded.
    FirebaseMessaging.onMessageOpenedApp.listen(_handleTap);

    // App was launched from a terminated state by tapping a notification.
    final initialMessage = await messaging.getInitialMessage();
    if (initialMessage != null) {
      // Defer until the first frame so the router is mounted before we navigate.
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _handleTap(initialMessage),
      );
    }
  }

  Future<void> _initLocalNotifications() async {
    const androidInit = AndroidInitializationSettings('ic_stat_notification');
    // firebase_messaging already handles iOS permission prompts, so don't
    // request again here.
    const darwinInit = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    await _localNotifications.initialize(
      settings: const InitializationSettings(
        android: androidInit,
        iOS: darwinInit,
      ),
      onDidReceiveNotificationResponse: (response) {
        final route = response.payload;
        if (route != null) _navigateTo(route);
      },
    );

    // Register both channels up front so their importance/sound is honoured
    // (Android 8+). Channel sound is immutable after creation.
    final android = _localNotifications.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await android?.createNotificationChannel(_androidChannel);
    await android?.createNotificationChannel(_jobChannel);
  }

  void _onForegroundMessage(RemoteMessage message) {
    debugPrint(
      'FCM(fg): id=${message.messageId} '
      'title=${message.notification?.title} data=${message.data}',
    );
    FcmDebugLog.log(
      'Foreground message received: id=${message.messageId} data=${message.data}',
    );

    // iOS presents notifications itself via the foreground options above,
    // including the loud job-alert sound set in `apns.payload.aps.sound` — no
    // local draw needed, and drawing one too would double the alert. Android
    // does not display notification messages while foregrounded, so this app
    // draws one itself, using the loud channel for job offers.
    if (defaultTargetPlatform != TargetPlatform.android) return;

    if (_isJobOffer(message)) {
      final key = message.data['job_id']?.toString() ??
          message.data['order_id']?.toString() ??
          message.data['id']?.toString() ??
          message.messageId;
      alertJobOffer(
        key: key,
        title: message.data['title'] as String? ?? message.notification?.title,
        body: message.data['body'] as String? ?? message.notification?.body,
        route: message.data['route'] as String?,
      );
      return;
    }

    final notification = message.notification;
    if (notification == null) return;

    _localNotifications.show(
      id: notification.hashCode,
      title: notification.title,
      body: notification.body,
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          _androidChannel.id,
          _androidChannel.name,
          channelDescription: _androidChannel.description,
          icon: 'ic_stat_notification',
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
      payload: message.data['route'] as String?,
    );
  }

  /// Navigate in response to a notification tap. The backend can steer the
  /// driver to a screen by including a `route` path (e.g. `/incoming-job`) in
  /// the message data; unknown or missing routes are ignored.
  void _handleTap(RemoteMessage message) {
    debugPrint('FCM(tap): id=${message.messageId} data=${message.data}');
    FcmDebugLog.log('Notification tapped: id=${message.messageId} route=${message.data['route']}');
    // Finance decided on a held (override-claimed) fare → open the held list.
    final type = message.data['type']?.toString();
    if (type == 'held_fare_approved' || type == 'held_fare_rejected') {
      _navigateTo('/held-fares');
      return;
    }
    final route = message.data['route'];
    if (route is String) _navigateTo(route);
  }

  /// Manually re-fetch the current FCM token and log it, without going
  /// through the permission-request flow again. Used by the FCM debug
  /// screen's "Refresh token" action.
  Future<void> refreshTokenForDebug() async {
    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token == null || token.isEmpty) {
        FcmDebugLog.log('Refresh: token unavailable (Simulator or no APNs token)');
        return;
      }
      FcmDebugLog.setToken(token);
      FcmDebugLog.log('Refresh: token = ${FcmDebugLog.truncate(token, 24)}...');
    } catch (e) {
      FcmDebugLog.log('Refresh: ERROR $e');
    }
  }

  void _navigateTo(String route) {
    if (route.startsWith('/')) {
      AppRouter.router.go(route);
    }
  }
}
