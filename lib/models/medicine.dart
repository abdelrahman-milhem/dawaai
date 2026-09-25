import 'dart:convert';
import 'package:flutter/material.dart';
import '../ar.dart';

enum MedicineType {
  treatment, // دواء علاجي منتظم (مجدول بأوقات محددة)
  painkiller, // مسكن ألم (يؤخذ عند اللزوم مع فاصل أمان)
}

enum MedicineForm {
  pill, // حبوب / أقراص
  capsule, // كبسولات
  syrup, // شراب / ملعقة
  injection, // حقنة
  drops, // قطرة
  inhaler, // بخاخ
  ointment, // مرهم
}

class Medicine {
  final String id;
  String name;
  MedicineType type;
  MedicineForm form;
  int totalPills; // كم حبة عندك (المخزون المتوفر)
  int pillsPerDose; // كم حبة في كل جرعة
  int lowStockThreshold; // حد التنبيه بنقص المخزون (مثلاً 5 حبات)
  String instructions; // تعليمات (قبل الأكل، بعد الأكل، مع كوب ماء...)
  List<TimeOfDay> scheduledTimes; // أوقات الجرعات الأصلية
  int minSafeIntervalHours; // للمسكنات: الحد الأدنى للساعات بين الجرعات (مثلاً 4 أو 6 ساعات)
  int intervalHours; // الفاصل الساعي بين الجرعات (مثلاً كل 8 ساعات أو 12 ساعة) للعد الديناميكي عند الاستيقاظ
  int maxDailyDoses; // للمسكنات: الحد الأقصى المسموح به يومياً (مثلاً 4 جرعات)
  int colorValue; // اللون المخصص للدواء (يتم اختياره تلقائياً)
  int iconCode; // رمز الأيقونة
  DateTime createdAt;
  bool isActive;
  String profileId; // 'self', 'father', 'mother', etc.
  String activeIngredient; // المادة الفعالة لفحص التعارضات
  TimeOfDay? firstDoseTime; // موعد أول جرعة أخذها المستخدم (نقطة ارتكاز الجدول)
  DateTime? lastTakenTime; // وقت وتاريخ آخر جرعة أُخذت فعلياً
  DateTime? dynamicNextDoseTime; // موعد الجرعة التالية المعاد حسابه تلقائياً بناءً على آخر جرعة
  String? dynamicRescheduleNote; // ملاحظة الترحيل الذكي

  Medicine({
    required this.id,
    required this.name,
    required this.type,
    this.form = MedicineForm.pill,
    required this.totalPills,
    this.pillsPerDose = 1,
    this.lowStockThreshold = 5,
    this.instructions = Ar.foodAfter,
    this.scheduledTimes = const [],
    this.minSafeIntervalHours = 6,
    this.intervalHours = 8,
    this.maxDailyDoses = 4,
    this.colorValue = 0xFF0D9488,
    this.iconCode = 0xe40f,
    DateTime? createdAt,
    this.isActive = true,
    this.profileId = 'self',
    this.activeIngredient = '',
    this.firstDoseTime,
    this.lastTakenTime,
    this.dynamicNextDoseTime,
    this.dynamicRescheduleNote,
  }) : createdAt = createdAt ?? DateTime.now();


  bool get isPainkiller => type == MedicineType.painkiller;
  bool get isTreatment => type == MedicineType.treatment;
  bool get isLowStock => totalPills <= lowStockThreshold;
  bool get isOutOfStock => totalPills <= 0;

  String get typeLabel => isPainkiller ? Ar.typePainkillerLabel : Ar.typeTreatmentLabel;

  String get formLabel {
    switch (form) {
      case MedicineForm.pill:
        return Ar.formPill;
      case MedicineForm.capsule:
        return Ar.formCapsule;
      case MedicineForm.syrup:
        return Ar.formSyrupMl;
      case MedicineForm.injection:
        return Ar.formInjectionPlural;
      case MedicineForm.drops:
        return Ar.formDrops;
      case MedicineForm.inhaler:
        return Ar.formInhaler;
      case MedicineForm.ointment:
        return Ar.formOintment;
    }
  }

