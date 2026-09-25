import 'dart:convert';
import 'medicine.dart';

class HomePharmacyMember {
  final String id;
  final String name;
  final String role; // 'admin' or 'member'
  final DateTime joinedAt;
  final int avatarColor;

  HomePharmacyMember({
    required this.id,
    required this.name,
    this.role = 'member',
    DateTime? joinedAt,
    this.avatarColor = 0xFF0D9488,
  }) : joinedAt = joinedAt ?? DateTime.now();

  bool get isAdmin => role == 'admin';

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'role': role,
      'joinedAt': joinedAt.toIso8601String(),
      'avatarColor': avatarColor,
    };
  }

  factory HomePharmacyMember.fromMap(Map<String, dynamic> map) {
    return HomePharmacyMember(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      role: map['role'] ?? 'member',
      joinedAt: map['joinedAt'] != null ? DateTime.parse(map['joinedAt']) : DateTime.now(),
      avatarColor: map['avatarColor'] ?? 0xFF0D9488,
    );
  }

  String toJson() => json.encode(toMap());
  factory HomePharmacyMember.fromJson(String source) =>
      HomePharmacyMember.fromMap(json.decode(source));
}

class HomePharmacyItem {
  final String id;
  final String name;
  final MedicineForm form;
  final int quantity;
  final String unit;
  final String storageLocation; // 'خزانة الأدوية الرئيسية', 'ثلاجة المطبخ', 'حقيبة الإسعافات', 'أخرى'
  final DateTime? expiryDate;
  final String addedByName;
  final DateTime addedAt;
  final String notes;
  final int lowStockThreshold;

  HomePharmacyItem({
    required this.id,
    required this.name,
    this.form = MedicineForm.pill,
    required this.quantity,
    this.unit = 'حبة',
    this.storageLocation = 'خزانة الأدوية الرئيسية',
    this.expiryDate,
    this.addedByName = 'أنا',
    DateTime? addedAt,
    this.notes = '',
    this.lowStockThreshold = 5,
  }) : addedAt = addedAt ?? DateTime.now();

  bool get isLowStock => quantity <= lowStockThreshold;
  bool get isOutOfStock => quantity <= 0;

  bool get isExpired {
    if (expiryDate == null) return false;
    final now = DateTime.now();
    return expiryDate!.isBefore(DateTime(now.year, now.month, now.day));
  }

  bool get isExpiringSoon {
    if (expiryDate == null || isExpired) return false;
    final now = DateTime.now();
    final difference = expiryDate!.difference(now).inDays;
    return difference <= 60; // 2 months
  }

  bool get isRefrigerated => storageLocation.contains('ثلاجة');

  HomePharmacyItem copyWith({
    String? id,
    String? name,
    MedicineForm? form,
    int? quantity,
    String? unit,
    String? storageLocation,
    DateTime? expiryDate,
    String? addedByName,
    DateTime? addedAt,
    String? notes,
    int? lowStockThreshold,
  }) {
    return HomePharmacyItem(
      id: id ?? this.id,
      name: name ?? this.name,
      form: form ?? this.form,
      quantity: quantity ?? this.quantity,
      unit: unit ?? this.unit,
      storageLocation: storageLocation ?? this.storageLocation,
      expiryDate: expiryDate ?? this.expiryDate,
      addedByName: addedByName ?? this.addedByName,
      addedAt: addedAt ?? this.addedAt,
      notes: notes ?? this.notes,
      lowStockThreshold: lowStockThreshold ?? this.lowStockThreshold,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'form': form.index,
      'quantity': quantity,
      'unit': unit,
      'storageLocation': storageLocation,
      'expiryDate': expiryDate?.toIso8601String(),
      'addedByName': addedByName,
      'addedAt': addedAt.toIso8601String(),
      'notes': notes,
      'lowStockThreshold': lowStockThreshold,
    };
  }

  factory HomePharmacyItem.fromMap(Map<String, dynamic> map) {
    return HomePharmacyItem(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      form: MedicineForm.values[(map['form'] ?? 0).clamp(0, MedicineForm.values.length - 1)],
      quantity: map['quantity'] ?? 0,
      unit: map['unit'] ?? 'حبة',
      storageLocation: map['storageLocation'] ?? 'خزانة الأدوية الرئيسية',
      expiryDate: map['expiryDate'] != null ? DateTime.parse(map['expiryDate']) : null,
      addedByName: map['addedByName'] ?? 'أنا',
      addedAt: map['addedAt'] != null ? DateTime.parse(map['addedAt']) : DateTime.now(),
      notes: map['notes'] ?? '',
      lowStockThreshold: map['lowStockThreshold'] ?? 5,
    );
  }

  String toJson() => json.encode(toMap());
  factory HomePharmacyItem.fromJson(String source) =>
      HomePharmacyItem.fromMap(json.decode(source));
}

class HomePharmacy {
  final String id; // e.g. "HOME-101"
  String name; // e.g. "صيدلية منزل العائلة"
  String password; // PIN or secret password for joining
  final DateTime createdAt;
  String adminName;
  List<HomePharmacyMember> members;
  List<HomePharmacyItem> items;

  HomePharmacy({
    required this.id,
    required this.name,
    required this.password,
    DateTime? createdAt,
    required this.adminName,
    List<HomePharmacyMember>? members,
    List<HomePharmacyItem>? items,
  })  : createdAt = createdAt ?? DateTime.now(),
        members = members ?? [],
        items = items ?? [];

  HomePharmacy copyWith({
    String? id,
    String? name,
    String? password,
    DateTime? createdAt,
    String? adminName,
    List<HomePharmacyMember>? members,
    List<HomePharmacyItem>? items,
  }) {
    return HomePharmacy(
      id: id ?? this.id,
      name: name ?? this.name,
      password: password ?? this.password,
      createdAt: createdAt ?? this.createdAt,
      adminName: adminName ?? this.adminName,
      members: members ?? List.from(this.members),
      items: items ?? List.from(this.items),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'password': password,
      'createdAt': createdAt.toIso8601String(),
      'adminName': adminName,
      'members': members.map((m) => m.toMap()).toList(),
      'items': items.map((i) => i.toMap()).toList(),
    };
  }

  factory HomePharmacy.fromMap(Map<String, dynamic> map) {
    return HomePharmacy(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      password: map['password'] ?? '',
      createdAt: map['createdAt'] != null ? DateTime.parse(map['createdAt']) : DateTime.now(),
      adminName: map['adminName'] ?? '',
      members: map['members'] != null
          ? (map['members'] as List).map((m) => HomePharmacyMember.fromMap(m)).toList()
          : [],
      items: map['items'] != null
          ? (map['items'] as List).map((i) => HomePharmacyItem.fromMap(i)).toList()
          : [],
    );
  }

  String toJson() => json.encode(toMap());
  factory HomePharmacy.fromJson(String source) =>
      HomePharmacy.fromMap(json.decode(source));
}
