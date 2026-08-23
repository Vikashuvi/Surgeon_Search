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
    try {
      final settings = await _fcm.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );
      debugPrint(
          '🔔 Notification permission: ${settings.authorizationStatus}');
    } catch (e) {
      debugPrint('⚠️ Notification permission request failed: $e');
    }

    // 2. Setup flutter_local_notifications for foreground display
    try {
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
    } catch (e) {
      debugPrint('⚠️ Local notification initialization failed: $e');
    }

    // 3. Create Android notification channel
    try {
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
    } catch (e) {
      debugPrint('⚠️ Android notification channel creation failed: $e');
    }

    // 4. Listen for foreground messages and show local notification
    FirebaseMessaging.onMessage.listen(_showForegroundNotification);

    // 5. Get initial FCM token (with timeout to avoid hanging on iOS simulators)
    try {
      final token = await _fcm.getToken().timeout(const Duration(seconds: 4));
      debugPrint('🔑 FCM Token: $token');
    } catch (e) {
      debugPrint('⚠️ Could not retrieve initial FCM token (expected on iOS simulator): $e');
    }

    // 6. Listen for token refresh
    _fcm.onTokenRefresh.listen((newToken) {
      debugPrint('🔄 FCM Token refreshed: $newToken');
    });

    // 7. Set foreground notification presentation options (iOS)
    try {
      await _fcm.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );
    } catch (e) {
      debugPrint('⚠️ Set foreground notification options failed: $e');
    }

    _isInitialized = true;
    debugPrint('✅ NotificationService initialized');
  }

  /// Get the current FCM device token.
  Future<String?> getToken() async {
    try {
      return await _fcm.getToken().timeout(const Duration(seconds: 4));
    } catch (e) {
      debugPrint('⚠️ getToken error: $e');
      return null;
    }
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
