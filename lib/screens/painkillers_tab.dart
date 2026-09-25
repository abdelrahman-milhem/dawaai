import 'package:flutter/material.dart';

import '../ar.dart';
import '../models/medicine.dart';
import '../services/storage_service.dart';
import '../services/reminder_service.dart';
import '../services/medical_time_service.dart';
import '../widgets/pill_refresh_indicator.dart';

class PainkillersTab extends StatelessWidget {
  final StorageService storageService;
  final ReminderService reminderService;
  final Function(Medicine medicine) onTakeDose;
  final Function(Medicine medicine) onRefill;
  final VoidCallback onAddMedicine;
  final Function(Medicine medicine) onEdit;
  final Function(String id) onDelete;

  const PainkillersTab({
    super.key,
    required this.storageService,
    required this.reminderService,
    required this.onTakeDose,
    required this.onRefill,
    required this.onAddMedicine,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final allMedicines = storageService.getMedicines();
    final activeMeds = allMedicines.where((m) => m.isActive).toList();
    final treatmentCount = activeMeds.where((m) => m.isTreatment).length;
    final painkillerCount = activeMeds.where((m) => m.isPainkiller).length;

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
          // ─── Header Card ───
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDark
                    ? [const Color(0xFF0F766E), const Color(0xFF042F2E)]
                    : [const Color(0xFF0D9488), const Color(0xFF0891B2)],
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF0D9488).withValues(alpha: 0.35),
                  blurRadius: 18,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              children: [
                // Icon
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.medication_rounded,
                    color: Colors.white,
                    size: 30,
                  ),
                ),
                const SizedBox(width: 14),
                // Title + counts
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        Ar.myMedicinesTabTitle,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        Ar.myMedicinesSubtitle,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                // Add Button
                GestureDetector(
                  onTap: onAddMedicine,
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.add,
                      color: Color(0xFF0D9488),
                      size: 24,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // ─── Stats Row ───
          Row(
            children: [
              Expanded(
                child: _buildStatChip(
                  context,
                  icon: Icons.medication_outlined,
                  label: 'إجمالي',
                  value: '${activeMeds.length}',
                  color: theme.colorScheme.primary,
                  isDark: isDark,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildStatChip(
                  context,
                  icon: Icons.calendar_today_rounded,
                  label: 'علاج منتظم',
                  value: '$treatmentCount',
                  color: const Color(0xFF3B82F6),
                  isDark: isDark,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildStatChip(
                  context,
                  icon: Icons.healing_rounded,
                  label: 'مسكنات',
                  value: '$painkillerCount',
                  color: const Color(0xFFEF4444),
                  isDark: isDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // ─── Section Title ───
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'قائمة أدويتك',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
              ),
              Text(
                Ar.myMedicinesCountLabel(activeMeds.length),
                style: TextStyle(color: Colors.grey[600], fontSize: 13),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // ─── Empty State ───
          if (activeMeds.isEmpty)
            _buildEmptyState(context)
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: activeMeds.length,
              itemBuilder: (ctx, index) {
                final med = activeMeds[index];
                return _buildMedicineCard(context, med, isDark);
              },
            ),

          const SizedBox(height: 12),

          // ─── Add More Button ───
          if (activeMeds.isNotEmpty)
            OutlinedButton.icon(
              onPressed: onAddMedicine,
              icon: const Icon(Icons.add),
              label: const Text(Ar.addMedicineBtn),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                side: BorderSide(
                  color: theme.colorScheme.primary.withValues(alpha: 0.5),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
        ],
      ),
    ),
    );
  }

  Widget _buildStatChip(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Column(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(fontSize: 11, color: Colors.grey[600]),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildMedicineCard(BuildContext context, Medicine med, bool isDark) {
    final theme = Theme.of(context);
    final isPainkiller = med.isPainkiller;
    final badgeColor = isPainkiller
        ? const Color(0xFFEF4444)
        : const Color(0xFF3B82F6);
    final badgeText = isPainkiller
        ? Ar.painkillerTypeBadge
        : Ar.treatmentTypeBadge;
    final hue = (med.name.codeUnits.fold(0, (a, b) => a + b) * 137) % 360;
    final cardAccent = HSLColor.fromAHSL(
      1.0,
      hue.toDouble(),
      0.6,
      0.45,
    ).toColor();

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          // Top colored bar
          Container(
            height: 5,
            decoration: BoxDecoration(
              color: cardAccent,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── Row 1: Icon + Name + Type Badge + Delete ──
                Row(
                  children: [
                    // Med Icon
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: cardAccent.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(
                        isPainkiller
                            ? Icons.healing_rounded
                            : Icons.medication_rounded,
                        color: cardAccent,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Name + badge
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            med.name,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 3),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: badgeColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              badgeText,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: badgeColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Delete button
                    IconButton(
                      onPressed: () => _confirmDelete(context, med),
                      icon: const Icon(Icons.delete_outline_rounded),
                      color: Colors.red[400],
                      tooltip: Ar.deleteMedicineAction,
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.red.withValues(alpha: 0.08),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // ── Row 2: Stock + Dose info ──
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 9,
                  ),
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF0F172A)
                        : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(12),
                    border: med.isLowStock
                        ? Border.all(color: Colors.red.withValues(alpha: 0.4))
                        : null,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        med.isLowStock
                            ? Icons.warning_amber_rounded
                            : Icons.inventory_2_outlined,
                        size: 16,
                        color: med.isLowStock ? Colors.red : Colors.grey[500],
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          '${Ar.stockRemainingLabel}: ${med.totalPills} ${med.unitLabel}',
                          style: TextStyle(
                            fontSize: 12.5,
                            color: med.isLowStock
                                ? Colors.red
                                : Colors.grey[600],
                            fontWeight: med.isLowStock
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (med.isLowStock) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            Ar.lowStockAlertBadge,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                // ── Dose Timing Timeline: Previous Dose, Next Dose, Countdown ──
                if (med.isTreatment) ...[
                  Builder(
                    builder: (context) {
                      final nextInfo = reminderService.getNextDoseForMedicine(med);
                      if (nextInfo == null) return const SizedBox.shrink();
                      return Container(
                        margin: const EdgeInsets.only(top: 8, bottom: 4),
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.black26 : const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: theme.dividerColor.withValues(alpha: isDark ? 0.15 : 0.3),
                          ),
                        ),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.history_rounded, size: 14, color: Color(0xFF64748B)),
                                const SizedBox(width: 4),
                                Text(
                                  'الجرعة السابقة: ',
                                  style: TextStyle(fontSize: 11, color: Colors.grey[600], fontWeight: FontWeight.w600),
                                ),
                                Expanded(
                                  child: Text(
                                    nextInfo.lastTakenFormattedText,
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: isDark ? Colors.grey[300] : const Color(0xFF334155),
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Row(
                                    children: [
                                      const Icon(Icons.alarm_on_rounded, size: 14, color: Color(0xFF0D9488)),
                                      const SizedBox(width: 4),
                                      Text(
                                        'التالية: ',
                                        style: TextStyle(fontSize: 11, color: Colors.grey[600], fontWeight: FontWeight.w600),
                                      ),
                                      Expanded(
                                        child: Text(
                                          nextInfo.nextDoseFullText,
                                          style: const TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF0D9488),
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF0D9488).withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    nextInfo.remainingCountdownText,
                                    style: const TextStyle(
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF0D9488),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ] else ...[
                  Builder(
                    builder: (context) {
                      final safety = reminderService.getPainkillerSafety(med);
                      return Container(
                        margin: const EdgeInsets.only(top: 8, bottom: 4),
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.black26 : const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: theme.dividerColor.withValues(alpha: isDark ? 0.15 : 0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              safety.isSafeNow ? Icons.check_circle_outline_rounded : Icons.timelapse_rounded,
                              size: 15,
                              color: safety.isSafeNow ? const Color(0xFF10B981) : const Color(0xFFF59E0B),
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                safety.statusMessage,
                                style: TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.bold,
                                  color: safety.isSafeNow ? const Color(0xFF047857) : const Color(0xFFB45309),
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
                const SizedBox(height: 10),

                // ── Row 3: Action Buttons ──
                Row(
                  children: [
                    // Edit button
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => onEdit(med),
                        icon: const Icon(Icons.edit_outlined, size: 16),
                        label: const Text(
                          Ar.editBtn,
                          style: TextStyle(fontSize: 13),
                        ),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          side: BorderSide(
                            color: theme.colorScheme.primary.withValues(
                              alpha: 0.4,
                            ),
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    // Take Dose / Refill button
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: med.isOutOfStock
                            ? () => onRefill(med)
                            : () => onTakeDose(med),
                        icon: Icon(
                          med.isOutOfStock
                              ? Icons.add_circle_outline
                              : Icons.check_circle_outline,
                          size: 16,
                        ),
                        label: Text(
                          med.isOutOfStock ? Ar.refillBtn : Ar.takeMedicineBtn,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: med.isOutOfStock
                              ? Colors.orange[600]
                              : theme.colorScheme.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF0D9488).withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.medication_rounded,
              size: 56,
              color: Color(0xFF0D9488),
            ),
          ),
          const SizedBox(height: 18),
          const Text(
            Ar.noMedicinesYetTitle,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            Ar.noMedicinesYetDesc,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13.5,
              color: Colors.grey[600],
              height: 1.5,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: onAddMedicine,
            icon: const Icon(Icons.add_rounded, size: 20),
            label: const Text(
              Ar.addMedicineBtn,
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0D9488),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, Medicine med) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.delete_outline_rounded, color: Colors.red),
            const SizedBox(width: 8),
            const Text(Ar.deleteMedConfirmTitle),
          ],
        ),
        content: Text(Ar.deleteMedConfirmBody(med.name)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(Ar.cancel),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              onDelete(med.id);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text(Ar.deleteBtn),
          ),
        ],
      ),
    );
  }
}
