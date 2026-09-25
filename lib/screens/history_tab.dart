import 'package:flutter/material.dart';

import '../ar.dart';
import '../models/dose_log.dart';
import '../services/storage_service.dart';
import '../services/medical_time_service.dart';
import '../widgets/pill_refresh_indicator.dart';
import '../utils/date_utils.dart';

class HistoryTab extends StatelessWidget {
  final StorageService storageService;

  const HistoryTab({super.key, required this.storageService});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final logs = storageService.getLogs();

    return PillRefreshIndicator(
      onRefresh: () async {
        await MedicalTimeService.instance.syncWithNetworkTime();
        await Future.delayed(const Duration(milliseconds: 500));
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(left: 16, right: 16, top: 12, bottom: 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
          // Header Summary Card
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: theme.dividerColor.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Expanded(
                  child: _buildStatItem(
                    context,
                    title: Ar.totalDosesRecorded,
                    value: '${logs.length}',
                    icon: Icons.history,
                    color: theme.colorScheme.primary,
                  ),
                ),
                Container(width: 1, height: 40, color: theme.dividerColor),
                Expanded(
                  child: _buildStatItem(
                    context,
                    title: Ar.painkillerDosesStat,
                    value: '${logs.where((l) => l.isPainkiller).length}',
                    icon: Icons.healing,
                    color: const Color(0xFFEF4444),
                  ),
                ),
                Container(width: 1, height: 40, color: theme.dividerColor),
                Expanded(
                  child: _buildStatItem(
                    context,
                    title: Ar.treatmentDosesStat,
                    value: '${logs.where((l) => !l.isPainkiller).length}',
                    icon: Icons.calendar_today,
                    color: const Color(0xFF3B82F6),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),

          // Title
          const Row(
            children: [
              Icon(Icons.timeline_rounded, color: Color(0xFF0D9488), size: 20),
              SizedBox(width: 8),
              Text(
                Ar.timelineHistoryTitle,
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 12),

          if (logs.isEmpty)
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Column(
                children: [
                  Icon(Icons.history_toggle_off, size: 48, color: Colors.grey),
                  SizedBox(height: 12),
                  Text(
                    Ar.emptyHistoryTitle,
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 6),
                  Text(
                    Ar.emptyHistoryDesc,
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 13, color: Colors.grey),
                  ),
                ],
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: logs.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (ctx, index) {
                final log = logs[index];
                return _buildLogCard(context, log);
              },
            ),
        ],
      ),
    ),
    );
  }

  Widget _buildStatItem(
    BuildContext context, {
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Column(
      children: [
        Icon(icon, color: color, size: 20),
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
          title,
          style: const TextStyle(fontSize: 10.5, color: Colors.grey),
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildLogCard(BuildContext context, DoseLog log) {
    final theme = Theme.of(context);
    final isPainkiller = log.isPainkiller;
    final dateStr = AppDateUtils.formatDateTime(log.takenAt);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isPainkiller
              ? const Color(0xFFEF4444).withValues(alpha: 0.25)
              : theme.dividerColor.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isPainkiller
                  ? const Color(0xFFEF4444).withValues(alpha: 0.12)
                  : const Color(0xFF0D9488).withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isPainkiller
                  ? Icons.healing_rounded
                  : Icons.check_circle_outline_rounded,
              color: isPainkiller
                  ? const Color(0xFFEF4444)
                  : const Color(0xFF0D9488),
              size: 20,
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
                        log.medicineName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      dateStr,
                      style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: isPainkiller
                            ? const Color(0xFFEF4444).withValues(alpha: 0.1)
                            : const Color(0xFF0D9488).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        isPainkiller ? Ar.painkillerTag : Ar.treatmentTag,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: isPainkiller
                              ? const Color(0xFFEF4444)
                              : const Color(0xFF0D9488),
                        ),
                      ),
                    ),
                    Text(
                      Ar.deductedPillsDesc(log.pillsTaken),
                      style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                    ),
                  ],
                ),
                if (log.painLevel != null || log.notes != null) ...[
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        if (log.painLevel != null) ...[
                          Icon(
                            Icons.show_chart,
                            size: 14,
                            color: Colors.amber[800],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            Ar.painScoreText(log.painLevel!),
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.bold,
                              color: Colors.amber[900],
                            ),
                          ),
                          const SizedBox(width: 10),
                        ],
                        if (log.notes != null) ...[
                          Icon(Icons.notes, size: 14, color: Colors.grey[600]),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              log.notes!,
                              style: TextStyle(
                                fontSize: 11.5,
                                color: Colors.grey[800],
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
