import 'package:flutter/material.dart';

import '../ar.dart';
import '../models/medicine.dart';
import '../services/reminder_service.dart';
import '../utils/date_utils.dart';
import 'safety_indicator.dart';

class MedicineCard extends StatelessWidget {
  final Medicine medicine;
  final PainkillerSafetyInfo? safetyInfo;
  final VoidCallback onTakeDose;
  final VoidCallback onRefill;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const MedicineCard({
    super.key,
    required this.medicine,
    this.safetyInfo,
    required this.onTakeDose,
    required this.onRefill,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final medColor = Color(medicine.colorValue);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Row: Icon, Name, Type Badge, Popup Menu
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: medColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    medicine.isPainkiller
                        ? Icons.healing_rounded
                        : Icons.medication_rounded,
                    color: medColor,
                    size: 26,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              medicine.name,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: medicine.isPainkiller
                                  ? const Color(0xFFEF4444)
                                        .withValues(alpha: 0.12)
                                  : const Color(0xFF0D9488)
                                        .withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              medicine.typeLabel,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: medicine.isPainkiller
                                    ? const Color(0xFFEF4444)
                                    : const Color(0xFF0D9488),
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              '• ${medicine.formLabel}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, size: 20),
                  onSelected: (val) {
                    if (val == 'refill') onRefill();
                    if (val == 'edit') onEdit();
                    if (val == 'delete') onDelete();
                  },
                  itemBuilder: (ctx) => [
                    const PopupMenuItem(
                      value: 'refill',
                      child: Row(
                        children: [
                          Icon(Icons.add_shopping_cart, size: 18),
                          SizedBox(width: 8),
                          Text(Ar.refillStockAction),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit_outlined, size: 18),
                          SizedBox(width: 8),
                          Text(Ar.editMedicineAction),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(
                            Icons.delete_outline,
                            size: 18,
                            color: Colors.red,
                          ),
                          SizedBox(width: 8),
                          Text(
                            Ar.deleteMedicineAction,
                            style: TextStyle(color: Colors.red),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Pills stock section (كم حبة عندك) - Highlighted
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF0F172A)
                    : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(14),
                border: medicine.isLowStock
                    ? Border.all(
                        color: const Color(0xFFEF4444).withValues(alpha: 0.5),
                      )
                    : null,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          medicine.isLowStock
                              ? Icons.warning_amber_rounded
                              : Icons.inventory_2_outlined,
                          size: 18,
                          color: medicine.isLowStock
                              ? const Color(0xFFEF4444)
                              : Colors.grey[600],
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            Ar.availableStockLabel,
                            style: TextStyle(
                              fontSize: 12.5,
                              color: isDark
                                  ? Colors.grey[300]
                                  : Colors.grey[700],
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 6),
                  Row(
                    children: [
                      Text(
                        '${medicine.totalPills} ${medicine.unitLabel}',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: medicine.isOutOfStock
                              ? Colors.red
                              : medicine.isLowStock
                              ? const Color(0xFFEF4444)
                              : (isDark ? Colors.white : Colors.black),
                        ),
                      ),
                      if (medicine.isLowStock) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEF4444),
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
                      const SizedBox(width: 8),
                      InkWell(
                        onTap: onRefill,
                        borderRadius: BorderRadius.circular(6),
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary.withValues(
                              alpha: 0.15,
                            ),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Icon(
                            Icons.add,
                            size: 16,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // If Painkiller: Safety indicator widget
            if (medicine.isPainkiller && safetyInfo != null) ...[
              SafetyIndicatorWidget(safety: safetyInfo!, compact: true),
              const SizedBox(height: 12),
            ],

            // If Treatment: Daily times
            if (medicine.isTreatment && medicine.scheduledTimes.isNotEmpty) ...[
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Icon(Icons.alarm, size: 16, color: Colors.grey),
                  const SizedBox(width: 6),
                  const Text(
                    Ar.scheduledTimesLabel,
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: medicine.scheduledTimes.map((t) {
                          final hour = t.hourOfPeriod == 0
                              ? 12
                              : t.hourOfPeriod;
                          final period = t.period == DayPeriod.am
                              ? Ar.amShort
                              : Ar.pmShort;
                          final minute = t.minute.toString().padLeft(2, '0');
                          return Container(
                            margin: const EdgeInsets.only(left: 6),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary.withValues(
                                alpha: 0.08,
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '$hour:$minute $period',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
            ],

            // Instructions note
            if (medicine.instructions.isNotEmpty) ...[
              Row(
                children: [
                  const Icon(Icons.info_outline, size: 14, color: Colors.grey),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      medicine.instructions,
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
            ],

            // Last Dose Taken & Dynamic Next Dose Info
            if (medicine.lastTakenTime != null) ...[
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF0D9488).withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFF0D9488).withValues(alpha: 0.2),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.check_circle_outline,
                      size: 16,
                      color: Color(0xFF0D9488),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            Ar.lastDoseTakenAtText(
                              AppDateUtils.formatDateTime(
                                medicine.lastTakenTime!,
                              ),
                            ),
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0D9488),
                            ),
                          ),
                          if (medicine.dynamicNextDoseTime != null)
                            Text(
                              Ar.nextDoseScheduledAtText(
                                AppDateUtils.formatTime(
                                  medicine.dynamicNextDoseTime!,
                                ),
                                medicine.intervalHours,
                              ),
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey[700],
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Action Buttons: Take Dose + Delete Button
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: medicine.isOutOfStock ? null : onTakeDose,
                    icon: Icon(
                      medicine.isPainkiller
                          ? Icons.healing
                          : Icons.check_circle_outline,
                      size: 18,
                    ),
                    label: Text(
                      medicine.isOutOfStock
                          ? Ar.outOfStockBadge
                          : medicine.isPainkiller
                          ? (safetyInfo?.isSafeNow ?? true
                                ? Ar.takePainkillerNowBtn
                                : Ar.recordPainkillerDose)
                          : Ar.recordDoseWithAmount(
                              medicine.pillsPerDose,
                              medicine.unitLabel,
                            ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: medicine.isPainkiller
                          ? ((safetyInfo?.isSafeNow ?? true)
                                ? const Color(0xFF10B981)
                                : const Color(0xFFF59E0B))
                          : theme.colorScheme.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        vertical: 12,
                        horizontal: 8,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  onPressed: onDelete,
                  icon: const Icon(
                    Icons.delete_outline,
                    size: 18,
                    color: Colors.red,
                  ),
                  label: const Text(
                    Ar.delete,
                    style: TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.red, width: 1.2),
                    foregroundColor: Colors.red,
                    padding: const EdgeInsets.symmetric(
                      vertical: 12,
                      horizontal: 10,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