  String get unitLabel {
    switch (form) {
      case MedicineForm.pill:
      case MedicineForm.capsule:
        return Ar.unitPill;
      case MedicineForm.syrup:
        return Ar.unitMl;
      case MedicineForm.injection:
        return Ar.unitInjection;
      case MedicineForm.drops:
        return Ar.unitDrop;
      case MedicineForm.inhaler:
        return Ar.unitPuff;
      case MedicineForm.ointment:
        return Ar.unitDose;
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'type': type.index,
      'form': form.index,
      'totalPills': totalPills,
      'pillsPerDose': pillsPerDose,
      'lowStockThreshold': lowStockThreshold,
      'instructions': instructions,
      'scheduledTimes': scheduledTimes.map((t) => '${t.hour}:${t.minute}').toList(),
      'minSafeIntervalHours': minSafeIntervalHours,
      'intervalHours': intervalHours,
      'maxDailyDoses': maxDailyDoses,
      'colorValue': colorValue,
      'iconCode': iconCode,
      'createdAt': createdAt.toIso8601String(),
      'isActive': isActive,
      'profileId': profileId,
      'activeIngredient': activeIngredient,
      'firstDoseTime': firstDoseTime != null ? '${firstDoseTime!.hour}:${firstDoseTime!.minute}' : null,
      'lastTakenTime': lastTakenTime?.toIso8601String(),
      'dynamicNextDoseTime': dynamicNextDoseTime?.toIso8601String(),
      'dynamicRescheduleNote': dynamicRescheduleNote,
    };
  }

  factory Medicine.fromMap(Map<String, dynamic> map) {
    List<TimeOfDay> times = [];
    if (map['scheduledTimes'] != null) {
      final list = map['scheduledTimes'] as List;
      times = list.map((item) {
        final parts = (item as String).split(':');
        return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
      }).toList();
    }

    TimeOfDay? firstTime;
    if (map['firstDoseTime'] != null) {
      final parts = (map['firstDoseTime'] as String).split(':');
      firstTime = TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
    } else if (times.isNotEmpty) {
      firstTime = times.first;
    }

    return Medicine(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      type: MedicineType.values[map['type'] ?? 0],
      form: MedicineForm.values[map['form'] ?? 0],
      totalPills: map['totalPills'] ?? 0,
      pillsPerDose: map['pillsPerDose'] ?? 1,
      lowStockThreshold: map['lowStockThreshold'] ?? 5,
      instructions: map['instructions'] ?? '',
      scheduledTimes: times,
      minSafeIntervalHours: map['minSafeIntervalHours'] ?? 6,
      intervalHours: map['intervalHours'] ?? (times.length > 1 ? (24 ~/ times.length) : 8),
      maxDailyDoses: map['maxDailyDoses'] ?? 4,
      colorValue: map['colorValue'] ?? getAutomaticColor(map['name'] ?? ''),
      iconCode: map['iconCode'] ?? 0xe40f,
      createdAt: map['createdAt'] != null ? DateTime.parse(map['createdAt']) : DateTime.now(),
      isActive: map['isActive'] ?? true,
      profileId: map['profileId'] ?? 'self',
      activeIngredient: map['activeIngredient'] ?? '',
      firstDoseTime: firstTime,
      lastTakenTime: map['lastTakenTime'] != null ? DateTime.parse(map['lastTakenTime']) : null,
      dynamicNextDoseTime: map['dynamicNextDoseTime'] != null ? DateTime.parse(map['dynamicNextDoseTime']) : null,
      dynamicRescheduleNote: map['dynamicRescheduleNote'],
    );
  }

  String toJson() => json.encode(toMap());
  factory Medicine.fromJson(String source) => Medicine.fromMap(json.decode(source));

