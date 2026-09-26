import '../ar.dart';
import 'dart:io';
import 'dart:async';

import 'package:flutter/material.dart';

import '../models/medicine.dart';
import '../models/dose_log.dart';
import '../models/app_notification.dart';
import '../utils/date_utils.dart';
import 'storage_service.dart';
import 'system_notification_service.dart';
import 'medical_time_service.dart';

class PainkillerSafetyInfo {
  final bool isSafeNow;
  final bool limitReached;
  final int dosesTakenToday;
  final int maxDailyDoses;
  final Duration? timeSinceLastDose;
  final Duration? remainingCooldown;
  final String statusMessage;
  final double progress; // 0.0 to 1.0 (cooldown progress)

  PainkillerSafetyInfo({
    required this.isSafeNow,
    required this.limitReached,
    required this.dosesTakenToday,
    required this.maxDailyDoses,
    this.timeSinceLastDose,
    this.remainingCooldown,
    required this.statusMessage,
    required this.progress,
  });
}

class MedicationSafetyInfo {
  final bool isSafeNow;
  final bool limitReached;
  final int dosesTakenToday;
  final int maxDailyDoses;
  final Duration? timeSinceLastDose;
  final Duration? remainingCooldown;
  final int safeIntervalHours;
  final DateTime? lastTakenAt;
  final String statusMessage;
  final String warningTitle;
  final String warningDetails;
  final double progress;
  final bool isEarlyIntake;

  MedicationSafetyInfo({
    required this.isSafeNow,
    this.limitReached = false,
    required this.dosesTakenToday,
    required this.maxDailyDoses,
    this.timeSinceLastDose,
    this.remainingCooldown,
    required this.safeIntervalHours,
    this.lastTakenAt,
    required this.statusMessage,
    this.warningTitle = '',
    this.warningDetails = '',
    required this.progress,
    this.isEarlyIntake = false,
  });
}

class ScheduledDoseSlot {
  final Medicine medicine;
  final TimeOfDay time;
  final DateTime scheduledDateTime;
  final bool isTaken;
  final DoseLog? doseLog;
  final bool isDynamicallyRescheduled;
  final String? rescheduleReason;

  ScheduledDoseSlot({
    required this.medicine,
    required this.time,
    required this.scheduledDateTime,
    required this.isTaken,
    this.doseLog,
    this.isDynamicallyRescheduled = false,
    this.rescheduleReason,
  });

  bool get isPast => MedicalTimeService.instance.now().isAfter(scheduledDateTime);
  bool get isDueNow {
    final diff = MedicalTimeService.instance.now().difference(scheduledDateTime).inMinutes.abs();
    return diff <= 45;
  }
}

class NextDoseInfo {
  final Medicine medicine;
  final DateTime nextDateTime;
  final TimeOfDay timeOfDay;
  final bool isToday;
  final bool isTomorrow;
  final bool isOverdue; // Past scheduled time and not taken
  final bool isDueNow; // Within 45 minutes of scheduled time
  final bool isAllTodayCompleted; // All scheduled doses for today were completed, next is tomorrow
  final String formattedTime;
  final String relativeTimeText;
  final String dateBadgeText;
  final int doseNumberToday; // e.g. 1st dose, 2nd dose
  final int totalDosesToday; // e.g. out of 3
  final DateTime? lastTakenDateTime; // تاريخ ووقت الجرعة السابقة
  final String lastTakenFormattedText; // نص الجرعة السابقة (مثلاً: اليوم 02:30 م - منذ ساعتين)
  final String nextDoseFullText; // نص الجرعة القادمة الكامل (مثلاً: اليوم 08:30 م)
  final String remainingCountdownText; // نص الوقت المتبقي الصريح (مثلاً: متبقي 3 س و 45 د)
  final bool isDynamicallyRescheduled;
  final String? rescheduleNotice;
  final int safeIntervalHours;

  NextDoseInfo({
    required this.medicine,
    required this.nextDateTime,
    required this.timeOfDay,
    required this.isToday,
    required this.isTomorrow,
    required this.isOverdue,
    required this.isDueNow,
    required this.isAllTodayCompleted,
    required this.formattedTime,
    required this.relativeTimeText,
    required this.dateBadgeText,
    this.doseNumberToday = 1,
    this.totalDosesToday = 1,
    this.lastTakenDateTime,
    required this.lastTakenFormattedText,
    required this.nextDoseFullText,
    required this.remainingCountdownText,
    this.isDynamicallyRescheduled = false,
    this.rescheduleNotice,
    this.safeIntervalHours = 8,
  });
}

class ReminderService extends ChangeNotifier with WidgetsBindingObserver {
  final StorageService storageService;
  Timer? _tickerTimer;
  AppNotificationItem? _latestActiveBanner;
  bool _isAppInForeground = true;

  /// Returns trusted, UTC-synchronized medical time
  DateTime get _now => MedicalTimeService.instance.now();

  ReminderService(this.storageService) {
    WidgetsBinding.instance.addObserver(this);
    _startPeriodicCheck();
    // Immediate check on startup without waiting
    Future.microtask(() {
      checkReminders();
      scheduleAllFutureNativeAlarms();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _isAppInForeground = true;
      checkReminders();
      _startPeriodicCheck();
    } else if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      _isAppInForeground = false;
      _tickerTimer?.cancel();
    }
  }

  AppNotificationItem? get latestActiveBanner => _latestActiveBanner;

  void dismissBanner() {
    _latestActiveBanner = null;
    notifyListeners();
  }

