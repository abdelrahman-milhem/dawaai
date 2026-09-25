import '../ar.dart';

class DrugInteractionAlert {
  final String medicineAName;
  final String medicineBName;
  final String title;
  final String description;
  final String clinicalAdvice;
  final bool isSevere;

  DrugInteractionAlert({
    required this.medicineAName,
    required this.medicineBName,
    required this.title,
    required this.description,
    required this.clinicalAdvice,
    this.isSevere = false,
  });
}

class DrugInteractionService {
  /// Analyzes a list of medicines and returns detected interactions
  static List<DrugInteractionAlert> checkInteractions(List<String> medicineNames) {
    List<DrugInteractionAlert> alerts = [];
    final lowerNames = medicineNames.map((n) => n.toLowerCase()).toList();

    // 1. فحص ازدواجية الباراسيتامول (Paracetamol Duplication)
    final paracetamolKeywords = Ar.paracetamolSearchKeywords;

    List<String> matchingParacetamol = [];
    for (int i = 0; i < medicineNames.length; i++) {
      final name = lowerNames[i];
      if (paracetamolKeywords.any((k) => name.contains(k))) {
        matchingParacetamol.add(medicineNames[i]);
      }
    }

    if (matchingParacetamol.length >= 2) {
      alerts.add(DrugInteractionAlert(
        medicineAName: matchingParacetamol[0],
        medicineBName: matchingParacetamol[1],
        title: Ar.interactionParacetamolTitle,
        description: Ar.interactionParacetamolDesc(matchingParacetamol[0], matchingParacetamol[1]),
        clinicalAdvice: Ar.interactionParacetamolAdvice,
        isSevere: true,
      ));
    }

    // 2. فحص مضادات الالتهاب غير الستيرويدية (NSAIDs Duplication)
    final nsaidKeywords = Ar.nsaidSearchKeywords;

    List<String> matchingNsaids = [];
    for (int i = 0; i < medicineNames.length; i++) {
      final name = lowerNames[i];
      if (nsaidKeywords.any((k) => name.contains(k))) {
        matchingNsaids.add(medicineNames[i]);
      }
    }

    if (matchingNsaids.length >= 2) {
      alerts.add(DrugInteractionAlert(
        medicineAName: matchingNsaids[0],
        medicineBName: matchingNsaids[1],
        title: Ar.interactionNsaidTitle,
        description: Ar.interactionNsaidDesc(matchingNsaids[0], matchingNsaids[1]),
        clinicalAdvice: Ar.interactionNsaidAdvice,
        isSevere: true,
      ));
    }

    // 3. فحص المضادات الحيوية مع مكملات الكالسيوم أو الحديد أو مضادات الحموضة
    final antibioticKeywords = Ar.antibioticSearchKeywords;
    final mineralKeywords = Ar.mineralSearchKeywords;

    String? foundAntibiotic;
    String? foundMineral;

    for (int i = 0; i < medicineNames.length; i++) {
      final name = lowerNames[i];
      if (antibioticKeywords.any((k) => name.contains(k))) foundAntibiotic = medicineNames[i];
      if (mineralKeywords.any((k) => name.contains(k))) foundMineral = medicineNames[i];
    }

    if (foundAntibiotic != null && foundMineral != null) {
      alerts.add(DrugInteractionAlert(
        medicineAName: foundAntibiotic,
        medicineBName: foundMineral,
        title: Ar.interactionAntibioticTitle,
        description: Ar.interactionAntibioticDesc,
        clinicalAdvice: Ar.interactionAntibioticAdvice,
        isSevere: false,
      ));
    }

    return alerts;
  }

  /// Clinical Food & Drink Interaction Guidelines for a medicine
  static Map<String, String> getFoodGuidelines(String medicineName) {
    final lower = medicineName.toLowerCase();

    if (Ar.nsaidSearchKeywords.any((k) => lower.contains(k))) {
      return {
        'meal': Ar.foodNsaidMeal,
        'avoid': Ar.foodNsaidAvoid,
        'missed': Ar.foodNsaidMissed,
      };
    }

    if (Ar.antibioticSearchKeywords.any((k) => lower.contains(k))) {
      return {
        'meal': Ar.foodAntibioticMeal,
        'avoid': Ar.foodAntibioticAvoid,
        'missed': Ar.foodAntibioticMissed,
      };
    }

    if (Ar.cardiacSearchKeywords.any((k) => lower.contains(k))) {
      return {
        'meal': Ar.foodCardiacMeal,
        'avoid': Ar.foodCardiacAvoid,
        'missed': Ar.foodCardiacMissed,
      };
    }

    if (Ar.paracetamolSearchKeywords.any((k) => lower.contains(k))) {
      return {
        'meal': Ar.foodParacetamolMeal,
        'avoid': Ar.foodParacetamolAvoid,
        'missed': Ar.foodParacetamolMissed,
      };
    }

    // Default general clinical guidelines
    return {
      'meal': Ar.foodGeneralMeal,
      'avoid': Ar.foodGeneralAvoid,
      'missed': Ar.foodGeneralMissed,
    };
  }
}
