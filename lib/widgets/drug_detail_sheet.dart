import 'package:flutter/material.dart';

import '../ar.dart';
import '../models/drug_info.dart';
import '../models/medicine.dart';

class DrugDetailSheet extends StatelessWidget {
  final DrugInfo drug;
  final Function(DrugInfo drug) onAddToMyMedicines;

  const DrugDetailSheet({
    super.key,
    required this.drug,
    required this.onAddToMyMedicines,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      padding: const EdgeInsets.only(left: 20, right: 20, top: 16, bottom: 24),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Handle
          Center(
            child: Container(
              width: 44,
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: drug.isRare
                      ? const Color(0xFF8B5CF6).withValues(alpha: 0.15)
                      : (drug.type == MedicineType.painkiller
                            ? const Color(0xFFEF4444).withValues(alpha: 0.15)
                            : const Color(0xFF0D9488).withValues(alpha: 0.15)),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  drug.isRare
                      ? Icons.auto_awesome_rounded
                      : (drug.type == MedicineType.painkiller
                            ? Icons.healing_rounded
                            : Icons.medication_rounded),
                  color: drug.isRare
                      ? const Color(0xFF8B5CF6)
                      : (drug.type == MedicineType.painkiller
                            ? const Color(0xFFEF4444)
                            : const Color(0xFF0D9488)),
                  size: 28,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      drug.tradeName,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      Ar.activeIngredientNamed(drug.genericName),
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      Ar.manufacturerNamed(drug.company),
                      style: TextStyle(fontSize: 11.5, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Badges Row
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              _buildBadge(drug.category, const Color(0xFF0D9488)),
              _buildBadge(
                drug.type == MedicineType.painkiller
                    ? Ar.painkillerAsNeeded
                    : Ar.treatmentScheduled,
                drug.type == MedicineType.painkiller
                    ? const Color(0xFFEF4444)
                    : const Color(0xFF3B82F6),
              ),
              if (drug.isRare)
                _buildBadge(Ar.specializedRareDrug, const Color(0xFF8B5CF6)),
            ],
          ),
          const SizedBox(height: 14),

          // CRITICAL MEDICAL SAFETY NOTICE
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF450A0A) : const Color(0xFFFEF2F2),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: const Color(0xFFEF4444).withValues(alpha: 0.5),
              ),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.shield_outlined, color: Color(0xFFEF4444), size: 20),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    Ar.medicalDisclaimer,
                    style: TextStyle(
                      color: Color(0xFF991B1B),
                      fontSize: 11.5,
                      fontWeight: FontWeight.bold,
                      height: 1.35,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Content Sections
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (drug.availableDosages.isNotEmpty) ...[
                    _buildDosagesCard(context),
                    const SizedBox(height: 10),
                  ],

                  _buildSectionCard(
                    context,
                    title: Ar.indicationsSection,
                    icon: Icons.check_circle_outline,
                    color: const Color(0xFF10B981),
                    content: drug.uses,
                  ),
                  const SizedBox(height: 10),

                  _buildSectionCard(
                    context,
                    title: Ar.usageInstructionsSection,
                    icon: Icons.schedule_rounded,
                    color: const Color(0xFF3B82F6),
                    content:
                        '${drug.instructions}\n• ${Ar.safeIntervalPrefix} ${drug.defaultIntervalHours} ${Ar.hoursSuffix}.',
                  ),
                  const SizedBox(height: 10),

                  _buildSectionCard(
                    context,
                    title: Ar.safetyWarningsSection,
                    icon: Icons.warning_amber_rounded,
                    color: const Color(0xFFEF4444),
                    content: drug.precautions,
                  ),
                  const SizedBox(height: 10),

                  _buildSectionCard(
                    context,
                    title: Ar.sideEffectsSection,
                    icon: Icons.info_outline,
                    color: const Color(0xFFF59E0B),
                    content: drug.sideEffects,
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Add to my schedule Button
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              onAddToMyMedicines(drug);
            },
            icon: const Icon(Icons.add_task_rounded),
            label: const Text(
              Ar.addThisDrugToMyMeds,
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14.5),
            ),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              backgroundColor: const Color(0xFF0D9488),
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildSectionCard(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Color color,
    required String content,
  }) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: color),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13.5,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(content, style: const TextStyle(fontSize: 13, height: 1.4)),
        ],
      ),
    );
  }

  Widget _buildDosagesCard(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF0D9488).withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.straighten_rounded,
                size: 18,
                color: Color(0xFF0D9488),
              ),
              SizedBox(width: 8),
              Text(
                Ar.availableDosagesSection,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13.5,
                  color: Color(0xFF0D9488),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: drug.availableDosages.map((dosage) {
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF0D9488).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: const Color(0xFF0D9488).withValues(alpha: 0.35),
                  ),
                ),
                child: Text(
                  dosage,
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0D9488),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
