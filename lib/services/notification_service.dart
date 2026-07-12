import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'dart:math';
import '../core/api_client.dart';

class NotificationService {
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final ApiClient _apiClient = ApiClient();
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();

  // Android Notification Channel
  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'high_importance_channel', // id
    'High Importance Notifications', // title
    description: 'This channel is used for important notifications.',
    importance: Importance.max,
  );

  Future<void> initialize() async {
    // 1. Request permissions (Android 13+ and iOS)
    NotificationSettings settings = await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      debugPrint('User granted notification permission');
      
      // Get the token
      String? token = await _fcm.getToken();
      if (token != null) {
        debugPrint('FCM Token: $token');
        _saveTokenToBackend(token);
      }
    }

    // 2. Initialize Local Notifications for Foreground Alerts
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    
    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: DarwinInitializationSettings(),
    );

    await _localNotifications.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (details) {
        // Handle notification tap logic here
        debugPrint('Notification tapped: ${details.payload}');
      },
    );

    // Create the channel on Android
    await _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_channel);

    // 3. Handle background messages
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // 4. Handle foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      _handleIncomingMessage(message);
    });

    // 5. Handle app opened from notification
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('App opened via notification: ${message.data}');
    });
  }

  Future<void> _handleIncomingMessage(RemoteMessage message) async {
    // 1. Staggered Fetch Jitter (0-5 seconds)
    // Prevents "Thundering Herd" when thousands of devices receive a blast simultaneously
    final randomDelay = Random().nextInt(6); // 0 to 5 seconds
    debugPrint('Notification received. Applying jitter delay of $randomDelay seconds...');
    await Future.delayed(Duration(seconds: randomDelay));

    // 2. Show local notification
    RemoteNotification? notification = message.notification;
    AndroidNotification? android = message.notification?.android;

    if (notification != null && android != null) {
      _localNotifications.show(
        notification.hashCode,
        notification.title,
        notification.body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            _channel.id,
            _channel.name,
            channelDescription: _channel.description,
            icon: android.smallIcon,
            importance: Importance.max,
            priority: Priority.high,
          ),
        ),
        payload: message.data.toString(),
      );
    }
    
    // 3. Trigger any specific UI refreshes or logic here
  }

  Future<void> _saveTokenToBackend(String token) async {
    try {
      await _apiClient.post('auth/fcm-token/', data: {'token': token});
    } catch (e) {
      debugPrint('Error saving FCM token: $e');
    }
  }
}

// Global background handler
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Staggered jitter even in background to protect API
  final randomDelay = Random().nextInt(6);
  await Future.delayed(Duration(seconds: randomDelay));

  debugPrint("Handling a background message: ${message.messageId}");
}
