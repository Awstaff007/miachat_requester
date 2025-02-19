// lib/notification_service.dart

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:rxdart/rxdart.dart';
import 'package:flutter/material.dart';
import 'dart:convert'; // Importa la libreria JSON

class NotificationService {
  static final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
  static final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  static final BehaviorSubject<String> _notificationStream = BehaviorSubject(); // Aggiunto

  // Aggiunta gestione azioni e stati
  static final onNotificationClick = BehaviorSubject<String>();
  static final _notificationClickController = BehaviorSubject<String>();

  static Stream<String> get notificationClicks => _notificationClickController.stream;
  static Stream<String> get notifications => _notificationStream.stream; // Aggiunto

  Future<void> init() async {
    // Richiedi permessi per iOS
    await _firebaseMessaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    // Inizializzazione per Android
    const AndroidInitializationSettings initializationSettingsAndroid = AndroidInitializationSettings('@mipmap/ic_launcher');

    // Inizializzazione per iOS
    const DarwinInitializationSettings initializationSettingsIOS = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    final InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS
    );

    await _flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (details) { // Aggiunto
        _notificationStream.add(details.payload ?? ''); // Aggiunto
      }
    );

    // Configurazione click notifiche
    _flutterLocalNotificationsPlugin.getNotificationAppLaunchDetails().then((details) {
      if (details?.didNotificationLaunchApp ?? false) {
        onNotificationClick.add(details!.payload!);
        _notificationClickController.add(details.payload!);
      }
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      onNotificationClick.add(message.data['payload'] ?? '');
      _notificationClickController.add(message.data['payload'] ?? '');
    });

    _setupInteractedMessage();

    // Gestione notifiche in background (Firebase)
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      _showForegroundNotification(message);
    });

    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler); // Aggiunto
  }

  // Gestione notifiche in background (Firebase) - Funzione statica
  static Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
    await Firebase.initializeApp();
    _showNotification(message); // Modificato
  }

  static Future<void> _handleBackgroundMessage(RemoteMessage message) async { // Aggiunto
    await Firebase.initializeApp(); // Aggiunto
    _showNotification(message); // Aggiunto
  } // Aggiunto

  static void _handleForegroundMessage(RemoteMessage message) { // Aggiunto
    _showNotification(message); // Aggiunto
  } // Aggiunto

  static void _showNotification(RemoteMessage message) { // Aggiunto
    _flutterLocalNotificationsPlugin.show(
      message.hashCode,
      message.notification?.title,
      message.notification?.body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          'main_channel',
          'Main Notifications',
          icon: 'ic_notification',
          color: Colors.blue,
        ),
        iOS: const DarwinNotificationDetails(),
      ),
      payload: jsonEncode(message.data),
    );
  } // Aggiunto

  Future<void> sendNotification(String title, String body, {String type = 'info', String? payload}) async { // Aggiunto parametro payload
    const AndroidNotificationDetails androidNotificationDetails = AndroidNotificationDetails(
      'your_channel_id',
      'Your Channel name',
      channelDescription: 'Your Channel Description',
      importance: Importance.max,
      priority: Priority.high,
      icon: type == 'error' ? 'ic_error' : 'ic_info', // <-- Icone personalizzate
    );

    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidNotificationDetails,
      iOS: DarwinNotificationDetails()
    );

    await _flutterLocalNotificationsPlugin.show(
      0,
      title,
      body,
      notificationDetails,
      payload: payload ?? 'default_payload', // <-- Passa il payload
    );
  }

  Future<void> _setupInteractedMessage() async {
    RemoteMessage? initialMessage = await FirebaseMessaging.instance.getInitialMessage();
    if (initialMessage != null) _handleMessage(initialMessage);

    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessage);
  }

  void _handleMessage(RemoteMessage message) {
    if (message.data['type'] == 'open_app') {
      _notificationClickController.add('open_app');
    }
  }

  void _handleBackgroundMessage(RemoteMessage message) {
    if (message.data.containsKey('action')) {
      _notificationClickController.add(message.data['action']);
    }
  }

  Future<void> _showForegroundNotification(RemoteMessage message) async {
    await sendNotification(
      title: message.notification?.title ?? 'Nuova Notifica',
      body: message.notification?.body ?? '',
      type: message.data['type'] ?? 'info',
      payload: jsonEncode(message.data) // Utilizza jsonEncode per convertire i dati in un formato JSON
    );
  }
}