  Medicine copyWith({
    String? id,
    String? name,
    MedicineType? type,
    MedicineForm? form,
    int? totalPills,
    int? pillsPerDose,
    int? lowStockThreshold,
    String? instructions,
    List<TimeOfDay>? scheduledTimes,
    int? minSafeIntervalHours,
    int? intervalHours,
    int? maxDailyDoses,
    int? colorValue,
    int? iconCode,
    DateTime? createdAt,
    bool? isActive,
    String? profileId,
    String? activeIngredient,
    TimeOfDay? firstDoseTime,
    DateTime? lastTakenTime,
    DateTime? dynamicNextDoseTime,
    String? dynamicRescheduleNote,
  }) {
    return Medicine(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      form: form ?? this.form,
      totalPills: totalPills ?? this.totalPills,
      pillsPerDose: pillsPerDose ?? this.pillsPerDose,
      lowStockThreshold: lowStockThreshold ?? this.lowStockThreshold,
      instructions: instructions ?? this.instructions,
      scheduledTimes: scheduledTimes ?? this.scheduledTimes,
      minSafeIntervalHours: minSafeIntervalHours ?? this.minSafeIntervalHours,
      intervalHours: intervalHours ?? this.intervalHours,
      maxDailyDoses: maxDailyDoses ?? this.maxDailyDoses,
      colorValue: colorValue ?? this.colorValue,
      iconCode: iconCode ?? this.iconCode,
      createdAt: createdAt ?? this.createdAt,
      isActive: isActive ?? this.isActive,
      profileId: profileId ?? this.profileId,
      activeIngredient: activeIngredient ?? this.activeIngredient,
      firstDoseTime: firstDoseTime ?? this.firstDoseTime,
      lastTakenTime: lastTakenTime ?? this.lastTakenTime,
      dynamicNextDoseTime: dynamicNextDoseTime ?? this.dynamicNextDoseTime,
      dynamicRescheduleNote: dynamicRescheduleNote ?? this.dynamicRescheduleNote,
    );
  }

  /// يختار لوناً متناسقاً وجميلاً تلقائياً لكل دواء لتمييزه بسهولة دون إرباك المستخدم
  static int getAutomaticColor(String name, [int? seed]) {
    const palette = [
      0xFF0D9488, // Medical Teal
      0xFF2563EB, // Royal Blue
      0xFF7C3AED, // Violet
      0xFFE11D48, // Crimson
      0xFFD97706, // Amber
      0xFF059669, // Emerald
      0xFFDB2777, // Rose
      0xFF0891B2, // Cyan
      0xFF4F46E5, // Indigo
      0xFFEA580C, // Coral Orange
    ];
    if (name.trim().isEmpty) {
      final s = seed ?? DateTime.now().millisecondsSinceEpoch;
      return palette[s.abs() % palette.length];
    }
    final hash = name.trim().codeUnits.fold(0, (sum, c) => (sum * 31 + c) & 0x7FFFFFFF);
    return palette[hash % palette.length];
  }

  /// يحسب مواعيد الجرعات اليومية تلقائياً بدءاً من موعد أول جرعة أخذها المستخدم
  static List<TimeOfDay> calculateScheduledTimes({
    required TimeOfDay firstDose,
    required int dosesPerDay,
    int? intervalHours,
  }) {
    if (dosesPerDay <= 1) {
      return [firstDose];
    }
    final interval = intervalHours ?? (24 ~/ dosesPerDay);
    final List<TimeOfDay> result = [];
    for (int i = 0; i < dosesPerDay; i++) {
      final totalMinutes = (firstDose.hour * 60 + firstDose.minute + (i * interval * 60)) % (24 * 60);
      final hour = totalMinutes ~/ 60;
      final minute = totalMinutes % 60;
      result.add(TimeOfDay(hour: hour, minute: minute));
    }
    result.sort((a, b) => (a.hour * 60 + a.minute).compareTo(b.hour * 60 + b.minute));
    return result;
  }
}