  void _startPeriodicCheck() {
    _tickerTimer?.cancel();
    if (!_isAppInForeground) return;
    if (Platform.environment.containsKey('FLUTTER_TEST')) return;

    // Adaptive battery-saving interval: 30 seconds when active, 0 when backgrounded
    _tickerTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (_isAppInForeground) {
        checkReminders();
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _tickerTimer?.cancel();
    super.dispose();
  }

  /// Check all medicines and fire notifications if appropriate
  void checkReminders() {
    final activeProfileId = storageService.getActiveProfileId();
    final medicines = storageService
        .getMedicines(forProfileId: activeProfileId)
        .where((m) => m.isActive)
        .toList();
    final logs = storageService.getLogs();
    final now = _now;

    for (final med in medicines) {
      if (med.isPainkiller) {
        final safety = getPainkillerSafety(med, logs);
        if (safety.isSafeNow &&
            !safety.limitReached &&
            safety.timeSinceLastDose != null) {
          final hoursAgo = safety.timeSinceLastDose!.inHours;
          if (hoursAgo >= med.minSafeIntervalHours &&
              hoursAgo <= med.minSafeIntervalHours + 1) {
            final recentNotifs = storageService.getNotifications().where(
              (n) =>
                  n.medicineId == med.id &&
                  n.type == NotificationType.painkillerSafe &&
                  now.difference(n.timestamp).inHours <
                      med.minSafeIntervalHours,
            );
            if (recentNotifs.isEmpty) {
              triggerPainkillerSafeNotification(med);
            }
          }
        }
      } else {
        // If there's a dynamic rescheduled next dose time that matches now
        if (med.dynamicNextDoseTime != null) {
          final diff = now.difference(med.dynamicNextDoseTime!).inMinutes;
          if (diff >= -1 && diff <= 60) {
            final alreadyLogged = logs.any(
              (l) =>
                  l.medicineId == med.id &&
                  l.takenAt.year == now.year &&
                  l.takenAt.month == now.month &&
                  l.takenAt.day == now.day &&
                  (l.takenAt
                          .difference(med.dynamicNextDoseTime!)
                          .inMinutes
                          .abs() <
                      60),
            );
            if (!alreadyLogged) {
              final recentNotifs = storageService.getNotifications().where(
                (n) =>
                    n.medicineId == med.id &&
                    n.type == NotificationType.treatmentReminder &&
                    now.difference(n.timestamp).inMinutes < 60,
              );
              if (recentNotifs.isEmpty) {
                triggerDynamicDoseReminderNotification(
                  med,
                  med.dynamicNextDoseTime!,
                );
              }
            }
          }
        } else {
          // Standard schedule check
          for (final time in med.scheduledTimes) {
            final scheduledToday = DateTime(
              now.year,
              now.month,
              now.day,
              time.hour,
              time.minute,
            );
            final diffMinutes = now.difference(scheduledToday).inMinutes;
            // Check if due right now or within the past 60 minutes and hasn't been logged yet
            if (diffMinutes >= -1 && diffMinutes <= 60) {
              final alreadyLogged = logs.any(
                (l) =>
                    l.medicineId == med.id &&
                    l.takenAt.year == now.year &&
                    l.takenAt.month == now.month &&
                    l.takenAt.day == now.day &&
                    (l.takenAt.difference(scheduledToday).inMinutes.abs() < 60),
              );
              if (!alreadyLogged) {
                final recentNotifs = storageService.getNotifications().where(
                  (n) =>
                      n.medicineId == med.id &&
                      n.type == NotificationType.treatmentReminder &&
                      n.timestamp.year == now.year &&
                      n.timestamp.month == now.month &&
                      n.timestamp.day == now.day &&
                      (n.timestamp.difference(scheduledToday).inMinutes.abs() <
                          60),
                );
                if (recentNotifs.isEmpty) {
                  triggerTreatmentReminderNotification(med, time);
                }
              }
            }
          }
        }
      }

      // Check stock warning
      if (med.isLowStock && !med.isOutOfStock) {
        final recentStockNotifs = storageService.getNotifications().where(
          (n) =>
              n.medicineId == med.id &&
              n.type == NotificationType.lowStock &&
              now.difference(n.timestamp).inHours < 24,
        );
        if (recentStockNotifs.isEmpty) {
          triggerLowStockNotification(med);
        }
      }
    }
  }

  /// حساب الفاصل الزمني الآمن الفعلي للدواء بالساعات
  int getSafeIntervalHours(Medicine medicine) {
    if (medicine.isTreatment) {
      if (medicine.intervalHours > 0) return medicine.intervalHours;
      if (medicine.scheduledTimes.isNotEmpty) {
        final n = medicine.scheduledTimes.length;
        if (n == 1) return 24;
        if (n == 2) return 12;
        if (n == 3) return 8;
        if (n == 4) return 6;
        return (24 ~/ n).clamp(4, 24);
      }
      return 8;
    } else {
      if (medicine.minSafeIntervalHours > 0) return medicine.minSafeIntervalHours;
      if (medicine.intervalHours > 0) return medicine.intervalHours;
      return 6;
    }
  }

  /// فحص الأمان الطبي الدقيق لجميع الأدوية (علاج ومسكنات) لمنع التناول المبكر ومضاعفة الجرعة
  MedicationSafetyInfo getMedicationSafety(
    Medicine medicine, [
    List<DoseLog>? allLogs,
    DateTime? nowTime,
  ]) {
    final logs = allLogs ?? storageService.getLogs();
    final now = nowTime ?? _now;
    final safeInterval = getSafeIntervalHours(medicine);
    final cooldownDuration = Duration(hours: safeInterval);

    final recentLogs = logs
        .where(
          (l) =>
              l.medicineId == medicine.id &&
              now.difference(l.takenAt).inHours < 48,
        )
        .toList()
      ..sort((a, b) => b.takenAt.compareTo(a.takenAt));

    final lastTakenAt = recentLogs.isNotEmpty
        ? recentLogs.first.takenAt
        : medicine.lastTakenTime;

    int dosesToday = recentLogs
        .where((l) => AppDateUtils.isSameDay(l.takenAt, now))
        .length;
    if (dosesToday == 0 &&
        medicine.lastTakenTime != null &&
        AppDateUtils.isSameDay(medicine.lastTakenTime!, now)) {
      dosesToday = 1;
    }

    if (medicine.isPainkiller) {
      final limitReached = dosesToday >= medicine.maxDailyDoses;
      if (lastTakenAt == null) {
        return MedicationSafetyInfo(
          isSafeNow: true,
          limitReached: false,
          dosesTakenToday: 0,
          maxDailyDoses: medicine.maxDailyDoses,
          safeIntervalHours: safeInterval,
          statusMessage: Ar.safePainkillerNotice,
          progress: 1.0,
        );
      }

      final timeSinceLastDose = now.difference(lastTakenAt);

      if (limitReached) {
        return MedicationSafetyInfo(
          isSafeNow: false,
          limitReached: true,
          dosesTakenToday: dosesToday,
          maxDailyDoses: medicine.maxDailyDoses,
          timeSinceLastDose: timeSinceLastDose,
          safeIntervalHours: safeInterval,
          lastTakenAt: lastTakenAt,
          statusMessage: Ar.statusPainkillerLimitReached(
            dosesToday,
            medicine.maxDailyDoses,
          ),
          warningTitle: 'تجاوز الحد الأقصى للمسكن',
          warningDetails: Ar.limitReachedWarning(medicine.maxDailyDoses),
          progress: 1.0,
        );
      }

      if (timeSinceLastDose >= cooldownDuration) {
        return MedicationSafetyInfo(
          isSafeNow: true,
          limitReached: false,
          dosesTakenToday: dosesToday,
          maxDailyDoses: medicine.maxDailyDoses,
          timeSinceLastDose: timeSinceLastDose,
          safeIntervalHours: safeInterval,
          lastTakenAt: lastTakenAt,
          statusMessage: Ar.safePainkillerNotice,
          progress: 1.0,
        );
      } else {
        final remaining = cooldownDuration - timeSinceLastDose;
        final totalMinutes = cooldownDuration.inMinutes;
        final elapsedMinutes = timeSinceLastDose.inMinutes;
        final progress = totalMinutes > 0
            ? (elapsedMinutes / totalMinutes).clamp(0.0, 1.0)
            : 1.0;

        final remainingHours = remaining.inHours;
        final remainingMins = remaining.inMinutes % 60;
        final timeStr = remainingHours > 0
            ? Ar.remainingHoursAndMins(remainingHours, remainingMins)
            : Ar.remainingMinsOnly(remainingMins);

        return MedicationSafetyInfo(
          isSafeNow: false,
          limitReached: false,
          dosesTakenToday: dosesToday,
          maxDailyDoses: medicine.maxDailyDoses,
          timeSinceLastDose: timeSinceLastDose,
          remainingCooldown: remaining,
          safeIntervalHours: safeInterval,
          lastTakenAt: lastTakenAt,
          statusMessage: Ar.statusPainkillerWait(timeStr),
          warningTitle: Ar.earlyIntakeWarningTitle,
          warningDetails: Ar.cooldownWarning(remaining.inMinutes),
          progress: progress,
          isEarlyIntake: true,
        );
      }
    } else {
      // Regular Treatment (علاج يومي منتظم)
      if (lastTakenAt == null) {
        return MedicationSafetyInfo(
          isSafeNow: true,
          limitReached: false,
          dosesTakenToday: 0,
          maxDailyDoses: medicine.scheduledTimes.isNotEmpty
              ? medicine.scheduledTimes.length
              : 4,
          safeIntervalHours: safeInterval,
          statusMessage: 'الموعد آمن وجاهز للتناول',
          progress: 1.0,
        );
      }

      final timeSinceLastDose = now.difference(lastTakenAt);

      if (timeSinceLastDose < cooldownDuration) {
        final remaining = cooldownDuration - timeSinceLastDose;
        final totalMinutes = cooldownDuration.inMinutes;
        final elapsedMinutes = timeSinceLastDose.inMinutes;
        final progress = totalMinutes > 0
            ? (elapsedMinutes / totalMinutes).clamp(0.0, 1.0)
            : 1.0;

        final remHours = remaining.inHours;
        final remMinsOnly = remaining.inMinutes % 60;
        final remText = Ar.earlyIntakeCooldownRemaining(remHours, remMinsOnly);
        final hoursAgo = timeSinceLastDose.inHours;
        final minsAgo = timeSinceLastDose.inMinutes % 60;
        final agoText = hoursAgo > 0
            ? '$hoursAgo ساعة و $minsAgo دقيقة'
            : '$minsAgo دقيقة';

        return MedicationSafetyInfo(
          isSafeNow: false,
          limitReached: false,
          dosesTakenToday: dosesToday,
          maxDailyDoses: medicine.scheduledTimes.isNotEmpty
              ? medicine.scheduledTimes.length
              : 4,
          timeSinceLastDose: timeSinceLastDose,
          remainingCooldown: remaining,
          safeIntervalHours: safeInterval,
          lastTakenAt: lastTakenAt,
          statusMessage: 'تناول مبكر! متبقي $remText لاكتمال الفاصل الآمن ($safeInterval ساعات)',
          warningTitle: Ar.earlyIntakeWarningTitle,
          warningDetails:
              '${Ar.earlyIntakeWarningDesc}\n\n${Ar.earlyIntakeLastDoseInfo(agoText, safeInterval)}',
          progress: progress,
          isEarlyIntake: true,
        );
      }

      return MedicationSafetyInfo(
        isSafeNow: true,
        limitReached: false,
        dosesTakenToday: dosesToday,
        maxDailyDoses: medicine.scheduledTimes.isNotEmpty
            ? medicine.scheduledTimes.length
            : 4,
        timeSinceLastDose: timeSinceLastDose,
        safeIntervalHours: safeInterval,
        lastTakenAt: lastTakenAt,
        statusMessage: 'الموعد آمن طبياً',
        progress: 1.0,
      );
    }
  }

  /// Calculates safe interval information for painkillers (توافقية كاملة)
  PainkillerSafetyInfo getPainkillerSafety(
    Medicine medicine, [
    List<DoseLog>? allLogs,
  ]) {
    final s = getMedicationSafety(medicine, allLogs);
    return PainkillerSafetyInfo(
      isSafeNow: s.isSafeNow,
      limitReached: s.limitReached,
      dosesTakenToday: s.dosesTakenToday,
      maxDailyDoses: s.maxDailyDoses,
      timeSinceLastDose: s.timeSinceLastDose,
      remainingCooldown: s.remainingCooldown,
      statusMessage: s.statusMessage,
      progress: s.progress,
    );
  }

  /// CORE MEDICAL REQUIREMENT: Record dose intake with STRICT dynamic safe interval enforcement
  /// When a user took their dose late, the next appointment is GUARANTEED to be at least safeIntervalHours away!
  Future<void> recordDoseIntake({
    required Medicine medicine,
    required int pillsTaken,
    int? painLevel,
    String? notes,
    DateTime? customTime,
  }) async {
    final now = customTime ?? _now;
    final safeIntervalHours = getSafeIntervalHours(medicine);
    final earliestSafeTime = now.add(Duration(hours: safeIntervalHours));

    DateTime recalculatedNextDose;
    String rescheduleNote;

    if (medicine.scheduledTimes.isNotEmpty) {
      final sortedTimes = List<TimeOfDay>.from(medicine.scheduledTimes)
        ..sort(
          (a, b) => (a.hour * 60 + a.minute).compareTo(b.hour * 60 + b.minute),
        );
      final previousLogsCount = storageService
          .getLogs()
          .where(
            (l) =>
                l.medicineId == medicine.id &&
                AppDateUtils.isSameDay(l.takenAt, now),
          )
          .length;
      final totalToday = previousLogsCount + 1;

      DateTime candidateNext;
      if (totalToday < sortedTimes.length) {
        final nextT = sortedTimes[totalToday];
        candidateNext = DateTime(
          now.year,
          now.month,
          now.day,
          nextT.hour,
          nextT.minute,
        );
      } else {
        final tomorrow = now.add(const Duration(days: 1));
        final firstT = sortedTimes.first;
        candidateNext = DateTime(
          tomorrow.year,
          tomorrow.month,
          tomorrow.day,
          firstT.hour,
          firstT.minute,
        );
      }

      // تطبيق الفاصل الزمني الآمن طبياً:
      // إذا كان الموعد التالي المجدول يأتي قبل اكتمال الفاصل الآمن من وقت التناول الفعلي:
      if (candidateNext.isBefore(earliestSafeTime)) {
        recalculatedNextDose = earliestSafeTime;
        final newTimeFormatted = AppDateUtils.formatTime(earliestSafeTime);
        rescheduleNote = Ar.delayedRescheduledSafeNotice(
          newTimeFormatted,
          safeIntervalHours,
        );
      } else {
        recalculatedNextDose = candidateNext;
        final nextTimeFormatted = AppDateUtils.formatTime(recalculatedNextDose);
        rescheduleNote = Ar.rescheduleNoteText(nextTimeFormatted);
      }
    } else {
      recalculatedNextDose = earliestSafeTime;
      final nextTimeFormatted = AppDateUtils.formatTime(recalculatedNextDose);
      rescheduleNote = Ar.rescheduleNoteText(nextTimeFormatted);
    }

    final log = DoseLog(
      id: 'log_${now.millisecondsSinceEpoch}',
      medicineId: medicine.id,
      medicineName: medicine.name,
      takenAt: now,
      pillsTaken: pillsTaken,
      isPainkiller: medicine.isPainkiller,
      painLevel: painLevel,
      notes: notes,
    );

    await storageService.addDoseLog(
      log,
      recalculatedNextDose: recalculatedNextDose,
      note: rescheduleNote,
    );

    // Show instant dynamic confirmation banner
    final alertItem = AppNotificationItem(
      id: 'dynamic_alert_${now.millisecondsSinceEpoch}',
      title: Ar.notifRescheduleTitle,
      message: rescheduleNote,
      type: NotificationType.treatmentReminder,
      medicineId: medicine.id,
      medicineName: medicine.name,
      timestamp: now,
    );

    _latestActiveBanner = alertItem;
    notifyListeners();

    // إعادة جدولة جميع التنبيهات الأصلية لنظام أندرويد لتعمل حتى والتطبيق مغلق
    await scheduleAllFutureNativeAlarms();
  }

  /// جدولة جميع التنبيهات المستقبلية كمنبهات نظام دقيقة (Exact Native Alarms) للأيام القادمة
  Future<void> scheduleAllFutureNativeAlarms() async {
    if (Platform.environment.containsKey('FLUTTER_TEST')) return;
    try {
      final medicines = storageService.getMedicines().where((m) => m.isActive).toList();
      final now = _now;

      // إلغاء التنبيهات السابقة وإعادة جدولتها بدقة
      await SystemNotificationService.cancelAll();

      for (final med in medicines) {
        if (med.dynamicNextDoseTime != null && med.dynamicNextDoseTime!.isAfter(now)) {
          final dynTime = med.dynamicNextDoseTime!;
          final id = (med.id.hashCode.abs() % 100000);
          final timeStr = AppDateUtils.formatTime(dynTime);
          await SystemNotificationService.scheduleExactNativeReminder(
            id: id,
            title: Ar.notifMedTimeTitle,
            body: '${med.name}: حان موعد جرعتك ($timeStr). اضغط لتأكيد الأخذ.',
            scheduledDateTime: dynTime,
            payload: 'take_dose_${med.id}',
          );
        } else if (med.scheduledTimes.isNotEmpty) {
          // جدولة للأيام الـ 7 القادمة
          for (int day = 0; day < 7; day++) {
            final targetDate = now.add(Duration(days: day));
            for (int tIdx = 0; tIdx < med.scheduledTimes.length; tIdx++) {
              final tod = med.scheduledTimes[tIdx];
              final scheduledDateTime = DateTime(
                targetDate.year,
                targetDate.month,
                targetDate.day,
                tod.hour,
                tod.minute,
              );
              if (scheduledDateTime.isAfter(now)) {
                final id = (med.id.hashCode.abs() % 10000) * 100 + day * 10 + tIdx;
                final timeStr = AppDateUtils.formatTime(scheduledDateTime);
                await SystemNotificationService.scheduleExactNativeReminder(
                  id: id,
                  title: Ar.notifMedTimeTitle,
                  body: '${med.name}: حان موعد جرعتك ($timeStr). اضغط لتأكيد الأخذ.',
                  scheduledDateTime: scheduledDateTime,
                  payload: 'take_dose_${med.id}',
                );
              }
            }
          }
        }
      }
    } catch (e) {
      debugPrint('Dawaai: scheduleAllFutureNativeAlarms error: $e');
    }
  }

  /// Snooze dose for X minutes
  Future<void> snoozeDose(Medicine medicine, int minutes) async {
    final now = _now;
    final snoozeTime = now.add(Duration(minutes: minutes));
    final timeStr = AppDateUtils.formatTime(snoozeTime);

    final item = AppNotificationItem(
      id: 'snooze_${now.millisecondsSinceEpoch}',
      title: Ar.notifSnoozeTitle(minutes),
      message: Ar.notifSnoozeMsg(medicine.name, timeStr),
      type: NotificationType.treatmentReminder,
      medicineId: medicine.id,
      medicineName: medicine.name,
      timestamp: now,
    );

    _latestActiveBanner = item;
    notifyListeners();
  }

  /// Builds today's schedule of doses for treatment medications with dynamic rescheduling!
  List<ScheduledDoseSlot> getTodayScheduledSlots({String? profileId}) {
    final medicines = storageService
        .getMedicines(forProfileId: profileId)
        .where((m) => m.isActive && m.isTreatment)
        .toList();
    final logs = storageService.getLogs();
    final now = _now;

    List<ScheduledDoseSlot> slots = [];

    for (final med in medicines) {
      // Check if there is an active dynamic rescheduled dose for today
      if (med.dynamicNextDoseTime != null &&
          AppDateUtils.isSameDay(med.dynamicNextDoseTime!, now)) {
        final dynTime = med.dynamicNextDoseTime!;
        final timeOfDay = TimeOfDay(hour: dynTime.hour, minute: dynTime.minute);

        final matchingLog = logs.cast<DoseLog?>().firstWhere(
          (l) =>
              l != null &&
              l.medicineId == med.id &&
              AppDateUtils.isSameDay(l.takenAt, now) &&
              (l.takenAt.isAfter(
                dynTime.subtract(const Duration(minutes: 30)),
              )),
          orElse: () => null,
        );

        slots.add(
          ScheduledDoseSlot(
            medicine: med,
            time: timeOfDay,
            scheduledDateTime: dynTime,
            isTaken: matchingLog != null,
            doseLog: matchingLog,
            isDynamicallyRescheduled: true,
            rescheduleReason: med.dynamicRescheduleNote,
          ),
        );
      } else {
        // Normal schedule
        for (final time in med.scheduledTimes) {
          final slotDateTime = DateTime(
            now.year,
            now.month,
            now.day,
            time.hour,
            time.minute,
          );

          final matchingLog = logs.cast<DoseLog?>().firstWhere(
            (l) =>
                l != null &&
                l.medicineId == med.id &&
                AppDateUtils.isSameDay(l.takenAt, now) &&
                (l.takenAt.difference(slotDateTime).inMinutes.abs() < 120),
            orElse: () => null,
          );

          slots.add(
            ScheduledDoseSlot(
              medicine: med,
              time: time,
              scheduledDateTime: slotDateTime,
              isTaken: matchingLog != null,
              doseLog: matchingLog,
            ),
          );
        }
      }
    }

    slots.sort((a, b) => a.scheduledDateTime.compareTo(b.scheduledDateTime));
    return slots;
  }

  /// USER REQUIREMENT: In the main list, ONLY show the next dose for each medicine.
  /// As soon as taken, it advances to the next dose and removes the old one!
  List<NextDoseInfo> getNextDosesForAllMedicines({String? profileId}) {
    final medicines = storageService
        .getMedicines(forProfileId: profileId)
        .where((m) => m.isActive && m.isTreatment)
        .toList();
    final logs = storageService.getLogs();

    List<NextDoseInfo> list = [];
    for (final med in medicines) {
      final info = getNextDoseForMedicine(med, logs);
      if (info != null) {
        list.add(info);
      }
    }

    // Sort by chronological order of next dose
    list.sort((a, b) => a.nextDateTime.compareTo(b.nextDateTime));
    return list;
  }

  /// Calculates ONLY the next upcoming dose for a single medicine with strict clinical safe interval enforcement!
  NextDoseInfo? getNextDoseForMedicine(
    Medicine medicine, [
    List<DoseLog>? allLogs,
  ]) {
    if (!medicine.isActive) return null;
    final logs = allLogs ?? storageService.getLogs();
    final now = _now;
    final safeInterval = getSafeIntervalHours(medicine);

    // تفقد آخر جرعة تم تناولها (من السجل أو آخر جرعة مسجلة)
    final recentLogs = logs
        .where((l) => l.medicineId == medicine.id)
        .toList()
      ..sort((a, b) => b.takenAt.compareTo(a.takenAt));
    final lastLog = recentLogs.isNotEmpty ? recentLogs.first : null;
    final lastTakenTime = lastLog?.takenAt ?? medicine.lastTakenTime;
    final earliestSafeTime = lastTakenTime?.add(Duration(hours: safeInterval));

    final todayLogs = logs
        .where(
          (l) =>
              l.medicineId == medicine.id &&
              AppDateUtils.isSameDay(l.takenAt, now),
        )
        .toList();

    int dosesTakenCount = todayLogs.length;
    if (dosesTakenCount == 0 &&
        medicine.lastTakenTime != null &&
        AppDateUtils.isSameDay(medicine.lastTakenTime!, now)) {
      dosesTakenCount = 1;
    }

    final totalDosesCount = medicine.scheduledTimes.isNotEmpty
        ? medicine.scheduledTimes.length
        : (medicine.intervalHours > 0
            ? (24 ~/ medicine.intervalHours).clamp(1, 6)
            : (24 ~/ safeInterval).clamp(1, 6));

    DateTime targetDateTime;
    TimeOfDay targetTod;
    bool isToday;
    bool isTomorrow;
    bool isAllTodayCompleted;
    int doseNum;
    bool isRescheduled = false;
    String? reschedNotice;

    // 1. المواعيد اليومية المجدولة
    if (medicine.scheduledTimes.isNotEmpty) {
      final times = List<TimeOfDay>.from(medicine.scheduledTimes);

      if (dosesTakenCount < times.length) {
        final candidateTime = times[dosesTakenCount];
        final candidate = DateTime(
          now.year,
          now.month,
          now.day,
          candidateTime.hour,
          candidateTime.minute,
        );

        if (earliestSafeTime != null && candidate.isBefore(earliestSafeTime)) {
          targetDateTime = earliestSafeTime;
          targetTod = TimeOfDay(
            hour: targetDateTime.hour,
            minute: targetDateTime.minute,
          );
          isRescheduled = true;
          final formattedT = AppDateUtils.formatTime(targetDateTime);
          reschedNotice = Ar.delayedRescheduledSafeNotice(
            formattedT,
            safeInterval,
          );
        } else {
          targetDateTime = candidate;
          targetTod = candidateTime;
        }

        isToday = AppDateUtils.isSameDay(targetDateTime, now);
        isTomorrow = AppDateUtils.isTomorrow(targetDateTime, now);
        isAllTodayCompleted = false;
        doseNum = (dosesTakenCount + 1).clamp(1, totalDosesCount);
      } else {
        // جميع جرعات اليوم اكتملت -> أول جرعة غداً
        final firstTomorrow = times.first;
        final tomorrow = now.add(const Duration(days: 1));
        final candidate = DateTime(
          tomorrow.year,
          tomorrow.month,
          tomorrow.day,
          firstTomorrow.hour,
          firstTomorrow.minute,
        );

        if (earliestSafeTime != null && candidate.isBefore(earliestSafeTime)) {
          targetDateTime = earliestSafeTime;
          targetTod = TimeOfDay(
            hour: targetDateTime.hour,
            minute: targetDateTime.minute,
          );
          isRescheduled = true;
          final formattedT = AppDateUtils.formatTime(targetDateTime);
          reschedNotice = Ar.delayedRescheduledSafeNotice(
            formattedT,
            safeInterval,
          );
        } else {
          targetDateTime = candidate;
          targetTod = firstTomorrow;
        }

        isToday = AppDateUtils.isSameDay(targetDateTime, now);
        isTomorrow = AppDateUtils.isTomorrow(targetDateTime, now);
        isAllTodayCompleted = !isToday;
        doseNum = totalDosesCount;
      }
    } else {
      // 2. أدوية الفترات الزمنية أو المسكنات بدون جدول ثابت
      if (earliestSafeTime != null) {
        targetDateTime = earliestSafeTime;
        if (medicine.isTreatment && lastTakenTime != null) {
          isRescheduled = true;
          final formattedT = AppDateUtils.formatTime(targetDateTime);
          reschedNotice = Ar.delayedRescheduledSafeNotice(
            formattedT,
            safeInterval,
          );
        }
      } else if (medicine.dynamicNextDoseTime != null) {
        targetDateTime = medicine.dynamicNextDoseTime!;
      } else {
        targetDateTime = now;
      }

      targetTod = TimeOfDay(
        hour: targetDateTime.hour,
        minute: targetDateTime.minute,
      );
      isToday = AppDateUtils.isSameDay(targetDateTime, now);
      isTomorrow = AppDateUtils.isTomorrow(targetDateTime, now);
      isAllTodayCompleted = dosesTakenCount >= totalDosesCount;
      doseNum = (dosesTakenCount + 1).clamp(1, totalDosesCount);
    }

    final diffMinutes = targetDateTime.difference(now).inMinutes;

    return _buildNextDoseInfo(
      medicine: medicine,
      targetTime: targetDateTime,
      tod: targetTod,
      isToday: isToday,
      isTomorrow: isTomorrow,
      isAllTodayCompleted: isAllTodayCompleted,
      diffMinutes: diffMinutes,
      doseNumberToday: doseNum,
      totalDosesToday: totalDosesCount,
      isDynamicallyRescheduled: isRescheduled,
      rescheduleNotice: reschedNotice,
      safeIntervalHours: safeInterval,
    );
  }

  NextDoseInfo _buildNextDoseInfo({
    required Medicine medicine,
    required DateTime targetTime,
    required TimeOfDay tod,
    required bool isToday,
    required bool isTomorrow,
    required bool isAllTodayCompleted,
    required int diffMinutes,
    int doseNumberToday = 1,
    int totalDosesToday = 1,
    bool isDynamicallyRescheduled = false,
    String? rescheduleNotice,
    int safeIntervalHours = 8,
  }) {
    final now = _now;
    final formattedHour = tod.hourOfPeriod == 0 ? 12 : tod.hourOfPeriod;
    final period = tod.period == DayPeriod.am ? Ar.amPeriod : Ar.pmPeriod;
    final minuteStr = tod.minute.toString().padLeft(2, '0');
    final formattedTime = '$formattedHour:$minuteStr $period';

    final isOverdue = !isAllTodayCompleted && diffMinutes < -15;
    final isDueNow = !isAllTodayCompleted && (diffMinutes.abs() <= 40 || diffMinutes < 0);

    String dateBadge;
    if (isToday) {
      dateBadge = 'اليوم';
    } else if (isTomorrow) {
      dateBadge = 'غداً';
    } else if (AppDateUtils.isYesterday(targetTime, now)) {
      dateBadge = 'مستحقة من الأمس';
    } else {
      dateBadge = AppDateUtils.formatShortDate(targetTime);
    }

    // حساب تفاصيل الجرعة السابقة
    final recentLogs = storageService
        .getLogs()
        .where((l) => l.medicineId == medicine.id)
        .toList()
      ..sort((a, b) => b.takenAt.compareTo(a.takenAt));

    final lastTaken = recentLogs.isNotEmpty
        ? recentLogs.first.takenAt
        : medicine.lastTakenTime;

    String lastTakenText;
    if (lastTaken != null) {
      final elapsed = now.difference(lastTaken);
      final elapsedMins = elapsed.inMinutes;
      final elapsedHours = elapsed.inHours;

      String timeAgoText;
      if (elapsedMins < 60) {
        timeAgoText = 'منذ ${elapsedMins <= 1 ? "دقيقة" : "$elapsedMins د"}';
      } else if (elapsedHours < 24) {
        final remM = elapsedMins % 60;
        timeAgoText = remM > 0
            ? 'منذ $elapsedHours س و $remM د'
            : 'منذ $elapsedHours ${elapsedHours == 1 ? "ساعة" : "ساعات"}';
      } else {
        final days = elapsed.inDays;
        timeAgoText = 'منذ $days ${days == 1 ? "يوم" : "أيام"}';
      }

      if (AppDateUtils.isSameDay(lastTaken, now)) {
        lastTakenText = 'اليوم ${AppDateUtils.formatTime(lastTaken)} ($timeAgoText)';
      } else if (AppDateUtils.isYesterday(lastTaken, now)) {
        lastTakenText = 'أمس ${AppDateUtils.formatTime(lastTaken)} ($timeAgoText)';
      } else {
        lastTakenText = '${AppDateUtils.formatShortDate(lastTaken)} ${AppDateUtils.formatTime(lastTaken)}';
      }
    } else {
      lastTakenText = 'لم تُسجل جرعة سابقة بعد';
    }

    String nextDoseFull;
    if (isToday) {
      nextDoseFull = 'اليوم $formattedTime';
    } else if (isTomorrow) {
      nextDoseFull = 'غداً $formattedTime';
    } else {
      nextDoseFull = '$dateBadge $formattedTime';
    }

    String countdownText;
    String relativeText;
    if (isAllTodayCompleted) {
      relativeText = 'اكتملت جرعات اليوم ✓ • القادمة غداً';
      countdownText = 'اكتملت جرعات اليوم ✓';
    } else if (isOverdue) {
      final lateMins = (-diffMinutes);
      if (lateMins >= 1440) {
        final days = lateMins ~/ 1440;
        final hours = (lateMins % 1440) ~/ 60;
        relativeText = 'مستحقة منذ $days يوم و $hours س';
        countdownText = 'متأخرة بـ $days يوم';
      } else if (lateMins >= 60) {
        final hours = lateMins ~/ 60;
        final mins = lateMins % 60;
        relativeText = 'متأخرة بـ $hours س و $mins د';
        countdownText = 'متأخرة بـ $hours س و $mins د';
      } else {
        relativeText = 'متأخرة بـ $lateMins دقيقة';
        countdownText = 'متأخرة بـ $lateMins د';
      }
    } else if (isDueNow) {
      relativeText = 'حان موعد الجرعة الآن!';
      countdownText = 'حان الموعد الآن!';
    } else if (diffMinutes > 0) {
      if (diffMinutes < 60) {
        relativeText = 'بعد $diffMinutes دقيقة';
        countdownText = 'متبقي $diffMinutes دقيقة';
      } else {
        final hours = diffMinutes ~/ 60;
        final mins = diffMinutes % 60;
        if (mins == 0) {
          relativeText = 'بعد $hours ${hours == 1 ? "ساعة" : "ساعات"}';
          countdownText = 'متبقي $hours ${hours == 1 ? "ساعة" : "ساعات"}';
        } else {
          relativeText = 'بعد $hours س و $mins د';
          countdownText = 'متبقي $hours س و $mins د';
        }
      }
    } else {
      relativeText = 'موعدها الآن';
      countdownText = 'حان الموعد الآن!';
    }

    return NextDoseInfo(
      medicine: medicine,
      nextDateTime: targetTime,
      timeOfDay: tod,
      isToday: isToday,
      isTomorrow: isTomorrow,
      isOverdue: isOverdue,
      isDueNow: isDueNow,
      isAllTodayCompleted: isAllTodayCompleted,
      formattedTime: formattedTime,
      relativeTimeText: relativeText,
      dateBadgeText: dateBadge,
      doseNumberToday: doseNumberToday,
      totalDosesToday: totalDosesToday,
      lastTakenDateTime: lastTaken,
      lastTakenFormattedText: lastTakenText,
      nextDoseFullText: nextDoseFull,
      remainingCountdownText: countdownText,
      isDynamicallyRescheduled: isDynamicallyRescheduled,
      rescheduleNotice: rescheduleNotice,
      safeIntervalHours: safeIntervalHours,
    );
  }

  /// Instant Take Next Dose
  /// Immediately marks the dose as taken, updates stock, and advances to the next dose!
  Future<NextDoseInfo?> takeNextDoseNow(
    Medicine medicine, {
    int? pillsTaken,
    int? painLevel,
    String? notes,
    DateTime? customTime,
  }) async {
    final count = pillsTaken ?? medicine.pillsPerDose;
    await recordDoseIntake(
      medicine: medicine,
      pillsTaken: count,
      painLevel: painLevel,
      notes: notes,
      customTime: customTime,
    );

    // Refresh updated medicine and return the new next dose info
    final updatedMeds = storageService.getMedicines();
    final updated = updatedMeds.firstWhere(
      (m) => m.id == medicine.id,
      orElse: () => medicine,
    );
    final nextInfo = getNextDoseForMedicine(updated);
    notifyListeners();
    return nextInfo;
  }

  /// Trigger Painkiller Safe Notification
  Future<void> triggerPainkillerSafeNotification(Medicine medicine) async {
    final now = _now;
    final item = AppNotificationItem(
      id: 'notif_${now.millisecondsSinceEpoch}',
      title: Ar.notifPainkillerSafeTitle,
      message: Ar.notifPainkillerSafeMsg(medicine.name),
      type: NotificationType.painkillerSafe,
      medicineId: medicine.id,
      medicineName: medicine.name,
      timestamp: now,
    );

    await storageService.addNotification(item);
    _latestActiveBanner = item;
    notifyListeners();

    // إرسال إشعار حقيقي إلى شريط إشعارات هاتف المستخدم (System Notification Bar)
    await SystemNotificationService.showNotification(
      id: medicine.id.hashCode.abs() % 100000,
      title: item.title,
      body: item.message,
      payload: medicine.id,
    );
  }

  /// Trigger Treatment Scheduled Reminder
  Future<void> triggerTreatmentReminderNotification(
    Medicine medicine,
    TimeOfDay time,
  ) async {
    final now = _now;
    final formattedHour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final period = time.period == DayPeriod.am ? Ar.amPeriod : Ar.pmPeriod;
    final minuteStr = time.minute.toString().padLeft(2, '0');
    final timeStr = '$formattedHour:$minuteStr $period';

    final item = AppNotificationItem(
      id: 'notif_${now.millisecondsSinceEpoch}',
      title: Ar.notifMedTimeTitle,
      message: Ar.notifMedTimeMsg(
        medicine.name,
        medicine.pillsPerDose,
        medicine.unitLabel,
        timeStr,
      ),
      type: NotificationType.treatmentReminder,
      medicineId: medicine.id,
      medicineName: medicine.name,
      timestamp: now,
    );

    await storageService.addNotification(item);
    _latestActiveBanner = item;
    notifyListeners();

    // إرسال إشعار حقيقي إلى شريط إشعارات هاتف المستخدم (System Notification Bar)
    await SystemNotificationService.showNotification(
      id: medicine.id.hashCode.abs() % 100000,
      title: item.title,
      body: item.message,
      payload: medicine.id,
    );
  }

  /// Trigger Dynamic Dose Reminder Notification
  Future<void> triggerDynamicDoseReminderNotification(
    Medicine medicine,
    DateTime targetTime,
  ) async {
    final now = _now;
    final timeStr = AppDateUtils.formatTime(targetTime);
    final item = AppNotificationItem(
      id: 'notif_${now.millisecondsSinceEpoch}',
      title: Ar.notifDynamicMedTimeTitle,
      message: Ar.notifDynamicMedTimeMsg(medicine.name, timeStr),
      type: NotificationType.treatmentReminder,
      medicineId: medicine.id,
      medicineName: medicine.name,
      timestamp: now,
    );

    await storageService.addNotification(item);
    _latestActiveBanner = item;
    notifyListeners();

    // إرسال إشعار حقيقي إلى شريط إشعارات هاتف المستخدم (System Notification Bar)
    await SystemNotificationService.showNotification(
      id: medicine.id.hashCode.abs() % 100000,
      title: item.title,
      body: item.message,
      payload: medicine.id,
    );
  }

  /// Trigger Low Stock Alert
  Future<void> triggerLowStockNotification(Medicine medicine) async {
    final now = _now;
    final item = AppNotificationItem(
      id: 'notif_${now.millisecondsSinceEpoch}',
      title: Ar.notifLowStockTitle,
      message: Ar.notifLowStockMsg(
        medicine.name,
        medicine.totalPills,
        medicine.unitLabel,
      ),
      type: NotificationType.lowStock,
      medicineId: medicine.id,
      medicineName: medicine.name,
      timestamp: now,
    );

    await storageService.addNotification(item);
    _latestActiveBanner = item;
    notifyListeners();

    // إرسال إشعار حقيقي إلى شريط إشعارات هاتف المستخدم (System Notification Bar)
    await SystemNotificationService.showNotification(
      id: ('stock_${medicine.id}').hashCode.abs() % 100000,
      title: item.title,
      body: item.message,
      payload: medicine.id,
    );
  }

  /// استجابة فورية للنقر على الإشعار من شريط الهاتف:
  /// تسجيل أخذ الجرعة تلقائياً وترحيل الموعد القادم وإشعار المستخدم بالنجاح
  Future<void> handleNotificationDoseConfirmation(String payload) async {
    final cleanMedId = payload.replaceFirst('take_dose_', '').replaceFirst('stock_', '').trim();
    final medicines = storageService.getMedicines();
    
    Medicine? targetMed;
    for (final m in medicines) {
      if (m.id == cleanMedId || m.id == payload) {
        targetMed = m;
        break;
      }
    }

    if (targetMed != null) {
      await takeNextDoseNow(targetMed);
      
      // إرسال إشعار تأكيد فوري بالنجاح في شريط الإشعارات
      await SystemNotificationService.showNotification(
        id: (targetMed.id.hashCode.abs() % 100000) + 777,
        title: 'تم تأكيد تناول الجرعة ✓',
        body: 'تم تسجيل جرعة "${targetMed.name}" بنجاح وترحيل الموعد القادم.',
        payload: 'confirmed_${targetMed.id}',
        showAction: false,
      );
    }
  }

  /// Helper to test trigger notification instantly from UI
  Future<void> simulateNotificationTest({required bool isPainkiller}) async {
    final medicines = storageService.getMedicines();
    if (medicines.isEmpty) return;

    if (isPainkiller) {
      final painkiller = medicines.firstWhere(
        (m) => m.isPainkiller,
        orElse: () => medicines.first,
      );
      await triggerPainkillerSafeNotification(painkiller);
    } else {
      final treatment = medicines.firstWhere(
        (m) => m.isTreatment,
        orElse: () => medicines.first,
      );
      await triggerTreatmentReminderNotification(treatment, TimeOfDay.now());
    }
  }
}
