import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get_storage/get_storage.dart';
import 'package:massdrive/core/constants/app_routes.dart';
import 'package:massdrive/core/services/fcm_debug_log.dart';
import 'package:massdrive/router/app_routes.dart';

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
  'job_offer_channel_v1',
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

/// True when a push is a job/offer that should ring with the loud alert. The
/// backend must send job offers as **data messages** (so this app draws the
/// notification with the custom-sound channel); a `notification`-type message
/// would be drawn by the OS on the default channel instead.
bool _isJobOffer(RemoteMessage message) {
  final type = message.data['type']?.toString() ?? '';
  return type.endsWith('offer') || message.data['sound'] == 'job_alert';
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

/// Shows the loud job-offer notification. Title/body are read from the data
/// payload (data-only messages carry no `notification`), falling back to the
/// `notification` block if present.
Future<void> _showJobNotification(
  FlutterLocalNotificationsPlugin plugin,
  RemoteMessage message,
) async {
  final title = message.data['title'] as String? ??
      message.notification?.title ??
      'มีงานเข้าใหม่';
  final body = message.data['body'] as String? ??
      message.notification?.body ??
      'แตะเพื่อดูรายละเอียดงาน';

  await plugin.show(
    id: message.messageId?.hashCode ?? 0,
    title: title,
    body: body,
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
    payload: message.data['route'] as String? ?? AppRoutes.incomingJobNamedPage,
  );
}

/// Handles messages delivered while the app is in the background or terminated.
///
/// This MUST be a top-level (or static) function so the AOT tree-shaker keeps
/// it, and it runs in its own isolate. For a job offer we draw the loud
/// custom-sound notification ourselves (the OS would otherwise use the default
/// channel/sound). Registered from [main] via
/// [FirebaseMessaging.onBackgroundMessage].
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('FCM(bg): id=${message.messageId} data=${message.data}');
  // This isolate never runs main(), so GetStorage needs its own init before
  // FcmDebugLog (backed by GetStorage) can persist an entry here.
  try {
    await GetStorage.init();
  } catch (_) {}
  FcmDebugLog.log('Background message received: id=${message.messageId} data=${message.data}');
  if (!_isJobOffer(message)) return;

  // The background isolate has its own plugin instance — initialize it and make
  // sure the job channel exists before showing (the main isolate may not have
  // run yet on a cold, push-launched start).
  final plugin = FlutterLocalNotificationsPlugin();
  await plugin.initialize(
    settings: const InitializationSettings(
      android: AndroidInitializationSettings('ic_stat_notification'),
      iOS: DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      ),
    ),
  );
  await plugin
      .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin
      >()
      ?.createNotificationChannel(_jobChannel);
  await _showJobNotification(plugin, message);
}

/// Wires up foreground / tap / launch message handling and the local
/// notification used to display foreground messages on Android. Token
/// registration is handled separately in the app-startup controller.
class PushNotificationService {
  PushNotificationService._();

  static final PushNotificationService instance = PushNotificationService._();

  bool _initialized = false;

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

    // A job offer rings loudly on both platforms via the local notification.
    if (_isJobOffer(message)) {
      _showJobNotification(_localNotifications, message);
      return;
    }

    // iOS presents ordinary notifications itself via the foreground options
    // above. Android does not display notification messages while foregrounded,
    // so draw one with a local notification.
    if (defaultTargetPlatform != TargetPlatform.android) return;

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
