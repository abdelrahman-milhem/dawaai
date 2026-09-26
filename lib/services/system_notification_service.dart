import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'storage_service.dart';
import 'reminder_service.dart';

/// معالج النقر على الإشعارات عندما يكون التطبيق في الخلفية أو مغلقاً تماماً
@pragma('vm:entry-point')
void notificationTapBackground(NotificationResponse response) async {
  WidgetsFlutterBinding.ensureInitialized();
  final payload = response.payload;
  debugPrint('Dawaai: Background notification tapped with payload: $payload');
  if (payload != null && payload.isNotEmpty) {
    try {
      final storage = await StorageService.init();
      final reminder = ReminderService(storage);
      await reminder.handleNotificationDoseConfirmation(payload);
    } catch (e) {
      debugPrint('Dawaai: Background tap handling failed: $e');
    }
  }
}

class SystemNotificationService {
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  static bool _isInitialized = false;
  static Function(String payload)? _onActionCallback;

  static const String channelId = 'dawaai_doses_channel_v2';
  static const String channelName = 'تنبيهات جرعات دوائي';
  static const String channelDesc =
      'إشعارات شريط الهاتف الدقيقة لمواعيد الأدوية والمسكنات الآمنة ونقص المخزون حتى والتطبيق مغلق';

  /// تهيئة إشعارات شريط هاتف الأندرويد وطلب الصلاحيات والتوقيت
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
      // تهيئة قاعدة بيانات المناطق الزمنية
      tz.initializeTimeZones();

      const androidSettings = AndroidInitializationSettings(
        '@drawable/ic_stat_medication',
      );
      const initSettings = InitializationSettings(android: androidSettings);

      await _plugin.initialize(
        settings: initSettings,
        onDidReceiveNotificationResponse: (NotificationResponse response) {
          final payload = response.payload;
          debugPrint('Dawaai: Foreground notification tapped with payload: $payload');
          if (payload != null && payload.isNotEmpty) {
            _onActionCallback?.call(payload);
          }
        },
        onDidReceiveBackgroundNotificationResponse: notificationTapBackground,
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
      debugPrint('SystemNotificationService initialized successfully with background action support.');
    } catch (e) {
      debugPrint('Error initializing SystemNotificationService: $e');
    }
  }

  static void setActionCallback(Function(String payload) callback) {
    _onActionCallback = callback;
  }

  /// إرسال إشعار فوري إلى شريط إشعارات الهاتف العلوي
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
                  showsUserInterface: true,
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

  /// جدولة تنبيه بنظام Android Alarm Manager المباشر (Exact Alarm)
  /// ليعمل حتى والتطبيق مغلق تماماً أو الهاتف في وضع السكون (Doze Mode)
  static Future<void> scheduleExactNativeReminder({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDateTime,
    String? payload,
  }) async {
    if (Platform.environment.containsKey('FLUTTER_TEST')) return;
    try {
      if (!_isInitialized) {
        await init();
      }
      if (scheduledDateTime.isBefore(DateTime.now())) return;

      final tzDate = tz.TZDateTime.from(scheduledDateTime, tz.local);

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
        actions: <AndroidNotificationAction>[
          const AndroidNotificationAction(
            'take_dose_action',
            '✓ أخذت الجرعة الآن',
            showsUserInterface: true,
            cancelNotification: true,
          ),
        ],
      );

      final details = NotificationDetails(android: androidDetails);

      await _plugin.zonedSchedule(
        id: id,
        title: title,
        body: body,
        scheduledDate: tzDate,
        notificationDetails: details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        payload: payload,
      );
      debugPrint('Dawaai: Exact alarm scheduled for: $scheduledDateTime (id: $id)');
    } catch (e) {
      debugPrint('Error scheduling exact native notification: $e');
    }
  }

  /// إلغاء إشعار محدد
  static Future<void> cancel(int id) async {
    if (Platform.environment.containsKey('FLUTTER_TEST')) return;
    await _plugin.cancel(id: id);
  }

  /// إلغاء كافة التنبيهات المجدولة لإعادة ضبطها
  static Future<void> cancelAll() async {
    if (Platform.environment.containsKey('FLUTTER_TEST')) return;
    await _plugin.cancelAll();
  }
}

