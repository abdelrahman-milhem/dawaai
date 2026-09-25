import 'dart:convert';

class DoseLog {
  final String id;
  final String medicineId;
  final String medicineName;
  final DateTime takenAt;
  final int pillsTaken;
  final bool isPainkiller;
  final int? painLevel; // 1 (خفيف جداً) إلى 10 (شديد جداً)
  final String? notes; // ملاحظات مثل "صداع نصفي"، "ألم مفاصل"...

  DoseLog({
    required this.id,
    required this.medicineId,
    required this.medicineName,
    required this.takenAt,
    this.pillsTaken = 1,
    this.isPainkiller = false,
    this.painLevel,
    this.notes,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'medicineId': medicineId,
      'medicineName': medicineName,
      'takenAt': takenAt.toIso8601String(),
      'pillsTaken': pillsTaken,
      'isPainkiller': isPainkiller,
      'painLevel': painLevel,
      'notes': notes,
    };
  }

  factory DoseLog.fromMap(Map<String, dynamic> map) {
    return DoseLog(
      id: map['id'] ?? '',
      medicineId: map['medicineId'] ?? '',
      medicineName: map['medicineName'] ?? '',
      takenAt: map['takenAt'] != null ? DateTime.parse(map['takenAt']) : DateTime.now(),
      pillsTaken: map['pillsTaken'] ?? 1,
      isPainkiller: map['isPainkiller'] ?? false,
      painLevel: map['painLevel'],
      notes: map['notes'],
    );
  }

  String toJson() => json.encode(toMap());
  factory DoseLog.fromJson(String source) => DoseLog.fromMap(json.decode(source));
}
