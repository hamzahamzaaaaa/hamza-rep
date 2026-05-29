import 'dart:ui';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();
  static const String _groupKey = 'com.hamza.medbouh.DOWNLOAD_GROUP';
  static const String _channelId = 'download_complete_channel_v6';
  static const int activeDownloadId = 888;

  static Future<void> init({Function(String?)? onSelectNotification, Function(String)? onAction}) async {
    const AndroidInitializationSettings initializationSettingsAndroid = AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings initializationSettings = InitializationSettings(android: initializationSettingsAndroid);
    await _notificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse details) {
        if (details.payload != null && onSelectNotification != null) {
          onSelectNotification(details.payload);
        }
        if (details.actionId != null && onAction != null) {
          onAction(details.actionId!);
        }
      },
    );
  }

  static Future<void> showDownloadProgress({
    required int id,
    required String title,
    required String body,
    required int progress,
    required int maxProgress,
    List<AndroidNotificationAction>? actions,
    bool isDark = true,
  }) async {
    final bool indeterminate = progress <= 0;
    AndroidNotificationDetails androidPlatformChannelSpecifics = AndroidNotificationDetails(
      'download_channel_v4',
      'Download Progress',
      channelDescription: 'Real-time download speed and progress',
      importance: Importance.max,
      priority: Priority.high,
      onlyAlertOnce: true,
      showProgress: true,
      maxProgress: indeterminate ? 0 : maxProgress,
      progress: indeterminate ? 0 : progress,
      indeterminate: indeterminate,
      ongoing: true,
      autoCancel: false,
      showWhen: false,
      actions: actions,
      color: isDark ? const Color(0xFF1A141F) : const Color(0xFFFFFFFF),
      colorized: true,
      styleInformation: BigTextStyleInformation(
        body,
        contentTitle: title,
        summaryText: 'جاري التحميل',
      ),
    );
    NotificationDetails platformChannelSpecifics = NotificationDetails(android: androidPlatformChannelSpecifics);
    await _notificationsPlugin.show(id, title, body, platformChannelSpecifics);
  }

  static Future<void> showDownloadComplete({
    required int id,
    required String title,
    required String body,
    String? payload,
    String syncType = 'lrc', // Default to LRC
  }) async {
    // Enhance payload with background image path and sync type for instant pre-loading
    final String? enhancedPayload = (payload != null && payload.startsWith('play_'))
        ? '$payload|assets/images/reciter.png|$syncType'
        : payload;

    const AndroidNotificationDetails androidPlatformChannelSpecifics = AndroidNotificationDetails(
      _channelId,
      'Download Complete',
      channelDescription: 'Notifications for finished downloads',
      importance: Importance.max,
      priority: Priority.high,
      groupKey: _groupKey,
      setAsGroupSummary: false,
    );
    const NotificationDetails platformChannelSpecifics = NotificationDetails(android: androidPlatformChannelSpecifics);
    await _notificationsPlugin.show(id, title, body, platformChannelSpecifics, payload: enhancedPayload);
    await _showGroupSummary();
  }

  static Future<void> _showGroupSummary() async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics = AndroidNotificationDetails(
      _channelId,
      'Downloads',
      channelDescription: 'Group summary for downloads',
      importance: Importance.low,
      priority: Priority.low,
      groupKey: _groupKey,
      setAsGroupSummary: true,
      groupAlertBehavior: GroupAlertBehavior.summary,
    );
    const NotificationDetails platformChannelSpecifics = NotificationDetails(android: androidPlatformChannelSpecifics);
    await _notificationsPlugin.show(0, 'التحميلات المكتملة', 'تم تحميل عدة ملفات', platformChannelSpecifics);
  }

  static Future<void> cancel(int id) async {
    await _notificationsPlugin.cancel(id);
  }

  static Future<void> cancelAll() async {
    await _notificationsPlugin.cancelAll();
  }
}
