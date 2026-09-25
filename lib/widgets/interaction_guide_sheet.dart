import 'package:flutter/material.dart';

import '../ar.dart';
import '../models/medicine.dart';
import '../models/drug_interaction.dart';

class InteractionGuideSheet extends StatelessWidget {
  final List<Medicine> medicines;

  const InteractionGuideSheet({super.key, required this.medicines});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final medNames = medicines.map((m) => m.name).toList();
    final interactions = DrugInteractionService.checkInteractions(medNames);

    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Expanded(
                child: Row(
                  children: [
                    Icon(
                      Icons.security_rounded,
                      color: Color(0xFFEF4444),
                      size: 24,
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        Ar.interactionsTitle,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close),
              ),
            ],
          ),
          const SizedBox(height: 14),

          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Section 1: Active Interactions
                  Row(
                    children: [
                      Icon(
                        interactions.isEmpty
                            ? Icons.verified_user_rounded
                            : Icons.warning_amber_rounded,
                        color: interactions.isEmpty
                            ? const Color(0xFF10B981)
                            : Colors.red,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          Ar.interactionsResultTitle(medicines.length),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  if (interactions.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981).withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: const Color(0xFF10B981).withValues(alpha: 0.3),
                        ),
                      ),
                      child: const Row(
                        children: [
                          Icon(
                            Icons.check_circle_outline,
                            color: Color(0xFF10B981),
                            size: 28,
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  Ar.noCurrentInteractions,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF065F46),
                                    fontSize: 14,
                                  ),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  Ar.noInteractionsDesc,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF047857),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    ...interactions.map((alert) {
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: alert.isSevere
                              ? const Color(0xFFFEF2F2)
                              : const Color(0xFFFFFBEB),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: alert.isSevere
                                ? const Color(0xFFEF4444)
                                : const Color(0xFFF59E0B),
                            width: 1.5,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  alert.isSevere
                                      ? Icons.dangerous_rounded
                                      : Icons.warning_rounded,
                                  color: alert.isSevere
                                      ? const Color(0xFFEF4444)
                                      : const Color(0xFFD97706),
                                  size: 24,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    alert.title,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                      color: alert.isSevere
                                          ? const Color(0xFF991B1B)
                                          : const Color(0xFF92400E),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              alert.description,
                              style: TextStyle(
                                fontSize: 13,
                                height: 1.4,
                                color: alert.isSevere
                                    ? const Color(0xFF7F1D1D)
                                    : const Color(0xFF78350F),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    '💡 ',
                                    style: TextStyle(fontSize: 14),
                                  ),
                                  Expanded(
                                    child: Text(
                                      alert.clinicalAdvice,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black87,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    }),

                  const SizedBox(height: 24),

                  // Section 2: Smart Food & Drink Guidelines
                  const Row(
                    children: [
                      Icon(
                        Icons.restaurant_rounded,
                        color: Color(0xFF0D9488),
                        size: 20,
                      ),
                      SizedBox(width: 8),
                      Text(
                        Ar.foodInteractionsTitle,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  ...medicines.map((med) {
                    final guide = DrugInteractionService.getFoodGuidelines(
                      med.name,
                    );
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                CircleAvatar(
                                  radius: 12,
                                  backgroundColor: Color(med.colorValue)
                                      .withValues(alpha: 0.15),
                                  child: Icon(
                                    Icons.medication,
                                    size: 14,
                                    color: Color(med.colorValue),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  med.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  '🍽️ ',
                                  style: TextStyle(fontSize: 12),
                                ),
                                Expanded(
                                  child: Text(
                                    guide['meal']!,
                                    style: TextStyle(
                                      fontSize: 12.5,
                                      color: Colors.grey[700],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  '⚠️ ',
                                  style: TextStyle(fontSize: 12),
                                ),
                                Expanded(
                                  child: Text(
                                    guide['avoid']!,
                                    style: TextStyle(
                                      fontSize: 12.5,
                                      color: Colors.grey[700],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  Ar.missedDoseLabel,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Expanded(
                                  child: Text(
                                    guide['missed']!,
                                    style: TextStyle(
                                      fontSize: 12.5,
                                      color: Colors.grey[700],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
