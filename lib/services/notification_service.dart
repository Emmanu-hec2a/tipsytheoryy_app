import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'dart:math';
import 'dart:async';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../core/api_client.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final ApiClient _apiClient = ApiClient();
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  
  // Task 3: Stream for screens to listen to specific notifications
  final StreamController<RemoteMessage> _messageStreamController = StreamController<RemoteMessage>.broadcast();
  Stream<RemoteMessage> get onMessageReceived => _messageStreamController.stream;

  // Stream for when a notification is tapped (deep linking)
  final StreamController<RemoteMessage> _tapStreamController = StreamController<RemoteMessage>.broadcast();
  Stream<RemoteMessage> get onNotificationTap => _tapStreamController.stream;

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
      debugPrint('FCM: User granted permission');
      
      // Get the token
      String? token = await _fcm.getToken();
      if (token != null) {
        debugPrint('FCM: Token retrieved: ${token.substring(0, 10)}...');
        await registerToken(); 
      }
    } else {
      debugPrint('FCM: User declined or has not accepted permission');
    }

    // 2. Initialize Local Notifications for Foreground Alerts
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    
    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: DarwinInitializationSettings(),
    );

    // Request local notification permission for Android 13+
    await _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();

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
      _tapStreamController.add(message);
    });

    // 6. Handle token refresh
    _fcm.onTokenRefresh.listen((newToken) {
      _saveTokenToBackend(newToken);
    });
  }

  Future<void> _handleIncomingMessage(RemoteMessage message) async {
    // 1. Show local notification
    RemoteNotification? notification = message.notification;
    AndroidNotification? android = message.notification?.android;

    if (notification != null) {
      _localNotifications.show(
        notification.hashCode,
        notification.title,
        notification.body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            _channel.id,
            _channel.name,
            channelDescription: _channel.description,
            icon: android?.smallIcon ?? '@mipmap/ic_launcher',
            importance: Importance.max,
            priority: Priority.high,
            ticker: 'ticker',
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        payload: message.data.toString(),
      );
    }
    
    // 2. Trigger any specific UI refreshes or logic here
    _messageStreamController.add(message);
    debugPrint('Foreground notification displayed: ${notification?.title}');
  }

  /// Public method to manually register/refresh token (e.g., after login)
  Future<void> registerToken() async {
    try {
      String? token = await _fcm.getToken();
      if (token != null) {
        await _saveTokenToBackend(token);
      }
    } catch (e) {
      debugPrint('Error getting FCM token: $e');
    }
  }

  Future<void> _saveTokenToBackend(String token) async {
    try {
      // Check if we already have a token saved to avoid redundant API calls
      const storage = FlutterSecureStorage();
      final lastSavedToken = await storage.read(key: 'last_fcm_token');
      if (lastSavedToken == token) {
        debugPrint('FCM Token already registered with backend.');
        return;
      }

      final response = await _apiClient.post('auth/fcm-token/', data: {'token': token});
      if (response.statusCode == 200) {
        debugPrint('FCM: Token saved to backend. Token: ${token.substring(0, 10)}...');
        await storage.write(key: 'last_fcm_token', value: token);
      } else if (response.statusCode == 401) {
        debugPrint('FCM: Failed to save token - Unauthorized. User not logged in.');
      } else {
        debugPrint('FCM: Failed to save token. Status: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error saving FCM token to backend: $e');
    }
  }
}

// Global background handler
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Initialize Firebase if not already initialized
  // await Firebase.initializeApp(); // Usually already handled in main

  debugPrint("Handling a background message: ${message.messageId}");
}
