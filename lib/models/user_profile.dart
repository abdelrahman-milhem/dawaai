import 'dart:convert';
import '../ar.dart';

class UserProfile {
  final String id;
  final String name;
  final String relation;
  final int colorValue;
  final int iconCode;

  UserProfile({
    required this.id,
    required this.name,
    required this.relation,
    this.colorValue = 0xFF0D9488,
    this.iconCode = 0xe491, // Icons.person
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'relation': relation,
      'colorValue': colorValue,
      'iconCode': iconCode,
    };
  }

  factory UserProfile.fromMap(Map<String, dynamic> map) {
    return UserProfile(
      id: map['id'] ?? 'self',
      name: map['name'] ?? Ar.myProfileDefaultName,
      relation: map['relation'] ?? Ar.myProfileRelation,
      colorValue: map['colorValue'] ?? 0xFF0D9488,
      iconCode: map['iconCode'] ?? 0xe491,
    );
  }

  String toJson() => json.encode(toMap());
  factory UserProfile.fromJson(String source) => UserProfile.fromMap(json.decode(source));
}
