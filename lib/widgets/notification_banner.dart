import 'package:flutter/material.dart';

import '../ar.dart';
import '../models/app_notification.dart';
import '../models/medicine.dart';
import '../services/storage_service.dart';
import '../services/reminder_service.dart';
import '../utils/date_utils.dart';

class InAppNotificationBanner extends StatelessWidget {
  final AppNotificationItem notification;
  final VoidCallback onDismiss;
  final VoidCallback? onAction;

  const InAppNotificationBanner({
    super.key,
    required this.notification,
    required this.onDismiss,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final isPainkillerSafe =
        notification.type == NotificationType.painkillerSafe;
    final isLowStock = notification.type == NotificationType.lowStock;

    final bgColor = isPainkillerSafe
        ? const Color(0xFF065F46) // Emerald Dark
        : isLowStock
        ? const Color(0xFF991B1B) // Crimson Dark
        : const Color(0xFF1E293B); // Slate Navy

    final iconColor = isPainkillerSafe
        ? const Color(0xFF34D399)
        : isLowStock
        ? const Color(0xFFF87171)
        : const Color(0xFF38BDF8);

    return Material(
      color: Colors.transparent,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.35),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
          border: Border.all(
            color: iconColor.withValues(alpha: 0.3),
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isPainkillerSafe
                    ? Icons.healing_rounded
                    : isLowStock
                    ? Icons.warning_rounded
                    : Icons.alarm_on_rounded,
                color: iconColor,
                size: 24,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          notification.title,
                          style: TextStyle(
                            color: iconColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        Ar.nowTime,
                        style: TextStyle(color: Colors.white54, fontSize: 11),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    notification.message,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 13.5,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              onPressed: onDismiss,
              icon: const Icon(Icons.close, color: Colors.white70, size: 20),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        ),
      ),
    );
  }
}

class NotificationCenterSheet extends StatelessWidget {
  final StorageService storageService;
  final ReminderService reminderService;
  final Function(Medicine medicine) onTakeDose;

  const NotificationCenterSheet({
    super.key,
    required this.storageService,
    required this.reminderService,
    required this.onTakeDose,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final notifications = storageService.getNotifications();
    final medicines = storageService.getMedicines();

    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
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
                      Icons.notifications_active_rounded,
                      color: Color(0xFF0D9488),
                    ),
                    SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        Ar.notificationsCenterTitle,
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              if (notifications.isNotEmpty)
                TextButton(
                  onPressed: () async {
                    final nav = Navigator.of(context);
                    await storageService.clearNotifications();
                    nav.pop();
                  },
                  child: const Text(
                    Ar.clearAllNotifications,
                    style: TextStyle(color: Colors.red),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),

          // Simulation / Test notification buttons for user experience
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: theme.colorScheme.primary.withValues(alpha: 0.2),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  Ar.testLiveNotificationTitle,
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          reminderService.simulateNotificationTest(
                            isPainkiller: true,
                          );
                          Navigator.pop(context);
                        },
                        icon: const Icon(Icons.healing, size: 16),
                        label: const Text(
                          Ar.testSafePainkillerBtn,
                          style: TextStyle(fontSize: 12),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF10B981),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          reminderService.simulateNotificationTest(
                            isPainkiller: false,
                          );
                          Navigator.pop(context);
                        },
                        icon: const Icon(Icons.alarm, size: 16),
                        label: const Text(
                          Ar.testMedTimeBtn,
                          style: TextStyle(fontSize: 12),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0D9488),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Notification List
          Expanded(
            child: notifications.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.notifications_off_outlined,
                          size: 48,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          Ar.noNotificationsYet,
                          style: TextStyle(fontSize: 15, color: Colors.grey),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          Ar.noNotificationsDesc,
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    itemCount: notifications.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (ctx, index) {
                      final item = notifications[index];
                      final isPainkillerSafe =
                          item.type == NotificationType.painkillerSafe;
                      final isLowStock = item.type == NotificationType.lowStock;

                      final matchingMed = medicines
                          .cast<Medicine?>()
                          .firstWhere(
                            (m) => m?.id == item.medicineId,
                            orElse: () => null,
                          );

                      final timeFormatted = AppDateUtils.formatTime(
                        item.timestamp,
                      );

                      return Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: isPainkillerSafe
                              ? const Color(0xFF10B981).withValues(alpha: 0.08)
                              : isLowStock
                              ? const Color(0xFFEF4444).withValues(alpha: 0.08)
                              : theme.cardColor,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isPainkillerSafe
                                ? const Color(0xFF10B981).withValues(alpha: 0.3)
                                : isLowStock
                                ? const Color(0xFFEF4444).withValues(alpha: 0.3)
                                : theme.dividerColor.withValues(alpha: 0.2),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  isPainkillerSafe
                                      ? Icons.check_circle_rounded
                                      : isLowStock
                                      ? Icons.warning_rounded
                                      : Icons.alarm,
                                  color: isPainkillerSafe
                                      ? const Color(0xFF10B981)
                                      : isLowStock
                                      ? const Color(0xFFEF4444)
                                      : theme.colorScheme.primary,
                                  size: 18,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    item.title,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                      color: isPainkillerSafe
                                          ? const Color(0xFF065F46)
                                          : isLowStock
                                          ? const Color(0xFF991B1B)
                                          : null,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  timeFormatted,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              item.message,
                              style: const TextStyle(fontSize: 13, height: 1.3),
                            ),
                            if (matchingMed != null && !isLowStock) ...[
                              const SizedBox(height: 10),
                              Align(
                                alignment: Alignment.centerLeft,
                                child: TextButton.icon(
                                  onPressed: () {
                                    Navigator.pop(context);
                                    onTakeDose(matchingMed);
                                  },
                                  icon: const Icon(Icons.check, size: 16),
                                  label: const Text(Ar.recordTakeNow),
                                  style: TextButton.styleFrom(
                                    foregroundColor: isPainkillerSafe
                                        ? const Color(0xFF047857)
                                        : theme.colorScheme.primary,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 4,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
