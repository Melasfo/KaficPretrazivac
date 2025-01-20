import 'package:flutter/material.dart';

class NotificationScreen extends StatelessWidget {
  final String? payload;

  NotificationScreen({this.payload});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Notification Screen'),
      ),
      body: Center(
        child: Text('You clicked on the notification! Payload: $payload'),
      ),
    );
  }
}
