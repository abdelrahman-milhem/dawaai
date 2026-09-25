import 'dart:convert';

enum NotificationType {
  treatmentReminder, // تذكير بموعد دواء علاجي
  painkillerSafe, // إشعار أمان المسكن: يمكنك تناول المسكن الآن بأمان إذا كنت تشعر بألم
  lowStock, // تنبيه انخفاض المخزون
}

class AppNotificationItem {
  final String id;
  final String title;
  final String message;
  final NotificationType type;
  final String medicineId;
  final String medicineName;
  final DateTime timestamp;
  bool isRead;

  AppNotificationItem({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.medicineId,
    required this.medicineName,
    required this.timestamp,
    this.isRead = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'message': message,
      'type': type.index,
      'medicineId': medicineId,
      'medicineName': medicineName,
      'timestamp': timestamp.toIso8601String(),
      'isRead': isRead,
    };
  }

  factory AppNotificationItem.fromMap(Map<String, dynamic> map) {
    return AppNotificationItem(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      message: map['message'] ?? '',
      type: NotificationType.values[map['type'] ?? 0],
      medicineId: map['medicineId'] ?? '',
      medicineName: map['medicineName'] ?? '',
      timestamp: map['timestamp'] != null ? DateTime.parse(map['timestamp']) : DateTime.now(),
      isRead: map['isRead'] ?? false,
    );
  }

  String toJson() => json.encode(toMap());
  factory AppNotificationItem.fromJson(String source) => AppNotificationItem.fromMap(json.decode(source));
}
