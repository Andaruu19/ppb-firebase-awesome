import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/material.dart';
import 'package:ppb_awesome_notification/models/task.dart'; // Pastikan path ini benar

class NotificationService {
  static Future<void> initializeNotifications() async {
    await AwesomeNotifications().initialize(
      null,
      [
        NotificationChannel(
          channelKey: 'task_channel',
          channelName: 'Task Reminders',
          channelDescription: 'Notification channel for task reminders',
          defaultColor: Colors.teal,
          ledColor: Colors.white,
          importance: NotificationImportance.High,
          channelShowBadge: true,
          playSound: true,
        )
      ],
      debug: true, // Set ke false untuk production
    );

    // Meminta izin notifikasi
    bool isAllowed = await AwesomeNotifications().isNotificationAllowed();
    if (!isAllowed) {
      await AwesomeNotifications().requestPermissionToSendNotifications();
    }
  }

  static Future<void> scheduleNotification(Task task) async {
    if (task.reminderDateTime.isBefore(DateTime.now())) {
      print("Reminder time is in the past. Notification not scheduled.");
      return;
    }

    // Hasilkan ID notifikasi unik, bisa dari hashCode task.id atau timestamp
    // Jika task.id null (task baru), kita bisa generate satu atau tunggu sampai ada ID dari Firebase
    // Untuk kesederhanaan, kita anggap task.id sudah ada atau kita gunakan hashCode dari title + time
    final int notificationId = task.id?.hashCode ?? (task.title.hashCode + task.reminderDateTime.millisecondsSinceEpoch).hashCode.abs() % 2147483647;
    task.notificationId = notificationId; // Simpan ID notifikasi ke task

    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: notificationId,
        channelKey: 'task_channel',
        title: task.title,
        body: task.description ?? 'Jangan lupa selesaikan task ini!',
        notificationLayout: NotificationLayout.Default,
        // bigPicture: 'asset://assets/notification_banner.jpg', // Jika ada gambar
        // largeIcon: 'asset://assets/app_icon.png',
        payload: {'taskId': task.id ?? ''}, // Kirim data jika perlu saat notifikasi ditekan
      ),
      schedule: NotificationCalendar.fromDate(date: task.reminderDateTime),
    );
    print("Notification scheduled for task: ${task.title} at ${task.reminderDateTime} with ID: $notificationId");
  }

  static Future<void> cancelNotification(int? notificationId) async {
    if (notificationId != null) {
      await AwesomeNotifications().cancel(notificationId);
      print("Notification with ID $notificationId cancelled.");
    }
  }

  static Future<void> listenToNotifications() async {
     AwesomeNotifications().setListeners(
        onActionReceivedMethod:         NotificationController.onActionReceivedMethod,
        onNotificationCreatedMethod:    NotificationController.onNotificationCreatedMethod,
        onNotificationDisplayedMethod:  NotificationController.onNotificationDisplayedMethod,
        onDismissActionReceivedMethod:  NotificationController.onDismissActionReceivedMethod
    );
  }

    static Future<void> sendTaskCompletedNotification(Task task) async {
    final int notificationId = (task.id?.hashCode ?? DateTime.now().millisecondsSinceEpoch.hashCode).abs() % 2147483647 + 1000; // Tambah offset

    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: notificationId, // ID unik untuk notifikasi "selesai" ini
        channelKey: 'task_channel', // Gunakan channel yang sama atau buat channel baru
        title: '👍 Task Selesai!',
        body: '"${task.title}" telah ditandai selesai.',
        notificationLayout: NotificationLayout.Default,
        // payload: {'taskId': task.id ?? '', 'action': 'completed'}, // Opsional, jika ingin ada aksi spesifik
      ),
      // Tidak ada parameter 'schedule', berarti notifikasi akan langsung muncul
    );
  }
}

///  ********************************************************************************************************************
///     NOTIFICATION CONTROLLER (Opsional, untuk menangani aksi notifikasi)
///  ********************************************************************************************************************
class NotificationController {

    /// Use this method to detect when a new notification or a schedule is created
    @pragma("vm:entry-point")
    static Future <void> onNotificationCreatedMethod(ReceivedNotification receivedNotification) async {
        // Your code goes here
        print('Notification created: ${receivedNotification.id}');
    }

    /// Use this method to detect every time that a new notification is displayed
    @pragma("vm:entry-point")
    static Future <void> onNotificationDisplayedMethod(ReceivedNotification receivedNotification) async {
        // Your code goes here
        print('Notification displayed: ${receivedNotification.id}');
    }

    /// Use this method to detect if the user dismissed a notification
    @pragma("vm:entry-point")
    static Future <void> onDismissActionReceivedMethod(ReceivedAction receivedAction) async {
        // Your code goes here
        print('Notification dismissed: ${receivedAction.id}');
    }

    /// Use this method to detect when the user taps on a notification or action button
    @pragma("vm:entry-point")
    static Future <void> onActionReceivedMethod(ReceivedAction receivedAction) async {
        // Your code goes here
        // Navigate to specific page
        print('Notification action received: ${receivedAction.id}');
        print('Payload: ${receivedAction.payload}');
        // Contoh: jika ada payload taskId, bisa navigasi ke detail task tersebut
        // MyApp.navigatorKey.currentState?.pushNamed('/task-detail', arguments: receivedAction.payload);
    }
}