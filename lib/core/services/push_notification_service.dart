import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:massdrive/router/app_routes.dart';

/// Android notification channel used both by the local-notification display
/// (foreground) and by FCM's system-drawn notifications (background/terminated).
/// The id MUST match `default_notification_channel_id` in AndroidManifest.xml.
const AndroidNotificationChannel _androidChannel = AndroidNotificationChannel(
  'high_importance_channel',
  'Notifications',
  description: 'ใช้สำหรับการแจ้งเตือนสำคัญ เช่น งานเข้าใหม่',
  importance: Importance.high,
);

final FlutterLocalNotificationsPlugin _localNotifications =
    FlutterLocalNotificationsPlugin();

/// Handles messages delivered while the app is in the background or terminated.
///
/// This MUST be a top-level (or static) function so the AOT tree-shaker keeps
/// it, and it runs in its own isolate — keep the work light and self-contained.
/// The plugin auto-initializes Firebase for this isolate. Registered from
/// [main] via [FirebaseMessaging.onBackgroundMessage]. Notification messages are
/// drawn by the OS automatically; nothing extra is needed here.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint(
    'FCM(bg): id=${message.messageId} data=${message.data}',
  );
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

    // Register the channel up front so its importance is honoured (Android 8+).
    await _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(_androidChannel);
  }

  void _onForegroundMessage(RemoteMessage message) {
    debugPrint(
      'FCM(fg): id=${message.messageId} '
      'title=${message.notification?.title} data=${message.data}',
    );

    // iOS presents the notification itself via the foreground options above.
    // Android does not display notification messages while foregrounded, so
    // draw one with a local notification.
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
    final route = message.data['route'];
    if (route is String) _navigateTo(route);
  }

  void _navigateTo(String route) {
    if (route.startsWith('/')) {
      AppRouter.router.go(route);
    }
  }
}
