import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:permission_handler/permission_handler.dart';
import '../models/models.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    try {
      tz.initializeTimeZones();
      tz.setLocalLocation(tz.getLocation('UTC'));
    } catch (e) {
      // Log error but don't crash
    }

    const AndroidInitializationSettings initializationSettingsAndroid = AndroidInitializationSettings('@mipmap/ic_launcher');
    const DarwinInitializationSettings initializationSettingsDarwin = DarwinInitializationSettings();
    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsDarwin,
    );

    await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _onNotificationResponse,
    );
  }

  void _onNotificationResponse(NotificationResponse response) {
    // Handle notification tapped
    // For snooze or mark started, one could parse payload here
  }

  Future<void> requestPermissions() async {
    await Permission.notification.request();
    await Permission.scheduleExactAlarm.request();
    await Permission.ignoreBatteryOptimizations.request();
  }

  Future<void> scheduleBlockAlarms(List<TimeBlock> blocks) async {
    await flutterLocalNotificationsPlugin.cancelAll(); // Reset

    for (var block in blocks) {
      if (!block.remindersEnabled) continue;
      
      final now = DateTime.now();
      if (block.startTime.isBefore(now) && block.recurrence == Recurrence.none) continue;

      DateTime scheduledTime = block.startTime;
      while (scheduledTime.isBefore(now)) {
        scheduledTime = scheduledTime.add(const Duration(days: 1)); // Simplified logic
      }

      final tz.TZDateTime tzTime = tz.TZDateTime.from(scheduledTime, tz.local);

      await flutterLocalNotificationsPlugin.zonedSchedule(
        block.id.hashCode,
        '⏰ Time for: ${block.title}',
        'Your scheduled block is starting now.',
        tzTime,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'zenith_schedule',
            'Schedule Alarms',
            channelDescription: 'Notifications for your scheduled time blocks.',
            importance: Importance.max,
            priority: Priority.high,
            actions: [
              AndroidNotificationAction('snooze_5', 'Snooze 5 min'),
              AndroidNotificationAction('start', 'Mark Started'),
            ],
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: block.recurrence == Recurrence.daily ? DateTimeComponents.time : null,
      );
    }
  }
}
