import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'home_screen.dart';
import 'notification_service.dart';
import 'notification_screen.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  // Initialize NotificationService (no need to capture return value)
  await NotificationService.initialize();

  // Check if the app was launched via a notification
  final NotificationAppLaunchDetails? notificationAppLaunchDetails =
      await NotificationService.getNotificationAppLaunchDetails();

  final bool launchedByNotification = notificationAppLaunchDetails?.didNotificationLaunchApp ?? false;

  final String? notificationPayload = notificationAppLaunchDetails?.notificationResponse?.payload;

  runApp(MyApp(
    launchedByNotification: launchedByNotification,
    notificationPayload: notificationPayload,
  ));
}

class MyApp extends StatelessWidget {
  final bool launchedByNotification;
  final String? notificationPayload;

  const MyApp({
    Key? key,
    required this.launchedByNotification,
    this.notificationPayload,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      title: 'Notification Demo',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: launchedByNotification
          ? NotificationScreen(payload: notificationPayload) // Navigate to NotificationScreen if launched by notification
          : HomeScreen(),  // Otherwise show HomeScreen
    );
  }
}