import 'package:flutter/material.dart';

import '../ar.dart';
import '../models/medicine.dart';
import '../models/dose_log.dart';
import '../services/reminder_service.dart';

class DoseLogSheet extends StatefulWidget {
  final Medicine medicine;
  final MedicationSafetyInfo? safetyInfo;
  final Function(DoseLog log) onConfirmed;

  const DoseLogSheet({
    super.key,
    required this.medicine,
    this.safetyInfo,
    required this.onConfirmed,
  });

  @override
  State<DoseLogSheet> createState() => _DoseLogSheetState();
}

class _DoseLogSheetState extends State<DoseLogSheet> {
  int _pillsTaken = 1;
  double _painLevel = 5;
  String _notes = '';
  final List<String> _quickNotes = Ar.quickPainNotes;

  @override
  void initState() {
    super.initState();
    _pillsTaken = widget.medicine.pillsPerDose;
  }

  Color get _painColor {
    if (_painLevel <= 3) return Colors.green;
    if (_painLevel <= 6) return Colors.orange;
    return Colors.red;
  }

  Future<void> _handleConfirmDose() async {
    final safety = widget.safetyInfo;
    if (safety != null && !safety.isSafeNow) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Row(
            children: [
              const Icon(Icons.warning_amber_rounded, color: Colors.red, size: 28),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  safety.warningTitle.isNotEmpty ? safety.warningTitle : Ar.earlyIntakeWarningTitle,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.red),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                safety.warningDetails.isNotEmpty ? safety.warningDetails : safety.statusMessage,
                style: const TextStyle(fontSize: 13.5, height: 1.5),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline_rounded, color: Colors.red, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'الحد الأدنى للفاصل الآمن: ${safety.safeIntervalHours} ساعات',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5, color: Colors.red),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF0D9488),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              ),
              child: const Text(
                Ar.earlyIntakeWaitRecommendation,
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red[700],
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text(Ar.earlyIntakeConfirmOverride),
            ),
          ],
        ),
      );

      if (confirmed != true) return;
    }

    final log = DoseLog(
      id: 'log_${DateTime.now().millisecondsSinceEpoch}',
      medicineId: widget.medicine.id,
      medicineName: widget.medicine.name,
      takenAt: DateTime.now(),
      pillsTaken: _pillsTaken,
      isPainkiller: widget.medicine.isPainkiller,
      painLevel: widget.medicine.isPainkiller ? _painLevel.toInt() : null,
      notes: _notes.isNotEmpty ? _notes : null,
    );
    widget.onConfirmed(log);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final med = widget.medicine;
    final isPainkiller = med.isPainkiller;
    final safety = widget.safetyInfo;

    return Container(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Header
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: Color(med.colorValue)
                      .withValues(alpha: 0.15),
                  radius: 24,
                  child: Icon(
                    isPainkiller
                        ? Icons.healing_rounded
                        : Icons.medication_rounded,
                    color: Color(med.colorValue),
                    size: 26,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        Ar.takeDoseSheetTitle,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        med.name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Safety Warning if NOT safe (لجميع الأدوية: مسكنات وعلاجات يومية)
            if (safety != null && !safety.isSafeNow) ...[
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.red.withValues(alpha: 0.5), width: 1.5),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.warning_amber_rounded,
                          color: Colors.red,
                          size: 28,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            safety.warningTitle.isNotEmpty
                                ? safety.warningTitle
                                : Ar.earlyIntakeWarningTitle,
                            style: const TextStyle(
                              color: Colors.red,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      safety.warningDetails.isNotEmpty
                          ? safety.warningDetails
                          : safety.statusMessage,
                      style: const TextStyle(
                        color: Colors.red,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Safe message if SAFE
            if (safety == null || safety.isSafeNow) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: Colors.green.withValues(alpha: 0.4),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.check_circle_outline,
                      color: Colors.green,
                      size: 24,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        isPainkiller ? Ar.safePainkillerNotice : 'الموعد آمن طبياً وجاهز للتناول',
                        style: const TextStyle(
                          color: Color(0xFF047857),
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Quantity selector & Inventory Impact
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: theme.dividerColor.withValues(alpha: 0.2),
                ),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        Ar.consumedQuantityLabel,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      Row(
                        children: [
                          IconButton(
                            onPressed: _pillsTaken > 1
                                ? () => setState(() => _pillsTaken--)
                                : null,
                            icon: const Icon(Icons.remove_circle_outline),
                            color: theme.colorScheme.primary,
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary.withValues(
                                alpha: 0.1,
                              ),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '$_pillsTaken ${med.unitLabel}',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: () => setState(() => _pillsTaken++),
                            icon: const Icon(Icons.add_circle_outline),
                            color: theme.colorScheme.primary,
                          ),
                        ],
                      ),
                    ],
                  ),
                  const Divider(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        Ar.stockAfterDoseLabel,
                        style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                      ),
                      Text(
                        Ar.stockRemainingFormatted(
                          (med.totalPills - _pillsTaken).clamp(0, 9999),
                          med.totalPills,
                          med.unitLabel,
                        ),
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color:
                              (med.totalPills - _pillsTaken) <=
                                  med.lowStockThreshold
                              ? Colors.red
                              : Colors.green,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Dynamic Next Dose Recalculation Note
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: theme.colorScheme.primary.withValues(alpha: 0.2),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.auto_mode_rounded,
                    color: theme.colorScheme.primary,
                    size: 22,
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      Ar.dynamicRescheduleExplainer,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF0D9488),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Painkiller specific: Pain Level & Reason
            if (isPainkiller) ...[
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: theme.dividerColor.withValues(alpha: 0.2),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          Ar.currentPainLevelLabel,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: _painColor.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${_painLevel.toInt()}/10 - ${Ar.painDescription(_painLevel)}',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: _painColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                    Slider(
                      value: _painLevel,
                      min: 1,
                      max: 10,
                      divisions: 9,
                      activeColor: _painColor,
                      label: '${_painLevel.toInt()}',
                      onChanged: (val) => setState(() => _painLevel = val),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      Ar.painCausePrompt,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _quickNotes.map((item) {
                        final isSelected = _notes == item;
                        return ChoiceChip(
                          label: Text(item),
                          selected: isSelected,
                          onSelected: (selected) {
                            setState(() {
                              _notes = selected ? item : '';
                            });
                          },
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Action Button
            ElevatedButton.icon(
              onPressed: _handleConfirmDose,
              icon: const Icon(Icons.check),
              label: Text(
                isPainkiller
                    ? Ar.confirmTakePainkillerNow
                    : Ar.confirmTakeMedicineNow,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: isPainkiller
                    ? const Color(0xFFEF4444)
                    : theme.colorScheme.primary,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
