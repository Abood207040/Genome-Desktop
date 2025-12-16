import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  Future<void> initialize() async {
    // Initialize settings for basic notifications
    const InitializationSettings initializationSettings = InitializationSettings();

    await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        // Handle notification tap if needed
        print('Notification tapped: ${response.payload}');
      },
    );
  }

  Future<void> showAppointmentNotification({
    required String patientName,
    required String appointmentTime,
    required String appointmentDate,
  }) async {
    const NotificationDetails notificationDetails = NotificationDetails();

    await flutterLocalNotificationsPlugin.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000, // Unique ID
      'New Appointment Scheduled',
      'Appointment with $patientName on $appointmentDate at $appointmentTime',
      notificationDetails,
      payload: 'appointment',
    );
  }

  Future<void> showChatNotification({
    required String senderName,
    required String message,
  }) async {
    const NotificationDetails notificationDetails = NotificationDetails();

    await flutterLocalNotificationsPlugin.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000 + 1, // Unique ID
      'New Message from $senderName',
      message.length > 50 ? '${message.substring(0, 50)}...' : message,
      notificationDetails,
      payload: 'chat',
    );
  }

  Future<void> showSystemNotification({
    required String title,
    required String body,
  }) async {
    const NotificationDetails notificationDetails = NotificationDetails();

    await flutterLocalNotificationsPlugin.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000 + 2, // Unique ID
      title,
      body,
      notificationDetails,
      payload: 'system',
    );
  }
}
