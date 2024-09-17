import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class PrayerNotificationService {
  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  PrayerNotificationService() {
    _initializeNotifications();
  }

  // Initialize notifications
  void _initializeNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
    );

    await _notificationsPlugin.initialize(initializationSettings);

    tz.initializeTimeZones();
  }

  // Schedule a prayer time notification
  void schedulePrayerNotification(
      String prayerName, DateTime prayerTime) async {
    final notificationTime = tz.TZDateTime.from(prayerTime, tz.local);

    await _notificationsPlugin.zonedSchedule(
      prayerTime.hashCode, // unique ID
      'Prayer Time: $prayerName',
      'It\'s time for $prayerName prayer',
      notificationTime,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'prayer_channel_id',
          'Prayer Notifications',
          channelDescription: 'Notifications for prayer times',
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
      androidAllowWhileIdle: true,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.wallClockTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  // Cancel a specific notification
  void cancelPrayerNotification(DateTime prayerTime) {
    _notificationsPlugin.cancel(prayerTime.hashCode);
  }

  // Cancel all notifications
  void cancelAllNotifications() {
    _notificationsPlugin.cancelAll();
  }
}
