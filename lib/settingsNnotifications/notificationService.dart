import 'package:flutter/material.dart';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationService {
  static Future<void> checkForPermission() async {
    bool isAllowed = await AwesomeNotifications().isNotificationAllowed();
    if (!isAllowed) {
      await AwesomeNotifications().requestPermissionToSendNotifications();
    }
  }

  // SetUp
  static Future<void> initAwesomeNoti() async {
    await AwesomeNotifications().initialize(
      null,
      [
        NotificationChannel(
          channelKey: 'basic_channel',
          channelName: 'Basic notifications',
          channelDescription: 'Notification channel for basic tests',
          defaultColor: Color(0xFF9D50DD),
          ledColor: Colors.white,
        ),
      ],
    );
  }

  //Create Notification
  static void createNotification(TimeOfDay time, int weekDays, int sessionId) {
    for (int i = 0; i < weekDays; i++) {
      final notifId = sessionId * 100 + i;

      AwesomeNotifications().createNotification(
        content: NotificationContent(
          id: notifId,
          channelKey: 'basic_channel',
          title: "Today's attendance",
          body: "Don't forget to mark today's attendance.",
        ),
        schedule: NotificationCalendar(
          weekday: i + 1, // Monday=1
          hour: time.hour,
          minute: time.minute,
          second: 0,
          millisecond: 0,
          repeats: true,
        ),
      );
    }
  }

  // Delete all notifications
  static Future<void> cancelSessionNoti(int sessionId) async {
    // Cancel IDs in the range sessionId*100 → sessionId*100 + 99
    for (int i = 0; i < 100; i++) {
      await AwesomeNotifications().cancel(sessionId * 100 + i);
    }
  }

  // Show timePicker and save to pref
  static Future<TimeOfDay?> timePicker(
      BuildContext context, TimeOfDay? oldTime, int sessionID) async {
    TimeOfDay? time = await showTimePicker(
      context: context,
      initialTime: oldTime ?? TimeOfDay.now(),
      initialEntryMode: TimePickerEntryMode.dial,
    );

    if (time != null) {
      final pref = await SharedPreferences.getInstance();
      final formatted = "${time.hour}:${time.minute}";
      await pref.setString("DailyNotificationTime_$sessionID", formatted);

      return time; // 👈 return picked time so caller can update state
    }

    return null;
  }

  // load time from pref
  static Future<TimeOfDay?> getTime(int sessionID) async {
    final pref = await SharedPreferences.getInstance();
    final time = pref.getString("DailyNotificationTime_$sessionID");
    if (time == null) return null;
    final parts = time.split(":");

    final hour = int.parse(parts[0]);
    final minute = int.parse(parts[1]);
    return TimeOfDay(hour: hour, minute: minute);
  }
}
