import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class SystemNotificationService {
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  static bool _isInitialized = false;
  static Function(String payload)? _onActionCallback;

  static const String channelId = 'dawaai_doses_channel_v2';
  static const String channelName = 'تنبيهات جرعات دوائي';
  static const String channelDesc =
      'إشعارات شريط الهاتف لمواعيد الأدوية والمسكنات الآمنة ونقص المخزون';

  /// تهيئة إشعارات شريط هاتف الأندرويد وطلب الصلاحيات
  static Future<void> init({Function(String payload)? onNotificationAction}) async {
    if (onNotificationAction != null) {
      _onActionCallback = onNotificationAction;
    }

    if (Platform.environment.containsKey('FLUTTER_TEST')) {
      _isInitialized = true;
      return;
    }

    if (_isInitialized) return;

    try {
      const androidSettings = AndroidInitializationSettings(
        '@drawable/ic_stat_medication',
      );
      const initSettings = InitializationSettings(android: androidSettings);

      await _plugin.initialize(
        settings: initSettings,
        onDidReceiveNotificationResponse: (NotificationResponse response) {
          final payload = response.payload;
          debugPrint('Notification clicked with payload: $payload, actionId: ${response.actionId}');
          if (payload != null && payload.isNotEmpty) {
            _onActionCallback?.call(payload);
          }
        },
      );

      // Check if app was launched from a notification response
      final launchDetails = await _plugin.getNotificationAppLaunchDetails();
      if (launchDetails != null && launchDetails.didNotificationLaunchApp) {
        final payload = launchDetails.notificationResponse?.payload;
        if (payload != null && payload.isNotEmpty) {
          Future.microtask(() {
            _onActionCallback?.call(payload);
          });
        }
      }

      // طلب إذن الإشعارات لهواتف Android 13+ (Infinix, Samsung, Xiaomi, etc.)
      final androidPlatform = _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      if (androidPlatform != null) {
        await androidPlatform.requestNotificationsPermission();
        await androidPlatform.requestExactAlarmsPermission();

        // إنشاء قناة الإشعارات ذات الأولوية القصوى
        const channel = AndroidNotificationChannel(
          channelId,
          channelName,
          description: channelDesc,
          importance: Importance.max,
          enableVibration: true,
          playSound: true,
          showBadge: true,
        );
        await androidPlatform.createNotificationChannel(channel);
      }

      _isInitialized = true;
      debugPrint('SystemNotificationService initialized successfully.');
    } catch (e) {
      debugPrint('Error initializing SystemNotificationService: $e');
    }
  }

  static void setActionCallback(Function(String payload) callback) {
    _onActionCallback = callback;
  }

  /// إرسال إشعار حقيقي إلى شريط إشعارات الهاتف العلوي (Notification Tray / Status Bar)
  /// مع زر مباشر "أخذت الجرعة ✓" لاعتبار النقر تأكيداً فورياً لأخذ الجرعة
  static Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
    bool showAction = true,
  }) async {
    if (Platform.environment.containsKey('FLUTTER_TEST')) return;
    try {
      if (!_isInitialized) {
        await init();
      }

      final androidDetails = AndroidNotificationDetails(
        channelId,
        channelName,
        channelDescription: channelDesc,
        importance: Importance.max,
        priority: Priority.high,
        showWhen: true,
        enableVibration: true,
        playSound: true,
        icon: '@drawable/ic_stat_medication',
        color: const Color(0xFF0D9488),
        category: AndroidNotificationCategory.reminder,
        visibility: NotificationVisibility.public,
        actions: showAction
            ? <AndroidNotificationAction>[
                const AndroidNotificationAction(
                  'take_dose_action',
                  '✓ أخذت الجرعة الآن',
                  showsUserInterface: false,
                  cancelNotification: true,
                ),
              ]
            : null,
      );

      final details = NotificationDetails(android: androidDetails);
      await _plugin.show(
        id: id,
        title: title,
        body: body,
        notificationDetails: details,
        payload: payload,
      );
    } catch (e) {
      debugPrint('Error showing system notification: $e');
    }
  }

  /// إلغاء إشعار محدد
  static Future<void> cancel(int id) async {
    if (Platform.environment.containsKey('FLUTTER_TEST')) return;
    await _plugin.cancel(id: id);
  }
}

