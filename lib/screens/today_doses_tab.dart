import 'package:flutter/material.dart';
import '../ar.dart';
import '../models/medicine.dart';
import '../services/storage_service.dart';
import '../services/reminder_service.dart';
import '../services/medical_time_service.dart';
import '../widgets/pill_refresh_indicator.dart';
import '../utils/date_utils.dart';

class TodayDosesTab extends StatelessWidget {
  final StorageService storageService;
  final ReminderService reminderService;
  final Function(Medicine medicine) onTakeDose;
  final Function(Medicine medicine) onRefill;
  final VoidCallback onAddMedicine;

  const TodayDosesTab({
    super.key,
    required this.storageService,
    required this.reminderService,
    required this.onTakeDose,
    required this.onRefill,
    required this.onAddMedicine,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final activeProfileId = storageService.getActiveProfileId();

    final medicines = storageService.getMedicines(forProfileId: activeProfileId).where((m) => m.isActive).toList();
    final treatmentMeds = medicines.where((m) => m.isTreatment).toList();
    final painkillerMeds = medicines.where((m) => m.isPainkiller).toList();

    // Core User Requirement: In the main list, ONLY show the next dose for each medicine!
    final nextDoses = reminderService.getNextDosesForAllMedicines(profileId: activeProfileId);
    final todaySlots = reminderService.getTodayScheduledSlots(profileId: activeProfileId);

    final now = MedicalTimeService.instance.now();
    final dateStr = AppDateUtils.formatFullDate(now);

    final takenCount = todaySlots.where((s) => s.isTaken).length;
    final totalCount = todaySlots.length;
    final adherenceRate = totalCount > 0 ? (takenCount / totalCount) : 1.0;

    return PillRefreshIndicator(
      onRefresh: () async {
        await MedicalTimeService.instance.syncWithNetworkTime();
        reminderService.checkReminders();
        await Future.delayed(const Duration(milliseconds: 500));
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(left: 16, right: 16, top: 12, bottom: 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
          // Header Date & Welcome
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      Ar.welcome,
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    ),
                    Text(
                      dateStr,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    Icon(Icons.calendar_month, size: 16, color: theme.colorScheme.primary),
                    const SizedBox(width: 6),
                    Text(
                      Ar.today,
                      style: TextStyle(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          if (medicines.isEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: theme.dividerColor.withValues(alpha: 0.3)),
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0D9488).withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.medication_rounded,
                      size: 52,
                      color: Color(0xFF0D9488),
                    ),
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    Ar.welcomeTitle,
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    Ar.welcomeSubtitle,
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14, color: Colors.grey[600], height: 1.5),
                  ),
                  const SizedBox(height: 22),
                  ElevatedButton.icon(
                    onPressed: onAddMedicine,
                    icon: const Icon(Icons.add_rounded, size: 20),
                    label: const Text(
                      Ar.addNewMedicine,
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0D9488),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                  ),
                ],
              ),
            )
          else ...[
            // Daily Adherence Card
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isDark
                      ? [const Color(0xFF0F766E), const Color(0xFF042F2E)]
                      : [const Color(0xFF0D9488), const Color(0xFF14B8A6)],
                  begin: Alignment.topRight,
                  end: Alignment.bottomLeft,
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF0D9488).withValues(alpha: 0.3),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              Ar.todayAdherenceTitle,
                              style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                              overflow: TextOverflow.ellipsis,
                            ),
                            SizedBox(height: 4),
                            Text(
                              Ar.appTagline,
                              style: TextStyle(color: Colors.white70, fontSize: 12),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          SizedBox(
                            width: 54,
                            height: 54,
                            child: CircularProgressIndicator(
                              value: adherenceRate,
                              strokeWidth: 5,
                              backgroundColor: Colors.white24,
                              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          ),
                          Text(
                            '${(adherenceRate * 100).toInt()}%',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildStatColumn(Ar.completedDosesStat, '$takenCount', Icons.check_circle_outline),
                        Container(width: 1, height: 28, color: Colors.white24),
                        _buildStatColumn(Ar.remainingDosesStat, '${(totalCount - takenCount).clamp(0, 999)}', Icons.alarm),
                        Container(width: 1, height: 28, color: Colors.white24),
                        _buildStatColumn(Ar.totalMedicinesStat, '${medicines.length}', Icons.medication_outlined),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),

            // Safe Painkillers Quick Status Banner (If any painkiller is safe or in cooldown)
            if (painkillerMeds.isNotEmpty) ...[
              ...painkillerMeds.map((painkiller) {
                final safety = reminderService.getPainkillerSafety(painkiller);
                final isSafe = safety.isSafeNow;
                return Container(
                  margin: const EdgeInsets.only(bottom: 14),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: isDark
                        ? (isSafe ? const Color(0xFF064E3B) : const Color(0xFF261D11))
                        : (isSafe ? const Color(0xFFECFDF5) : const Color(0xFFFEF3C7)),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: isSafe
                          ? const Color(0xFF10B981).withValues(alpha: 0.5)
                          : const Color(0xFFF59E0B).withValues(alpha: 0.5),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: (isSafe ? const Color(0xFF10B981) : const Color(0xFFF59E0B)).withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          isSafe ? Icons.healing_rounded : Icons.timelapse_rounded,
                          color: isSafe ? const Color(0xFF10B981) : const Color(0xFFD97706),
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    painkiller.name,
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: (isSafe ? const Color(0xFF10B981) : const Color(0xFFF59E0B)).withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    Ar.painkillerTag,
                                    style: TextStyle(
                                      color: isSafe ? const Color(0xFF047857) : const Color(0xFFB45309),
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 3),
                            Text(
                              safety.statusMessage,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: isSafe ? const Color(0xFF047857) : const Color(0xFFB45309),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (isSafe)
                        ElevatedButton(
                          onPressed: () => onTakeDose(painkiller),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF10B981),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: const Text(
                            Ar.takePainkillerNowBtn,
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                          ),
                        )
                      else
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.grey.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            'انتظار الأمان',
                            style: TextStyle(fontSize: 11, color: Colors.grey[700], fontWeight: FontWeight.bold),
                          ),
                        ),
                    ],
                  ),
                );
              }),
            ],

            // ─── NEXT DOSES ONLY (USER REQUIREMENT) ───
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.bolt_rounded, size: 22, color: Color(0xFF0D9488)),
                    SizedBox(width: 6),
                    Text(
                      Ar.nextDosesOnlyTitle,
                      style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0D9488).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${nextDoses.length} ${Ar.appointmentsCount}',
                    style: const TextStyle(
                      color: Color(0xFF0D9488),
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 3),
            Text(
              Ar.nextDosesOnlySubtitle,
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
            const SizedBox(height: 14),

            if (treatmentMeds.isEmpty)
              _buildEmptyTreatmentState(context)
            else if (nextDoses.isEmpty)
              _buildNoSlotsScheduledState(context)
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: nextDoses.length,
                itemBuilder: (ctx, index) {
                  final nextInfo = nextDoses[index];
                  return _buildNextDoseCard(context, nextInfo);
                },
              ),
          ],
        ],
      ),
    ),
    );
  }

  Widget _buildStatColumn(String label, String value, IconData icon) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: Colors.white70),
            const SizedBox(width: 4),
            Text(value, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 11)),
      ],
    );
  }

  /// NEXT DOSE CARD:
  /// Shows ONLY the single upcoming dose for this medicine.
  /// As soon as taken, immediately advances to the next dose and removes the old one!
  Widget _buildNextDoseCard(BuildContext context, NextDoseInfo nextInfo) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final med = nextInfo.medicine;
    final isOverdue = nextInfo.isOverdue;
    final isDueNow = nextInfo.isDueNow;
    final isCompletedToday = nextInfo.isAllTodayCompleted;

    Color borderColor;
    Color timeBadgeColor;
    Color timeTextColor;

    if (isCompletedToday) {
      borderColor = const Color(0xFF10B981).withValues(alpha: 0.35);
      timeBadgeColor = const Color(0xFF10B981).withValues(alpha: 0.12);
      timeTextColor = const Color(0xFF047857);
    } else if (isOverdue) {
      borderColor = const Color(0xFFEF4444).withValues(alpha: 0.5);
      timeBadgeColor = const Color(0xFFEF4444).withValues(alpha: 0.12);
      timeTextColor = const Color(0xFFDC2626);
    } else if (isDueNow) {
      borderColor = const Color(0xFF0D9488);
      timeBadgeColor = const Color(0xFF0D9488).withValues(alpha: 0.15);
      timeTextColor = const Color(0xFF0D9488);
    } else {
      borderColor = theme.dividerColor.withValues(alpha: 0.25);
      timeBadgeColor = theme.colorScheme.primary.withValues(alpha: 0.08);
      timeTextColor = theme.colorScheme.primary;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: isCompletedToday
            ? (isDark ? const Color(0xFF09261C) : const Color(0xFFF0FDF4))
            : theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor, width: isDueNow ? 1.8 : 1.2),
        boxShadow: [
          BoxShadow(
            color: isDueNow
                ? const Color(0xFF0D9488).withValues(alpha: 0.12)
                : Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Timing & Date Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: timeBadgeColor,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        isCompletedToday
                            ? Icons.check_circle_rounded
                            : (isOverdue
                                ? Icons.warning_amber_rounded
                                : (isDueNow ? Icons.alarm_on_rounded : Icons.access_time_rounded)),
                        size: 22,
                        color: timeTextColor,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        nextInfo.formattedTime,
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.bold,
                          color: timeTextColor,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                        decoration: BoxDecoration(
                          color: timeTextColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          nextInfo.dateBadgeText,
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.bold,
                            color: timeTextColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 14),

                // Medicine Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              med.name,
                              style: const TextStyle(
                                fontSize: 16.5,
                                fontWeight: FontWeight.bold,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          // Medicine Color Indicator
                          Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Color(med.colorValue),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),

                      // Relative Timing indicator (e.g. "بعد ساعتين" or "حان الموعد الآن!")
                      Row(
                        children: [
                          Icon(
                            isOverdue
                                ? Icons.error_outline
                                : (isDueNow ? Icons.flash_on_rounded : Icons.schedule),
                            size: 13,
                            color: isOverdue
                                ? Colors.red
                                : (isDueNow ? const Color(0xFF0D9488) : Colors.grey[600]),
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              nextInfo.relativeTimeText,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: isOverdue
                                    ? Colors.red
                                    : (isDueNow
                                        ? const Color(0xFF0D9488)
                                        : (isCompletedToday ? const Color(0xFF047857) : Colors.grey[700])),
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),

                      // Pills & Stock info
                      Wrap(
                        spacing: 8,
                        runSpacing: 2,
                        children: [
                          Text(
                            '${Ar.dosePrefix} ${med.pillsPerDose} ${med.unitLabel}',
                            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                          ),
                          Text(
                            '${Ar.stockPrefix} ${med.totalPills} ${med.unitLabel}',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: med.isLowStock ? Colors.red : Colors.grey[700],
                            ),
                          ),
                        ],
                      ),
                      if (med.instructions.isNotEmpty) ...[
                        const SizedBox(height: 3),
                        Text(
                          med.instructions,
                          style: TextStyle(fontSize: 11.5, color: Colors.grey[500]),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),

            // ─── MEDICAL DOSE TIMELINE (PREVIOUS, NEXT, COUNTDOWN) ───
            Container(
              margin: const EdgeInsets.only(top: 10),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: isDark ? Colors.black.withValues(alpha: 0.25) : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: theme.dividerColor.withValues(alpha: isDark ? 0.2 : 0.4),
                ),
              ),
              child: Column(
                children: [
                  // 1. Previous Dose Row
                  Row(
                    children: [
                      const Icon(Icons.history_rounded, size: 16, color: Color(0xFF64748B)),
                      const SizedBox(width: 6),
                      Text(
                        'الجرعة السابقة:',
                        style: TextStyle(
                          fontSize: 11.5,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          nextInfo.lastTakenFormattedText,
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.grey[300] : const Color(0xFF334155),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Divider(height: 1, thickness: 0.7),
                  const SizedBox(height: 8),
                  // 2. Next Dose & Countdown Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Next Dose
                      Expanded(
                        child: Row(
                          children: [
                            const Icon(Icons.alarm_on_rounded, size: 16, color: Color(0xFF0D9488)),
                            const SizedBox(width: 6),
                            Text(
                              'التالية:',
                              style: TextStyle(
                                fontSize: 11.5,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                nextInfo.nextDoseFullText,
                                style: const TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF0D9488),
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Countdown Badge (الوقت المتبقي)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: (isDueNow
                                  ? const Color(0xFF0D9488)
                                  : (isOverdue ? Colors.red : theme.colorScheme.primary))
                              .withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.hourglass_bottom_rounded,
                              size: 13,
                              color: isDueNow
                                  ? const Color(0xFF0D9488)
                                  : (isOverdue ? Colors.red : theme.colorScheme.primary),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              nextInfo.remainingCountdownText,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: isDueNow
                                    ? const Color(0xFF0D9488)
                                    : (isOverdue ? Colors.red : theme.colorScheme.primary),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 10),

            // Action row: One-Tap "أخذت الجرعة" which instantly advances to next dose!
            Row(
              children: [
                // Dose progress badge (Flexible to fit any screen size)
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.grey.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      isCompletedToday
                          ? 'جرعات اليوم مكتملة ✓'
                          : 'الجرعة ${nextInfo.doseNumberToday} من ${nextInfo.totalDosesToday} لليوم',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: isCompletedToday ? const Color(0xFF047857) : Colors.grey[700],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                const SizedBox(width: 6),

                // Options / Log Sheet icon button
                IconButton(
                  icon: const Icon(Icons.tune_rounded, size: 20),
                  tooltip: 'خيارات تفصيلية / تعديل الكمية',
                  onPressed: () => onTakeDose(med),
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.all(6),
                  constraints: const BoxConstraints(),
                ),
                const SizedBox(width: 6),

                // CORE USER REQUIREMENT BUTTON:
                // "بمجرد انه اكبس انه اخذته على طول يظهر موعدها التالي ويروح القديم"
                ElevatedButton.icon(
                  onPressed: med.isOutOfStock
                      ? () => onRefill(med)
                      : () async {
                          // 1. Immediately advance to next dose!
                          final newNext = await reminderService.takeNextDoseNow(med);

                          // 2. Instant feedback showing the new next appointment
                          if (context.mounted && newNext != null) {
                            ScaffoldMessenger.of(context).hideCurrentSnackBar();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Row(
                                  children: [
                                    const Icon(Icons.check_circle_rounded, color: Colors.white, size: 22),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        Ar.doseTakenAdvancedMsg(
                                          med.name,
                                          '${newNext.dateBadgeText} ${newNext.formattedTime}',
                                        ),
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                      ),
                                    ),
                                  ],
                                ),
                                backgroundColor: const Color(0xFF10B981),
                                duration: const Duration(seconds: 4),
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              ),
                            );
                          }
                        },
                  icon: Icon(
                    med.isOutOfStock
                        ? Icons.add_shopping_cart_rounded
                        : (isCompletedToday ? Icons.done_all_rounded : Icons.check_circle_outline_rounded),
                    size: 16,
                  ),
                  label: Text(
                    med.isOutOfStock
                        ? Ar.refillBtn
                        : (isCompletedToday ? 'جرعة إضافية' : Ar.takeDoseInstantBtn),
                    style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: med.isOutOfStock
                        ? Colors.orange[800]
                        : (isOverdue
                            ? const Color(0xFFEF4444)
                            : (isCompletedToday ? const Color(0xFF0F766E) : const Color(0xFF0D9488))),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: isDueNow ? 2 : 0,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyTreatmentState(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Icon(Icons.medication_liquid_outlined, size: 52, color: Colors.grey[400]),
          const SizedBox(height: 12),
          const Text(
            Ar.noTreatmentsScheduledTitle,
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          const Text(
            Ar.noTreatmentsScheduledDesc,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: Colors.grey),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: onAddMedicine,
            icon: const Icon(Icons.add),
            label: const Text(Ar.addNewMedicine),
          ),
        ],
      ),
    );
  }

  Widget _buildNoSlotsScheduledState(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Center(
        child: Text(
          Ar.noTimesSetDesc,
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey),
        ),
      ),
    );
  }
}
