import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/services.dart'; // For SystemNavigator.pop()
import 'main.dart';
import 'notification_screen.dart';
import 'home_screen.dart'; // Import the home screen

class NotificationService {
  static final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  /// Initializes Firebase Messaging and Local Notifications.
  static Future<void> initialize() async {
    // Request permissions for notifications
    await _firebaseMessaging.requestPermission();

    // Initialize local notifications
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);

    await _flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _onDidReceiveNotificationResponse,
    );

    // Log the FCM token
    String? token = await _firebaseMessaging.getToken();
    print('FCM Token: $token');

    // Listen for foreground notifications
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('Notification received: ${message.data}');
      _handleNotification(message, true); // true indicates foreground
    });

    // Listen for background notifications
    FirebaseMessaging.onBackgroundMessage(_backgroundMessageHandler);
  }

  /// Handles background notifications when the app is in the background or terminated.
  static Future<void> _backgroundMessageHandler(RemoteMessage message) async {
    print('Background notification received: ${message.data}');
    _handleNotification(message, false); // false indicates background
  }

  /// Retrieves app launch details (if the app was opened by a notification).
  static Future<NotificationAppLaunchDetails?> getNotificationAppLaunchDetails() async {
    return await _flutterLocalNotificationsPlugin.getNotificationAppLaunchDetails();
  }

  /// Handles the notification data and shows the notification.
  static Future<void> _handleNotification(RemoteMessage message, bool isForeground) async {
    String? imageUrl = message.data['imageUrl'];
    String? title = message.data['title'];
    String? body = message.data['body'];
    String? payload = message.data['payload'];

    // Show notification with the relevant data
    await _showNotification(title, body, payload, imageUrl, isForeground);
  }

  /// Displays a notification with title, body, image, and payload.
  static Future<void> _showNotification(
      String? title, String? body, String? payload, String? imageUrl, bool isForeground) async {
    // Temporary variable for local image file path
    String? localImagePath;

    // Download the image if the URL is provided
    if (imageUrl != null) {
      try {
        final http.Response response = await http.get(Uri.parse(imageUrl));
        if (response.statusCode == 200) {
          // Save the image to a temporary file
          final tempDir = Directory.systemTemp;
          final file = File('${tempDir.path}/notification_image.jpg');
          await file.writeAsBytes(response.bodyBytes);
          localImagePath = file.path;
        }
      } catch (e) {
        print('Error downloading image: $e');
      }
    }

    // Define notification actions
    const AndroidNotificationAction closeAppAction = AndroidNotificationAction(
      'closeApp_action',
      'Close Application',
      showsUserInterface: true, // Ensure no interaction with the UI
      cancelNotification: true, // This ensures the notification is dismissed
    );

    const AndroidNotificationAction testAction = AndroidNotificationAction(
      'test_action',
      'Test Action',
      showsUserInterface: true, // Action button will be visible
    );

    // Define notification details with actions
    final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'default_channel',
      'Default Channel',
      importance: Importance.high,
      priority: Priority.high,
      styleInformation: localImagePath != null
          ? BigPictureStyleInformation(
              FilePathAndroidBitmap(localImagePath),
              largeIcon: FilePathAndroidBitmap(localImagePath),
            )
          : null,
      actions: [closeAppAction, testAction], // Add both actions here
    );

    final NotificationDetails platformDetails = NotificationDetails(android: androidDetails);

    // Show notification based on foreground/background state
    await _flutterLocalNotificationsPlugin.show(
      0, // Notification ID
      title,
      body,
      platformDetails,
      payload: payload,
    );
  }

  /// Cancels a notification to avoid duplicate notifications.
  static Future<void> _cancelNotification() async {
    await _flutterLocalNotificationsPlugin.cancel(0); // Cancel notification with ID 0
  }

  /// Handles notification taps and navigates to the appropriate screen.
  static Future<void> _onDidReceiveNotificationResponse(NotificationResponse response) async {
    print('Notification response received: ${response.actionId}');

    // Handle tap navigation (normal notification tap)
    if (response.actionId == null || response.actionId!.isEmpty) {
      _handleNotificationPayload(response.payload);
    }
    // Handle notification action buttons (like dismiss)
    if (response.actionId == 'closeApp_action') {
      await _handleDismissAction();
    }
    // Handle "test_action" navigation to HomeScreen
    if (response.actionId == 'test_action') {
      await _navigateToHomeScreen();
    }
  }

  /// Handle the action of dismissing the notification and closing the app.
  static Future<void> _handleDismissAction() async {
    print('Close App button clicked');
    await _cancelNotification(); // Dismiss the notification
    _closeApp(); // Close the app completely
  }

  /// Closes the app completely by calling SystemNavigator.pop().
  static void _closeApp() {
    if (Platform.isAndroid) {
      SystemNavigator.pop(); // This closes the app completely
    } else if (Platform.isIOS) {
      // On iOS, you can't directly close the app programmatically.
      // You can prompt the user to exit the app manually if needed.
    }
  }

  /// Navigates to the HomeScreen when the "test_action" is clicked.
  static Future<void> _navigateToHomeScreen() async {
    print('Test Action button clicked');
    // Navigate to the HomeScreen
    navigatorKey.currentState?.pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => HomeScreen()), 
      (route) => false, // Remove all previous routes
    );
  }

  /// Processes the notification payload and navigates to a screen if needed.
  static void _handleNotificationPayload(String? payload) {
    if (payload != null) {
      navigatorKey.currentState?.push(
        MaterialPageRoute(builder: (_) => NotificationScreen(payload: payload)),
      );
    }
  }
}
