import 'medicine.dart';

class DrugInfo {
  final String id;
  final String tradeName; // الاسم التجاري (مثل: بنادول إكسترا - Panadol Extra)
  final String genericName; // الاسم العلمي (مثل: Paracetamol + Caffeine)
  final String company; // الشركة المصنعة (مثل: GSK, Pfizer, Novartis, Hikma...)
  final String category; // التصنيف الطبي (مسكن، مضاد حيوي، جهاز هضمي...)
  final MedicineType type; // treatment أو painkiller
  final MedicineForm defaultForm;
  final String uses; // دواعي الاستعمال بالتفصيل
  final String instructions; // طريقة الاستخدام والجرعة
  final String precautions; // محاذير الاستخدام وموانع الاستعمال
  final String sideEffects; // الأعراض الجانبية الشائعة
  final int defaultIntervalHours; // الفاصل الافتراضي بالساعات
  final bool isRare; // هل هو دواء نادر أو تخصصي
  final List<String> availableDosages; // جميع الجرعات والعيارات المتوفرة عالمياً ومحلياً
  final List<String> barcodes; // أكواد الباركود و EAN و GTIN المرتبطة بالدواء

  const DrugInfo({
    required this.id,
    required this.tradeName,
    required this.genericName,
    required this.company,
    required this.category,
    required this.type,
    required this.defaultForm,
    required this.uses,
    required this.instructions,
    required this.precautions,
    required this.sideEffects,
    this.defaultIntervalHours = 8,
    this.isRare = false,
    this.availableDosages = const [],
    this.barcodes = const [],
  });

  /// Normalize Arabic text for fuzzy matching (hamzas, alefs, teh marbuta, diacritics)
  static String normalizeArabic(String text) {
    return text
        .toLowerCase()
        .replaceAll(RegExp(r'[\u064B-\u065F\u0670]'), '') // remove tashkeel
        .replaceAll(RegExp(r'[أإآٱ]'), 'ا')
        .replaceAll('ة', 'ه')
        .replaceAll('ى', 'ي')
        .replaceAll('ئ', 'ي')
        .replaceAll('ؤ', 'و')
        .trim();
  }

  /// Check if query matches trade name, generic name, company, uses, or any available dosage
  bool matches(String query) {
    if (query.trim().isEmpty) return true;
    final q = query.trim().toLowerCase();
    final qNorm = normalizeArabic(q);

    final tradeNorm = normalizeArabic(tradeName);
    final genericNorm = normalizeArabic(genericName);
    final companyNorm = normalizeArabic(company);
    final categoryNorm = normalizeArabic(category);
    final usesNorm = normalizeArabic(uses);

    return tradeName.toLowerCase().contains(q) ||
        tradeNorm.contains(qNorm) ||
        genericName.toLowerCase().contains(q) ||
        genericNorm.contains(qNorm) ||
        company.toLowerCase().contains(q) ||
        companyNorm.contains(qNorm) ||
        category.toLowerCase().contains(q) ||
        categoryNorm.contains(qNorm) ||
        uses.toLowerCase().contains(q) ||
        usesNorm.contains(qNorm) ||
        barcodes.any((b) => b.toLowerCase().contains(q)) ||
        availableDosages.any((d) => normalizeArabic(d).contains(qNorm) || d.toLowerCase().contains(q));
  }

  /// Check if a scanned barcode matches this drug
  bool matchesBarcode(String rawBarcode) {
    final clean = rawBarcode.trim().replaceAll(RegExp(r'[^0-9a-zA-Z]'), '').toLowerCase();
    if (clean.isEmpty) return false;
    for (final b in barcodes) {
      final cleanB = b.trim().replaceAll(RegExp(r'[^0-9a-zA-Z]'), '').toLowerCase();
      if (cleanB == clean || clean.contains(cleanB) || cleanB.contains(clean)) {
        return true;
      }
    }
    return id.toLowerCase() == clean;
  }
}
