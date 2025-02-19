import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:rxdart/rxdart.dart';
import 'dart:convert';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();
  static final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  static final BehaviorSubject<Map<String, dynamic>> _notificationSubject =
      BehaviorSubject();

  static Future<void> init() async {
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('ic_notification');
    
    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    await _notificationsPlugin.initialize(
      const InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      ),
      onDidReceiveNotificationResponse: (details) {
        if (details.payload != null) {
          _notificationSubject.add(jsonDecode(details.payload!));
        }
      },
    );

    await _firebaseMessaging.requestPermission();
    
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
    FirebaseMessaging.onMessageOpenedApp.listen(_handleBackgroundMessage);
  }

  static Stream<Map<String, dynamic>> get notifications => _notificationSubject.stream;

  static Future<void> _handleBackgroundMessage(RemoteMessage message) async {
    _showNotification(message);
    _notificationSubject.add(message.data);
  }

  static void _handleForegroundMessage(RemoteMessage message) {
    _showNotification(message);
    _notificationSubject.add(message.data);
  }

  static void _showNotification(RemoteMessage message) {
    _notificationsPlugin.show(
      message.hashCode,
      message.notification?.title,
      message.notification?.body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          'main_channel',
          'Main Notifications',
          importance: Importance.max,
          priority: Priority.high,
          icon: 'ic_notification',
          color: Colors.blue,
        ),
        iOS: const DarwinNotificationDetails(),
      ),
      payload: jsonEncode(message.data),
    );
  }

  static Future<String?> getFCMToken() async {
    try {
      return await _firebaseMessaging.getToken();
    } catch (e) {
      debugPrint('Error getting FCM token: $e');
      return null;
    }
  }
}
