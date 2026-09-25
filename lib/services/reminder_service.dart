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
    Future.microtask(() => checkReminders());
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

  /// CORE USER REQUIREMENT: Record dose intake with dynamic interval recalculation
  /// When a user was asleep or delayed, starting the timer for the next dose from actual intake time!
  Future<void> recordDoseIntake({
    required Medicine medicine,
    required int pillsTaken,
    int? painLevel,
    String? notes,
  }) async {
    final now = _now;

    // Calculate the next dose: use scheduledTimes if defined, otherwise dynamic interval!
    DateTime recalculatedNextDose;
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
      if (totalToday < sortedTimes.length) {
        final nextT = sortedTimes[totalToday];
        recalculatedNextDose = DateTime(
          now.year,
          now.month,
          now.day,
          nextT.hour,
          nextT.minute,
        );
      } else {
        final tomorrow = now.add(const Duration(days: 1));
        final firstT = sortedTimes.first;
        recalculatedNextDose = DateTime(
          tomorrow.year,
          tomorrow.month,
          tomorrow.day,
          firstT.hour,
          firstT.minute,
        );
      }
    } else {
      final hours = medicine.intervalHours > 0 ? medicine.intervalHours : 8;
      recalculatedNextDose = now.add(Duration(hours: hours));
    }
    final nextTimeFormatted = AppDateUtils.formatTime(recalculatedNextDose);

    String rescheduleNote = Ar.rescheduleNoteText(nextTimeFormatted);

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

    // Show instant dynamic confirmation
    final alertItem = AppNotificationItem(
      id: 'dynamic_alert_${now.millisecondsSinceEpoch}',
      title: Ar.notifRescheduleTitle,
      message: Ar.notifRescheduleMsg(nextTimeFormatted),
      type: NotificationType.treatmentReminder,
      medicineId: medicine.id,
      medicineName: medicine.name,
      timestamp: now,
    );

    _latestActiveBanner = alertItem;
    notifyListeners();
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

  /// Calculates safe interval information for painkillers
  PainkillerSafetyInfo getPainkillerSafety(
    Medicine medicine, [
    List<DoseLog>? allLogs,
  ]) {
    final logs = allLogs ?? storageService.getLogs();
    final now = _now;

    final recentLogs = logs
        .where(
          (l) =>
              l.medicineId == medicine.id &&
              now.difference(l.takenAt).inHours < 24,
        )
        .toList();

    recentLogs.sort((a, b) => b.takenAt.compareTo(a.takenAt));

    final dosesToday = recentLogs
        .where(
          (l) => AppDateUtils.isSameDay(l.takenAt, now),
        )
        .length;

    final limitReached = dosesToday >= medicine.maxDailyDoses;

    if (recentLogs.isEmpty) {
      return PainkillerSafetyInfo(
        isSafeNow: true,
        limitReached: false,
        dosesTakenToday: 0,
        maxDailyDoses: medicine.maxDailyDoses,
        statusMessage: Ar.safePainkillerNotice,
        progress: 1.0,
      );
    }

    final lastLog = recentLogs.first;
    final timeSinceLastDose = now.difference(lastLog.takenAt);
    final cooldownDuration = Duration(hours: medicine.minSafeIntervalHours);

    if (limitReached) {
      return PainkillerSafetyInfo(
        isSafeNow: false,
        limitReached: true,
        dosesTakenToday: dosesToday,
        maxDailyDoses: medicine.maxDailyDoses,
        timeSinceLastDose: timeSinceLastDose,
        statusMessage: Ar.statusPainkillerLimitReached(
          dosesToday,
          medicine.maxDailyDoses,
        ),
        progress: 1.0,
      );
    }

    if (timeSinceLastDose >= cooldownDuration) {
      return PainkillerSafetyInfo(
        isSafeNow: true,
        limitReached: false,
        dosesTakenToday: dosesToday,
        maxDailyDoses: medicine.maxDailyDoses,
        timeSinceLastDose: timeSinceLastDose,
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

      return PainkillerSafetyInfo(
        isSafeNow: false,
        limitReached: false,
        dosesTakenToday: dosesToday,
        maxDailyDoses: medicine.maxDailyDoses,
        timeSinceLastDose: timeSinceLastDose,
        remainingCooldown: remaining,
        statusMessage: Ar.statusPainkillerWait(timeStr),
        progress: progress,
      );
    }
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

  /// Calculates ONLY the next upcoming dose for a single medicine
  NextDoseInfo? getNextDoseForMedicine(
    Medicine medicine, [
    List<DoseLog>? allLogs,
  ]) {
    if (!medicine.isActive) return null;
    final logs = allLogs ?? storageService.getLogs();
    final now = _now;

    // 1. Regular scheduled times (prioritized for scheduled treatments)
    if (medicine.scheduledTimes.isNotEmpty) {
      final sortedTimes = List<TimeOfDay>.from(medicine.scheduledTimes)
        ..sort(
          (a, b) => (a.hour * 60 + a.minute).compareTo(b.hour * 60 + b.minute),
        );

      // Doses logged today for this medicine
      final todayLogs = logs
          .where(
            (l) =>
                l.medicineId == medicine.id &&
                AppDateUtils.isSameDay(l.takenAt, now),
          )
          .toList();

      final dosesTakenCount = todayLogs.length;

      if (dosesTakenCount < sortedTimes.length) {
        // Still have doses remaining today!
        // The NEXT dose is at index dosesTakenCount
        final nextTime = sortedTimes[dosesTakenCount];
        final targetDateTime = DateTime(
          now.year,
          now.month,
          now.day,
          nextTime.hour,
          nextTime.minute,
        );
        final diffMinutes = targetDateTime.difference(now).inMinutes;

        return _buildNextDoseInfo(
          medicine: medicine,
          targetTime: targetDateTime,
          tod: nextTime,
          isToday: true,
          isTomorrow: false,
          isAllTodayCompleted: false,
          diffMinutes: diffMinutes,
          doseNumberToday: dosesTakenCount + 1,
          totalDosesToday: sortedTimes.length,
        );
      } else {
        // All scheduled doses for today have been taken!
        // The NEXT dose is tomorrow at the first scheduled time!
        final firstTomorrow = sortedTimes.first;
        final tomorrow = now.add(const Duration(days: 1));
        final targetDateTime = DateTime(
          tomorrow.year,
          tomorrow.month,
          tomorrow.day,
          firstTomorrow.hour,
          firstTomorrow.minute,
        );
        final diffMinutes = targetDateTime.difference(now).inMinutes;

        return _buildNextDoseInfo(
          medicine: medicine,
          targetTime: targetDateTime,
          tod: firstTomorrow,
          isToday: false,
          isTomorrow: true,
          isAllTodayCompleted: true,
          diffMinutes: diffMinutes,
          doseNumberToday: 1,
          totalDosesToday: sortedTimes.length,
        );
      }
    }

    // 2. If medicine has a dynamicNextDoseTime set
    if (medicine.dynamicNextDoseTime != null) {
      final dynTime = medicine.dynamicNextDoseTime!;
      final timeOfDay = TimeOfDay(hour: dynTime.hour, minute: dynTime.minute);
      final isToday = AppDateUtils.isSameDay(dynTime, now);
      final isTomorrow = AppDateUtils.isTomorrow(dynTime, now);
      final diffMinutes = dynTime.difference(now).inMinutes;

      // Check if this dynamic dose was already taken
      final alreadyTaken = logs.any(
        (l) =>
            l.medicineId == medicine.id &&
            l.takenAt.isAfter(dynTime.subtract(const Duration(minutes: 30))),
      );

      if (!alreadyTaken) {
        return _buildNextDoseInfo(
          medicine: medicine,
          targetTime: dynTime,
          tod: timeOfDay,
          isToday: isToday,
          isTomorrow: isTomorrow,
          isAllTodayCompleted: false,
          diffMinutes: diffMinutes,
        );
      }
    }

    // 3. Fallback: intervalHours from lastTakenTime or now
    final interval = medicine.intervalHours > 0 ? medicine.intervalHours : 8;
    DateTime targetTime;
    if (medicine.lastTakenTime != null) {
      targetTime = medicine.lastTakenTime!.add(Duration(hours: interval));
    } else {
      // Never taken yet: due right now
      targetTime = now;
    }

    final timeOfDay = TimeOfDay(
      hour: targetTime.hour,
      minute: targetTime.minute,
    );
    final isToday = AppDateUtils.isSameDay(targetTime, now);
    final isTomorrow = AppDateUtils.isTomorrow(targetTime, now);
    final diffMinutes = targetTime.difference(now).inMinutes;

    return _buildNextDoseInfo(
      medicine: medicine,
      targetTime: targetTime,
      tod: timeOfDay,
      isToday: isToday,
      isTomorrow: isTomorrow,
      isAllTodayCompleted: false,
      diffMinutes: diffMinutes,
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

    // 1. حساب تفاصيل الجرعة السابقة (Previous Dose)
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

    // 2. الجرعة القادمة (Next Dose Full Text)
    String nextDoseFull;
    if (isToday) {
      nextDoseFull = 'اليوم $formattedTime';
    } else if (isTomorrow) {
      nextDoseFull = 'غداً $formattedTime';
    } else {
      nextDoseFull = '$dateBadge $formattedTime';
    }

    // 3. العد التنازلي والوقت المتبقي الصريح (Countdown)
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
    );
  }

  /// Instant Take Next Dose
  /// Immediately marks the dose as taken, updates stock, and advances to the next dose!
  Future<NextDoseInfo?> takeNextDoseNow(
    Medicine medicine, {
    int? pillsTaken,
    int? painLevel,
    String? notes,
  }) async {
    final count = pillsTaken ?? medicine.pillsPerDose;
    await recordDoseIntake(
      medicine: medicine,
      pillsTaken: count,
      painLevel: painLevel,
      notes: notes,
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
