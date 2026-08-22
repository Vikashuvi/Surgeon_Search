import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/foundation.dart';

/// Core push notification service using Firebase Cloud Messaging.
///
/// Handles:
/// - FCM permission request (iOS + Android 13+)
/// - Foreground notification display via flutter_local_notifications
/// - FCM token retrieval and refresh listening
/// - Android notification channel creation
class NotificationService {
  static final NotificationService _instance = NotificationService._();
  factory NotificationService() => _instance;
  NotificationService._();

  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;

  /// Initialize the notification service.
  /// Call this once after Firebase.initializeApp() in main().
  Future<void> initialize() async {
    if (_isInitialized) return;

    // 1. Request notification permission (iOS + Android 13+)
    final settings = await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );
    debugPrint(
        '🔔 Notification permission: ${settings.authorizationStatus}');

    // 2. Setup flutter_local_notifications for foreground display
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    await _localNotifications.initialize(
      const InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      ),
    );

    // 3. Create Android notification channel
    const androidChannel = AndroidNotificationChannel(
      'surgeon_search_channel',
      'Surgeon Search Notifications',
      description: 'Notifications for Surgeon Search app',
      importance: Importance.high,
    );
    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(androidChannel);

    // 4. Listen for foreground messages and show local notification
    FirebaseMessaging.onMessage.listen(_showForegroundNotification);

    // 5. Get initial FCM token
    final token = await _fcm.getToken();
    debugPrint('🔑 FCM Token: $token');

    // 6. Listen for token refresh
    _fcm.onTokenRefresh.listen((newToken) {
      debugPrint('🔄 FCM Token refreshed: $newToken');
      // Token refresh is handled by AuthController when it detects a change
    });

    // 7. Set foreground notification presentation options (iOS)
    await _fcm.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    _isInitialized = true;
    debugPrint('✅ NotificationService initialized');
  }

  /// Get the current FCM device token.
  Future<String?> getToken() async {
    return await _fcm.getToken();
  }

  /// Show a local notification when a message arrives while app is in foreground.
  void _showForegroundNotification(RemoteMessage message) {
    final notification = message.notification;
    if (notification == null) return;

    debugPrint(
        '📩 Foreground notification: ${notification.title} - ${notification.body}');

    _localNotifications.show(
      notification.hashCode,
      notification.title,
      notification.body,
      NotificationDetails(
        android: const AndroidNotificationDetails(
          'surgeon_search_channel',
          'Surgeon Search Notifications',
          channelDescription: 'Notifications for Surgeon Search app',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
    );
  }
}
