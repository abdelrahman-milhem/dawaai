import 'package:flutter/material.dart';

import '../ar.dart';
import '../models/medicine.dart';
import '../models/user_profile.dart';
import '../data/drug_database.dart';
import '../models/drug_info.dart';
import '../utils/date_utils.dart';
import '../screens/barcode_scanner_screen.dart';

/// Clinical Safety Engine for Add Medicine Sheet
class ClinicalSafetyRule {
  /// Determines the locked food timing text for a given drug
  static String getLockedFoodRelation(DrugInfo drug) {
    final instr = drug.instructions.toLowerCase();
    final generic = drug.genericName.toLowerCase();
    final trade = drug.tradeName.toLowerCase();

    // Bedtime
    if (instr.contains('قبل النوم') ||
        trade.contains('نايت') ||
        trade.contains('night')) {
      return Ar.foodBedtime;
    }

    // PPIs, Thyroid, Bisphosphonates (Before food / empty stomach)
    if (instr.contains('قبل الاكل') ||
        instr.contains('قبل الأكل') ||
        instr.contains('فارغة') ||
        instr.contains('فارغه') ||
        generic.contains('omeprazole') ||
        generic.contains('pantoprazole') ||
        generic.contains('esomeprazole') ||
        generic.contains('lansoprazole') ||
        generic.contains('levothyroxine') ||
        trade.contains('اوميبرازول') ||
        trade.contains('نيكسيوم') ||
        trade.contains('كونترولوك') ||
        trade.contains('إيزوميبرازول') ||
        trade.contains('يوثيروكس') ||
        trade.contains('euthyrox')) {
      return Ar.foodBefore;
    }

    // NSAIDs, Metformin, Steroids, Antibiotics (After food with meals)
    if (instr.contains('بعد الاكل') ||
        instr.contains('بعد الأكل') ||
        instr.contains('مع الاكل') ||
        instr.contains('مع الأكل') ||
        instr.contains('مع الطعام') ||
        generic.contains('ibuprofen') ||
        generic.contains('diclofenac') ||
        generic.contains('naproxen') ||
        generic.contains('metformin') ||
        generic.contains('amoxicillin') ||
        generic.contains('clavulan') ||
        trade.contains('بروفين') ||
        trade.contains('فولتارين') ||
        trade.contains('جلوكوفاج') ||
        trade.contains('كتافلام') ||
        trade.contains('رومافين') ||
        trade.contains('أوجمنتين') ||
        trade.contains('كلافودار')) {
      return Ar.foodAfter;
    }

    return 'بعد الأكل مع كوب ماء وفير';
  }

  /// Calculates max safe single dose (pills / ml / puffs) based on form, strength & active ingredient
  static SafeDoseLimit getMaxSafeSingleDose({
    required DrugInfo drug,
    required String selectedDosage,
    required MedicineForm form,
  }) {
    final dosageLower = selectedDosage.toLowerCase();
    final tradeLower = drug.tradeName.toLowerCase();
    final genericLower = drug.genericName.toLowerCase();

    // 1. Syrups / Liquids
    final isLiquid = form == MedicineForm.syrup ||
        dosageLower.contains('شراب') ||
        dosageLower.contains('ml') ||
        dosageLower.contains('مل/') ||
        (dosageLower.contains('مل') && !dosageLower.contains('ملغ'));

    if (isLiquid) {
      return const SafeDoseLimit(
        minDose: 2,
        defaultDose: 5,
        maxSafeDose: 15,
        step: 2,
        unit: 'مل',
        safetyNotice:
            'الحد الأقصى للجرعة الواحدة للشراب هو 15 مل لتفادي فرط الجرعة للأطفال والبالغين.',
      );
    }

    // 2. Drops
    if (form == MedicineForm.drops || dosageLower.contains('نقط')) {
      return const SafeDoseLimit(
        minDose: 1,
        defaultDose: 5,
        maxSafeDose: 20,
        step: 1,
        unit: 'نقطة',
        safetyNotice: 'الحد الأقصى للجرعة الواحدة هو 20 نقطة.',
      );
    }

    // 3. Inhalers
    if (form == MedicineForm.inhaler || dosageLower.contains('بخاخ')) {
      return const SafeDoseLimit(
        minDose: 1,
        defaultDose: 1,
        maxSafeDose: 2,
        step: 1,
        unit: 'بخة',
        safetyNotice:
            'الحد الأقصى للجرعة الواحدة هو بختان لتفادي تسارع ضربات القلب.',
      );
    }

    // 4. Injections
    if (form == MedicineForm.injection || dosageLower.contains('حقن')) {
      return const SafeDoseLimit(
        minDose: 1,
        defaultDose: 1,
        maxSafeDose: 1,
        step: 1,
        unit: 'حقنة',
        safetyNotice: 'الجرعة الواحدة مقيدة بحقنة واحدة فقط وفق الوصفة الطبية.',
      );
    }

    // 5. Tablets / Capsules (Default)
    final unit = form == MedicineForm.capsule ? 'كبسولة' : 'حبة';

    // Paracetamol 500mg: safe max is 2 tablets (1000mg)
    final isParacetamol =
        genericLower.contains('paracetamol') ||
        tradeLower.contains('بنادول') ||
        tradeLower.contains('بانادول') ||
        tradeLower.contains('بايمول') ||
        tradeLower.contains('ريفانين') ||
        tradeLower.contains('باندريكس') ||
        tradeLower.contains('أدول') ||
        tradeLower.contains('panadol') ||
        tradeLower.contains('adramol');

    final is1000mgOrExtended =
        dosageLower.contains('1000') ||
        dosageLower.contains('1 جم') ||
        dosageLower.contains('1g') ||
        dosageLower.contains('665') || // Joint 665mg
        dosageLower.contains('جوينت') ||
        dosageLower.contains('ممتد');

    if (isParacetamol && !is1000mgOrExtended) {
      return SafeDoseLimit(
        minDose: 1,
        defaultDose: 1,
        maxSafeDose: 2,
        step: 1,
        unit: unit,
        safetyNotice:
            'الحد الأقصى للباراسيتامول 500 ملغ هو حبتان (1000 ملغ) في الجرعة الواحدة لمنع التسمم الكبدي.',
      );
    }

    // For all high-dose drugs, NSAIDs, Antibiotics, Chronic Heart/BP/Diabetes/Thyroid meds -> strictly 1 tablet max!
    String reason =
        'قرص واحد فقط في الجرعة الواحدة حرصاً على سلامتك الدوائية وتجنب المضاعفات.';
    if (genericLower.contains('ibuprofen') ||
        genericLower.contains('diclofenac') ||
        genericLower.contains('naproxen')) {
      reason =
          'مسكنات الالتهاب مقيدة بقرص واحد فقط بالجرعة لتفادي تقرحات ونزيف المعدة والإضرار بالكلى.';
    } else if (genericLower.contains('amoxicillin') ||
        genericLower.contains('clavulan') ||
        genericLower.contains('cipro')) {
      reason = 'المضادات الحيوية مقيدة بقرص واحد فقط بالجرعة وفق التركيز المصرح.';
    } else if (drug.category.contains('ضغط') ||
        drug.category.contains('سكر') ||
        drug.category.contains('قلب')) {
      reason =
          'أدوية الأمراض المزمنة مقيدة بقرص واحد فقط بالجرعة لتفادي هبوط الضغط أو السكر الحاد.';
    }

    return SafeDoseLimit(
      minDose: 1,
      defaultDose: 1,
      maxSafeDose: 1,
      step: 1,
      unit: unit,
      safetyNotice: 'الحد الأقصى الآمن للجرعة الواحدة هو $reason',
    );
  }

  /// Safe frequency options for scheduled treatments
  static List<SafeFrequencyOption> getSafeFrequencies(DrugInfo drug) {
    final interval = drug.defaultIntervalHours;

    if (interval >= 24) {
      return const [
        SafeFrequencyOption(
          dosesPerDay: 1,
          intervalHours: 24,
          label: 'مرة واحدة يومياً (كل 24 ساعة)',
        ),
      ];
    }

    if (interval >= 12) {
      return const [
        SafeFrequencyOption(
          dosesPerDay: 1,
          intervalHours: 24,
          label: 'مرة واحدة يومياً (كل 24 ساعة)',
        ),
        SafeFrequencyOption(
          dosesPerDay: 2,
          intervalHours: 12,
          label: 'مرتين يومياً (كل 12 ساعة)',
        ),
      ];
    }

    if (interval >= 8) {
      return const [
        SafeFrequencyOption(
          dosesPerDay: 1,
          intervalHours: 24,
          label: 'مرة واحدة يومياً (كل 24 ساعة)',
        ),
        SafeFrequencyOption(
          dosesPerDay: 2,
          intervalHours: 12,
          label: 'مرتين يومياً (كل 12 ساعة)',
        ),
        SafeFrequencyOption(
          dosesPerDay: 3,
          intervalHours: 8,
          label: '3 مرات يومياً (كل 8 ساعات)',
        ),
      ];
    }

    return const [
      SafeFrequencyOption(
        dosesPerDay: 1,
        intervalHours: 24,
        label: 'مرة واحدة يومياً (كل 24 ساعة)',
      ),
      SafeFrequencyOption(
        dosesPerDay: 2,
        intervalHours: 12,
        label: 'مرتين يومياً (كل 12 ساعة)',
      ),
      SafeFrequencyOption(
        dosesPerDay: 3,
        intervalHours: 8,
        label: '3 مرات يومياً (كل 8 ساعات)',
      ),
      SafeFrequencyOption(
        dosesPerDay: 4,
        intervalHours: 6,
        label: '4 مرات يومياً (كل 6 ساعات)',
      ),
    ];
  }

  /// Safe interval choices for painkillers
  static List<int> getSafePainkillerIntervals(DrugInfo drug) {
    final minBase = drug.defaultIntervalHours;
    if (minBase >= 12) {
      return [12, 24];
    }
    if (minBase >= 8) {
      return [8, 12];
    }
    if (minBase >= 6) {
      return [6, 8, 12];
    }
    return [4, 6, 8, 12];
  }
}

class SafeDoseLimit {
  final int minDose;
  final int defaultDose;
  final int maxSafeDose;
  final int step;
  final String unit;
  final String safetyNotice;

  const SafeDoseLimit({
    required this.minDose,
    required this.defaultDose,
    required this.maxSafeDose,
    required this.step,
    required this.unit,
    required this.safetyNotice,
  });
}

class SafeFrequencyOption {
  final int dosesPerDay;
  final int intervalHours;
  final String label;

  const SafeFrequencyOption({
    required this.dosesPerDay,
    required this.intervalHours,
    required this.label,
  });
}

/// موعد أخذ أول جرعة لتحديد الجدول الذكي وفترة الأمان
enum FirstDoseStatus {
  justNow, // ⚡ أخذتها الآن
  earlierToday, // 🕒 أخذتها اليوم في وقت سابق
  yesterday, // 📅 أخذتها بالأمس
  notYet, // ⏳ لم أتناولها بعد (سأبدأ لاحقاً)
}

class AddMedicineSheet extends StatefulWidget {
  final Medicine? initialMedicine;
  final DrugInfo? initialDrugInfo;
  final String? currentProfileId;
  final List<UserProfile>? profiles;
  final Function(Medicine medicine) onSave;
  final VoidCallback? onDelete;

  const AddMedicineSheet({
    super.key,
    this.initialMedicine,
    this.initialDrugInfo,
    this.currentProfileId,
    this.profiles,
    required this.onSave,
    this.onDelete,
  });

  @override
  State<AddMedicineSheet> createState() => _AddMedicineSheetState();
}

class _AddMedicineSheetState extends State<AddMedicineSheet> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _encyclopediaSearchController =
      TextEditingController();
  List<DrugInfo> _encyclopediaSuggestions = [];
  String _selectedCategoryFilter = Ar.allCategories;

  DrugInfo? _selectedDrugInfo;
  String _selectedDosage = '';
  MedicineType _type = MedicineType.treatment;
  MedicineForm _form = MedicineForm.pill;

  int _pillsPerDose = 1;
  int _totalPills = 30;
  int _lowStockThreshold = 5;
  String _foodRelationText = Ar.foodAfter;

  int _dosesPerDay = 2;
  int _intervalHours = 12;
  int _minSafeIntervalHours = 6;
  int _maxDailyDoses = 4;
  TimeOfDay _firstDoseTime = const TimeOfDay(hour: 8, minute: 0);
  DateTime _firstDoseTakenDateTime = DateTime.now();
  FirstDoseStatus _firstDoseStatus = FirstDoseStatus.justNow;
  List<TimeOfDay> _scheduledTimes = [];

  String _selectedProfileId = 'self';
  int _colorValue = 0xFF0D9488;
  bool _showAdvanced = false;

  @override
  void initState() {
    super.initState();
    final med = widget.initialMedicine;
    _selectedProfileId = med?.profileId ?? widget.currentProfileId ?? 'self';

    if (widget.initialDrugInfo != null) {
      _selectDrug(widget.initialDrugInfo!);
      _firstDoseStatus = FirstDoseStatus.justNow;
      _firstDoseTakenDateTime = DateTime.now();
      _firstDoseTime = TimeOfDay.fromDateTime(_firstDoseTakenDateTime);
    } else if (med != null) {
      // Find matching drug info from database
      final searchHits = DrugDatabase.search(med.name);
      if (searchHits.isNotEmpty) {
        _selectedDrugInfo = searchHits.first;
      } else {
        // Fallback reconstructed drug info
        _selectedDrugInfo = DrugInfo(
          id: med.id,
          tradeName: med.name,
          genericName: med.activeIngredient.isNotEmpty
              ? med.activeIngredient
              : med.name,
          company: 'معتمد رسمياً',
          category: med.isPainkiller ? 'مسكنات وخافضات حرارة' : 'علاج عام',
          type: med.type,
          defaultForm: med.form,
          uses: med.instructions,
          instructions: med.instructions,
          precautions: '',
          sideEffects: '',
          defaultIntervalHours: med.intervalHours,
        );
      }
      _selectedDosage = _selectedDrugInfo?.availableDosages.isNotEmpty == true
          ? _selectedDrugInfo!.availableDosages.first
          : '';
      _type = med.type;
      _form = med.form;
      _pillsPerDose = med.pillsPerDose;
      _totalPills = med.totalPills;
      _lowStockThreshold = med.lowStockThreshold;
      _foodRelationText = med.instructions.isNotEmpty
          ? med.instructions
          : ClinicalSafetyRule.getLockedFoodRelation(_selectedDrugInfo!);
      _minSafeIntervalHours = med.minSafeIntervalHours;
      _intervalHours = med.intervalHours;
      _maxDailyDoses = med.maxDailyDoses;
      _scheduledTimes = List.from(med.scheduledTimes);
      _firstDoseTime =
          med.firstDoseTime ??
          (med.scheduledTimes.isNotEmpty
              ? med.scheduledTimes.first
              : const TimeOfDay(hour: 8, minute: 0));
      _dosesPerDay = med.scheduledTimes.isNotEmpty
          ? med.scheduledTimes.length
          : (24 ~/ _intervalHours).clamp(1, 4);
      _colorValue = med.colorValue;

      if (med.lastTakenTime != null) {
        _firstDoseTakenDateTime = med.lastTakenTime!;
        final now = DateTime.now();
        final diffMins = now.difference(_firstDoseTakenDateTime).inMinutes;
        if (diffMins >= 0 && diffMins < 30) {
          _firstDoseStatus = FirstDoseStatus.justNow;
        } else if (AppDateUtils.isSameDay(_firstDoseTakenDateTime, now)) {
          _firstDoseStatus = FirstDoseStatus.earlierToday;
        } else if (AppDateUtils.isYesterday(_firstDoseTakenDateTime, now)) {
          _firstDoseStatus = FirstDoseStatus.yesterday;
        } else {
          _firstDoseStatus = FirstDoseStatus.earlierToday;
        }
        _firstDoseTime = TimeOfDay.fromDateTime(_firstDoseTakenDateTime);
      } else {
        _firstDoseStatus = FirstDoseStatus.notYet;
        _firstDoseTakenDateTime = DateTime.now();
      }
    } else {
      _firstDoseStatus = FirstDoseStatus.justNow;
      _firstDoseTakenDateTime = DateTime.now();
      _firstDoseTime = TimeOfDay.fromDateTime(_firstDoseTakenDateTime);
      _totalPills = 30;
      _pillsPerDose = 1;
      _lowStockThreshold = 5;
    }
  }

  @override
  void dispose() {
    _encyclopediaSearchController.dispose();
    super.dispose();
  }

  void _onSearchEncyclopedia(String query) {
    if (query.trim().isEmpty) {
      setState(() => _encyclopediaSuggestions = []);
      return;
    }
    final results = DrugDatabase.search(
      query,
      category: _selectedCategoryFilter != Ar.allCategories
          ? _selectedCategoryFilter
          : null,
    );
    setState(() {
      _encyclopediaSuggestions = results.take(6).toList();
    });
  }

  void _selectDrug(DrugInfo drug) {
    setState(() {
      _selectedDrugInfo = drug;
      _type = drug.type;
      _form = drug.defaultForm;
      _selectedDosage = drug.availableDosages.isNotEmpty
          ? drug.availableDosages.first
          : '';
      _foodRelationText = ClinicalSafetyRule.getLockedFoodRelation(drug);

      // Safe Dosing calculations
      final doseLimit = ClinicalSafetyRule.getMaxSafeSingleDose(
        drug: drug,
        selectedDosage: _selectedDosage,
        form: _form,
      );
      _pillsPerDose = doseLimit.defaultDose.clamp(
        doseLimit.minDose,
        doseLimit.maxSafeDose,
      );

      // Safe Schedule
      final safeFrequencies = ClinicalSafetyRule.getSafeFrequencies(drug);
      if (safeFrequencies.isNotEmpty) {
        final chosenFreq = safeFrequencies.firstWhere(
          (f) => f.intervalHours == drug.defaultIntervalHours,
          orElse: () => safeFrequencies.first,
        );
        _dosesPerDay = chosenFreq.dosesPerDay;
        _intervalHours = chosenFreq.intervalHours;
      } else {
        _dosesPerDay = (24 ~/ drug.defaultIntervalHours).clamp(1, 4);
        _intervalHours = drug.defaultIntervalHours;
      }

      _minSafeIntervalHours = drug.defaultIntervalHours;
      _colorValue = drug.isRare
          ? 0xFF8B5CF6
          : (drug.type == MedicineType.painkiller ? 0xFFEF4444 : 0xFF0D9488);

      _firstDoseStatus = FirstDoseStatus.justNow;
      _firstDoseTakenDateTime = DateTime.now();
      _firstDoseTime = TimeOfDay.fromDateTime(_firstDoseTakenDateTime);

      _recalculateTimes();
      _encyclopediaSuggestions = [];
      _encyclopediaSearchController.clear();
    });
  }

  void _onFirstDoseStatusChanged(FirstDoseStatus status) {
    setState(() {
      _firstDoseStatus = status;
      final now = DateTime.now();
      switch (status) {
        case FirstDoseStatus.justNow:
          _firstDoseTakenDateTime = now;
          _firstDoseTime = TimeOfDay.fromDateTime(_firstDoseTakenDateTime);
          _recalculateTimes();
          break;
        case FirstDoseStatus.earlierToday:
          _firstDoseTakenDateTime = DateTime(
            now.year,
            now.month,
            now.day,
            _firstDoseTime.hour,
            _firstDoseTime.minute,
          );
          _recalculateTimes();
          break;
        case FirstDoseStatus.yesterday:
          final yest = now.subtract(const Duration(days: 1));
          _firstDoseTakenDateTime = DateTime(
            yest.year,
            yest.month,
            yest.day,
            _firstDoseTime.hour,
            _firstDoseTime.minute,
          );
          _recalculateTimes();
          break;
        case FirstDoseStatus.notYet:
          _recalculateTimes();
          break;
      }
    });
  }

  Future<void> _pickCustomFirstDoseTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _firstDoseTime,
    );
    if (picked != null) {
      setState(() {
        _firstDoseTime = picked;
        final now = DateTime.now();
        if (_firstDoseStatus == FirstDoseStatus.yesterday) {
          final yest = now.subtract(const Duration(days: 1));
          _firstDoseTakenDateTime = DateTime(
            yest.year,
            yest.month,
            yest.day,
            picked.hour,
            picked.minute,
          );
        } else if (_firstDoseStatus == FirstDoseStatus.notYet) {
          // Schedule anchor updated
        } else {
          if (_firstDoseStatus == FirstDoseStatus.justNow) {
            _firstDoseStatus = FirstDoseStatus.earlierToday;
          }
          _firstDoseTakenDateTime = DateTime(
            now.year,
            now.month,
            now.day,
            picked.hour,
            picked.minute,
          );
        }
        _recalculateTimes();
      });
    }
  }

  String _formatFirstDoseSummary(DateTime dt) {
    final now = DateTime.now();
    final timeStr = AppDateUtils.formatTime(dt);
    if (AppDateUtils.isSameDay(dt, now)) {
      return 'اليوم في $timeStr';
    } else if (AppDateUtils.isYesterday(dt, now)) {
      return 'أمس في $timeStr';
    } else {
      return '${AppDateUtils.formatShortDate(dt)} في $timeStr';
    }
  }

  String _formatNextDoseSummary(DateTime dt) {
    final now = DateTime.now();
    final timeStr = AppDateUtils.formatTime(dt);
    final diff = dt.difference(now);
    String relative = '';
    if (diff.isNegative) {
      relative = '(حان موعدها)';
    } else if (diff.inHours > 0) {
      final mins = diff.inMinutes % 60;
      relative = mins > 0
          ? '(بعد ${diff.inHours} س و $mins د)'
          : '(بعد ${diff.inHours} س)';
    } else {
      relative = '(بعد ${diff.inMinutes} د)';
    }

    if (AppDateUtils.isSameDay(dt, now)) {
      return 'اليوم في $timeStr $relative';
    } else if (AppDateUtils.isTomorrow(dt, now)) {
      return 'غداً في $timeStr $relative';
    } else {
      return '${AppDateUtils.formatShortDate(dt)} في $timeStr $relative';
    }
  }

  void _changeDosage(String dosage) {
    setState(() {
      _selectedDosage = dosage;
      if (_selectedDrugInfo != null) {
        if (dosage.contains('شراب') || dosage.contains('ml')) {
          _form = MedicineForm.syrup;
        } else if (dosage.contains('كبسول')) {
          _form = MedicineForm.capsule;
        } else if (dosage.contains('نقط')) {
          _form = MedicineForm.drops;
        } else if (dosage.contains('تحاميل')) {
          _form = MedicineForm.ointment;
        }

        final doseLimit = ClinicalSafetyRule.getMaxSafeSingleDose(
          drug: _selectedDrugInfo!,
          selectedDosage: _selectedDosage,
          form: _form,
        );
        _pillsPerDose = _pillsPerDose.clamp(
          doseLimit.minDose,
          doseLimit.maxSafeDose,
        );
      }
    });
  }

  void _recalculateTimes() {
    _scheduledTimes = Medicine.calculateScheduledTimes(
      firstDose: _firstDoseTime,
      dosesPerDay: _dosesPerDay,
      intervalHours: _intervalHours,
    );
  }

  void _adjustPillsPerDose(int delta) {
    if (_selectedDrugInfo == null) return;
    final doseLimit = ClinicalSafetyRule.getMaxSafeSingleDose(
      drug: _selectedDrugInfo!,
      selectedDosage: _selectedDosage,
      form: _form,
    );

    final nextVal = _pillsPerDose + (delta * doseLimit.step);
    final clamped = nextVal.clamp(doseLimit.minDose, doseLimit.maxSafeDose);

    setState(() {
      _pillsPerDose = clamped;
    });
  }

  void _adjustStock(int delta) {
    setState(() {
      _totalPills = (_totalPills + delta).clamp(0, 9999);
    });
  }

  void _scanBarcodeAndAutoFill() async {
    final result = await Navigator.push<BarcodeScanResult>(
      context,
      MaterialPageRoute(builder: (_) => const BarcodeScannerScreen()),
    );
    if (result != null) {
      if (result.drug != null) {
        _selectDrug(result.drug!);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'تم التعرف على ${result.drug!.tradeName} بنجاح من الموسوعة المعتمدة!',
              ),
              backgroundColor: const Color(0xFF10B981),
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'الباركود (${result.barcode}) غير مسجل في الموسوعة المعتمدة. يرجى اختيار الدواء بالاسم.',
              ),
              backgroundColor: const Color(0xFFD97706),
            ),
          );
        }
      }
    }
  }

  String _buildFullMedicineName() {
    if (_selectedDrugInfo == null) return '';
    if (_selectedDosage.trim().isEmpty) return _selectedDrugInfo!.tradeName;
    if (_selectedDrugInfo!.tradeName.contains(_selectedDosage)) {
      return _selectedDrugInfo!.tradeName;
    }
    return '${_selectedDrugInfo!.tradeName} ($_selectedDosage)';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isEditing = widget.initialMedicine != null;
    final categories = DrugDatabase.getCategories();

    final doseLimit = _selectedDrugInfo != null
        ? ClinicalSafetyRule.getMaxSafeSingleDose(
            drug: _selectedDrugInfo!,
            selectedDosage: _selectedDosage,
            form: _form,
          )
        : const SafeDoseLimit(
            minDose: 1,
            defaultDose: 1,
            maxSafeDose: 1,
            step: 1,
            unit: 'حبة',
            safetyNotice: '',
          );

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.92,
      ),
      padding: EdgeInsets.only(
        left: MediaQuery.of(context).size.width < 360 ? 12 : 20,
        right: MediaQuery.of(context).size.width < 360 ? 12 : 20,
        top: 14,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              // ─── Top Drag Handle ───
              Center(
                child: Container(
                  width: 44,
                  height: 4.5,
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.35),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // ─── Header: Title & Close ───
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: const Color(0xFF0D9488)
                                    .withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(
                                Icons.verified_user_rounded,
                                color: Color(0xFF0D9488),
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                isEditing
                                    ? Ar.editMedicineSheetTitle
                                    : Ar.addNewMedicineSheetTitle,
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 3),
                        Text(
                          Ar.addMedElderlySubtitle,
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? Colors.grey[400] : Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded, size: 24),
                    tooltip: Ar.close,
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // ═══════════════════════════════════════════════════════════
              // STEP 1: اختيار الدواء من الموسوعة المعتمدة (Strict Encyclopedia)
              // ═══════════════════════════════════════════════════════════
              if (_selectedDrugInfo == null) ...[
                _buildSectionHeader(
                  icon: Icons.menu_book_rounded,
                  title: Ar.step1SelectDrugTitle,
                  color: const Color(0xFF0D9488),
                ),
                const SizedBox(height: 10),

                // Quick Barcode Scan Banner
                InkWell(
                  onTap: _scanBarcodeAndAutoFill,
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: isDark
                            ? [
                                const Color(0xFF0F766E),
                                const Color(0xFF042F2E),
                              ]
                            : [
                                const Color(0xFF0D9488),
                                const Color(0xFF0F766E),
                              ],
                        begin: Alignment.topRight,
                        end: Alignment.bottomLeft,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF0D9488).withValues(alpha: 0.2),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.qr_code_scanner_rounded,
                            color: Colors.white,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                Ar.scanBarcodeBtn,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              Text(
                                Ar.scanBarcodeSubtitle,
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(
                          Icons.arrow_forward_ios_rounded,
                          color: Colors.white70,
                          size: 15,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Search Field
                TextField(
                  controller: _encyclopediaSearchController,
                  onChanged: _onSearchEncyclopedia,
                  style: const TextStyle(fontSize: 14.5),
                  decoration: InputDecoration(
                    labelText: 'ابحث بالاسم التجاري أو العلمي بالموسوعة *',
                    hintText: Ar.searchEncyclopediaHint,
                    prefixIcon: const Icon(
                      Icons.search_rounded,
                      color: Color(0xFF0D9488),
                    ),
                    suffixIcon: _encyclopediaSearchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded, size: 18),
                            onPressed: () {
                              _encyclopediaSearchController.clear();
                              setState(() => _encyclopediaSuggestions = []);
                            },
                          )
                        : null,
                    filled: true,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 14,
                    ),
                  ),
                ),
                const SizedBox(height: 8),

                // Category Filter Chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: categories.take(6).map((cat) {
                      final isSel = _selectedCategoryFilter == cat;
                      return Padding(
                        padding: const EdgeInsets.only(left: 6),
                        child: ChoiceChip(
                          label: Text(cat, style: const TextStyle(fontSize: 11)),
                          selected: isSel,
                          onSelected: (selected) {
                            setState(() {
                              _selectedCategoryFilter = cat;
                              _onSearchEncyclopedia(
                                _encyclopediaSearchController.text,
                              );
                            });
                          },
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 10),

                // Live Suggestions or Popular Drugs
                if (_encyclopediaSuggestions.isNotEmpty) ...[
                  Container(
                    decoration: BoxDecoration(
                      color: theme.cardColor,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: const Color(0xFF0D9488).withValues(alpha: 0.3),
                      ),
                    ),
                    child: ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _encyclopediaSuggestions.length,
                      separatorBuilder: (context, index) =>
                          Divider(height: 1, color: theme.dividerColor),
                      itemBuilder: (ctx, idx) {
                        final drug = _encyclopediaSuggestions[idx];
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: drug.type == MedicineType.painkiller
                                ? const Color(0xFFEF4444)
                                      .withValues(alpha: 0.12)
                                : const Color(0xFF0D9488)
                                      .withValues(alpha: 0.12),
                            child: Icon(
                              drug.type == MedicineType.painkiller
                                  ? Icons.healing_rounded
                                  : Icons.medication_rounded,
                              color: drug.type == MedicineType.painkiller
                                  ? const Color(0xFFEF4444)
                                  : const Color(0xFF0D9488),
                              size: 20,
                            ),
                          ),
                          title: Text(
                            drug.tradeName,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          subtitle: Text(
                            '${drug.genericName} • ${drug.category}',
                            style: TextStyle(
                              fontSize: 11.5,
                              color: isDark ? Colors.grey[400] : Colors.grey[600],
                            ),
                          ),
                          trailing: const Text(
                            Ar.tapToAutoFill,
                            style: TextStyle(
                              color: Color(0xFF0D9488),
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          onTap: () => _selectDrug(drug),
                        );
                      },
                    ),
                  ),
                ] else ...[
                  // Popular Drugs Fast Picks
                  const Text(
                    Ar.popularDrugsQuickSelect,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12.5,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: DrugDatabase.allDrugs.take(8).map((drug) {
                      return ActionChip(
                        avatar: Icon(
                          drug.type == MedicineType.painkiller
                              ? Icons.healing_rounded
                              : Icons.medication_rounded,
                          size: 16,
                          color: drug.type == MedicineType.painkiller
                              ? const Color(0xFFEF4444)
                              : const Color(0xFF0D9488),
                        ),
                        label: Text(
                          drug.tradeName,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        onPressed: () => _selectDrug(drug),
                      );
                    }).toList(),
                  ),
                ],

                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0D9488).withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: const Color(0xFF0D9488).withValues(alpha: 0.2),
                    ),
                  ),
                  child: const Row(
                    children: [
                      Icon(
                        Icons.shield_outlined,
                        color: Color(0xFF0D9488),
                        size: 20,
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          Ar.encyclopediaExclusiveNote,
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF0F766E),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ] else ...[
                // Selected Drug Hero Card (with Change button)
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF042F2E)
                        : const Color(0xFFF0FDFA),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: const Color(0xFF0D9488).withValues(alpha: 0.4),
                      width: 1.5,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0D9488)
                              .withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          _selectedDrugInfo!.type == MedicineType.painkiller
                              ? Icons.healing_rounded
                              : Icons.medication_rounded,
                          color: const Color(0xFF0D9488),
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _selectedDrugInfo!.tradeName,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${_selectedDrugInfo!.genericName} • ${_selectedDrugInfo!.company}',
                              style: TextStyle(
                                fontSize: 11.5,
                                color: isDark
                                    ? Colors.grey[300]
                                    : Colors.grey[700],
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (!isEditing)
                        IconButton(
                          onPressed: () {
                            setState(() => _selectedDrugInfo = null);
                          },
                          icon: const Icon(
                            Icons.sync_rounded,
                            size: 20,
                            color: Color(0xFF0D9488),
                          ),
                          tooltip: Ar.changeSelectedDrugBtn,
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),

                // ═══════════════════════════════════════════════════════════
                // STEP 2: البيانات الدوائية المقفلة (Auto-filled & Locked 🔒)
                // ═══════════════════════════════════════════════════════════
                _buildSectionHeader(
                  icon: Icons.lock_rounded,
                  title: Ar.step2LockedInfoTitle,
                  color: const Color(0xFF3B82F6),
                ),
                const SizedBox(height: 4),
                Text(
                  Ar.lockedAutoFilledNotice,
                  style: TextStyle(
                    fontSize: 11.5,
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 12),

                // 1. Field: Trade Name (Locked 🔒)
                _buildLockedField(
                  label: Ar.tradeNameField,
                  value: _buildFullMedicineName(),
                  icon: Icons.medication,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(height: 10),

                // 2. Field: Dosage / Strength Selection & Display (Locked 🔒)
                if (_selectedDrugInfo!.availableDosages.isNotEmpty) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF1E293B)
                          : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: theme.dividerColor.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.straighten_rounded,
                              size: 16,
                              color: Color(0xFF3B82F6),
                            ),
                            const SizedBox(width: 6),
                            const Expanded(
                              child: Text(
                                'اختر العيار والتركيز المتوفر لديك (معتمد من الموسوعة 🔒):',
                                style: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF3B82F6),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _selectedDrugInfo!.availableDosages.map((
                            dosage,
                          ) {
                            final isSel = _selectedDosage == dosage;
                            return ChoiceChip(
                              label: Text(
                                dosage,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: isSel
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                  color: isSel ? Colors.white : null,
                                ),
                              ),
                              selected: isSel,
                              selectedColor: const Color(0xFF3B82F6),
                              onSelected: (selected) {
                                if (selected) _changeDosage(dosage);
                              },
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                ],

                // 3. Field: Active Ingredient & Category (Locked 🔒)
                _buildLockedField(
                  label: Ar.activeIngredientField,
                  value:
                      '${_selectedDrugInfo!.genericName} • ${_selectedDrugInfo!.category}',
                  icon: Icons.science_outlined,
                  color: const Color(0xFF8B5CF6),
                ),
                const SizedBox(height: 10),

                // 4. Field: Medicine Type (Locked 🔒)
                _buildLockedField(
                  label: Ar.medicineTypeLockedTitle,
                  value: _type == MedicineType.painkiller
                      ? 'مسكن ألم وخافض حرارة (يؤخذ عند اللزوم بفاصل أمان صارم) 🔒'
                      : 'علاج منتظم ومجدول (يؤخذ بمواعيد يومية ثابتة) 🔒',
                  icon: _type == MedicineType.painkiller
                      ? Icons.healing_rounded
                      : Icons.calendar_today_rounded,
                  color: _type == MedicineType.painkiller
                      ? const Color(0xFFEF4444)
                      : const Color(0xFF0D9488),
                ),
                const SizedBox(height: 10),

                // 5. Field: Food Relation Timing (Locked 🔒)
                _buildLockedField(
                  label: Ar.foodTimingLockedTitle,
                  value: '$_foodRelationText (محدد تلقائياً وفق التوصيات الصيدلانية 🔒)',
                  icon: Icons.restaurant_rounded,
                  color: const Color(0xFF10B981),
                ),
                const SizedBox(height: 20),

                // ═══════════════════════════════════════════════════════════
                // STEP 3: الخطة العلاجية والجرعات الآمنة (Safe Dose & Schedule)
                // ═══════════════════════════════════════════════════════════
                _buildSectionHeader(
                  icon: Icons.health_and_safety_rounded,
                  title: Ar.step3SafeDoseScheduleTitle,
                  color: const Color(0xFFD97706),
                ),
                const SizedBox(height: 12),

                // A. Single Dose Quantity Stepper (Strictly Clamped)
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF1E293B)
                        : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: const Color(0xFFD97706).withValues(alpha: 0.3),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Expanded(
                            child: Text(
                              Ar.singleDoseStrictLimitTitle,
                              style: TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFD97706)
                                  .withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'الحد الأقصى: ${doseLimit.maxSafeDose} ${doseLimit.unit}',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFFD97706),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildStepperButton(
                            icon: Icons.remove,
                            enabled: _pillsPerDose > doseLimit.minDose,
                            onPressed: () => _adjustPillsPerDose(-1),
                          ),
                          const SizedBox(width: 12),
                          Flexible(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: theme.cardColor,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: const Color(0xFFD97706),
                                  width: 1.5,
                                ),
                              ),
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  '$_pillsPerDose ${doseLimit.unit}',
                                  style: const TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFFD97706),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          _buildStepperButton(
                            icon: Icons.add,
                            enabled: _pillsPerDose < doseLimit.maxSafeDose,
                            onPressed: () => _adjustPillsPerDose(1),
                          ),
                        ],
                      ),
                      if (doseLimit.safetyNotice.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(
                              Icons.info_outline,
                              size: 14,
                              color: Color(0xFFD97706),
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                doseLimit.safetyNotice,
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Color(0xFFD97706),
                                  height: 1.3,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // B. Safe Frequency or Safe Interval Choice Chips
                if (_type == MedicineType.treatment) ...[
                  const Text(
                    Ar.safeFrequencyTitle,
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: ClinicalSafetyRule.getSafeFrequencies(
                      _selectedDrugInfo!,
                    ).map((freq) {
                      final isSel =
                          _dosesPerDay == freq.dosesPerDay &&
                          _intervalHours == freq.intervalHours;
                      return ChoiceChip(
                        label: Text(freq.label),
                        selected: isSel,
                        selectedColor: const Color(0xFF8B5CF6),
                        onSelected: (val) {
                          if (val) {
                            setState(() {
                              _dosesPerDay = freq.dosesPerDay;
                              _intervalHours = freq.intervalHours;
                              _recalculateTimes();
                            });
                          }
                        },
                      );
                    }).toList(),
                  ),
                ] else ...[
                  const Text(
                    Ar.painkillerIntervalQuestion,
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: ClinicalSafetyRule.getSafePainkillerIntervals(
                      _selectedDrugInfo!,
                    ).map((hours) {
                      final isSel = _minSafeIntervalHours == hours;
                      return ChoiceChip(
                        label: Text('كل $hours ساعات'),
                        selected: isSel,
                        selectedColor: const Color(0xFFEF4444),
                        onSelected: (val) {
                          if (val) {
                            setState(() {
                              _minSafeIntervalHours = hours;
                              _intervalHours = hours;
                            });
                          }
                        },
                      );
                    }).toList(),
                  ),
                ],
                const SizedBox(height: 14),

                // C. First Dose Taken Selector Card (متى أخذت أول جرعة)
                _buildFirstDoseTimingCard(isDark: isDark, theme: theme),
                const SizedBox(height: 16),

                // C. Stock Counter (كم حبة متوفرة بالعلبة)
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: theme.cardColor,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: theme.dividerColor.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        Ar.stepStockTitle,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildStepperButton(
                            icon: Icons.remove,
                            enabled: _totalPills > 0,
                            onPressed: () => _adjustStock(-1),
                          ),
                          const SizedBox(width: 12),
                          Flexible(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? const Color(0xFF1E293B)
                                    : const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  '$_totalPills ${doseLimit.unit}',
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          _buildStepperButton(
                            icon: Icons.add,
                            enabled: true,
                            onPressed: () => _adjustStock(1),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Center(
                        child: Wrap(
                          alignment: WrapAlignment.center,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          spacing: 6,
                          runSpacing: 6,
                          children: [
                            const Text(
                              Ar.quickAddPills,
                              style: TextStyle(fontSize: 11.5, color: Colors.grey),
                            ),
                            ActionChip(
                              label: const Text('+10', style: TextStyle(fontSize: 11)),
                              onPressed: () => _adjustStock(10),
                            ),
                            ActionChip(
                              label: const Text('+20', style: TextStyle(fontSize: 11)),
                              onPressed: () => _adjustStock(20),
                            ),
                            ActionChip(
                              label: const Text('+30', style: TextStyle(fontSize: 11)),
                              onPressed: () => _adjustStock(30),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // Collapsible Advanced Settings (Low Stock & Profile)
                InkWell(
                  onTap: () => setState(() => _showAdvanced = !_showAdvanced),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              Icon(
                                _showAdvanced
                                    ? Icons.tune_rounded
                                    : Icons.expand_more_rounded,
                                size: 16,
                                color: Colors.grey[700],
                              ),
                              const SizedBox(width: 8),
                              const Expanded(
                                child: Text(
                                  Ar.advancedOptionsToggle,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          _showAdvanced
                              ? Icons.keyboard_arrow_up
                              : Icons.keyboard_arrow_down,
                          size: 18,
                          color: Colors.grey,
                        ),
                      ],
                    ),
                  ),
                ),

                if (_showAdvanced) ...[
                  const SizedBox(height: 10),
                  // Profiles if exist
                  if (widget.profiles != null && widget.profiles!.length > 1) ...[
                    DropdownButtonFormField<String>(
                      initialValue: _selectedProfileId,
                      decoration: const InputDecoration(
                        labelText: 'ملف الشخص (العائلة):',
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                      items: widget.profiles!.map((p) {
                        return DropdownMenuItem(
                          value: p.id,
                          child: Text('${p.name} (${p.relation})'),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => _selectedProfileId = val);
                      },
                    ),
                    const SizedBox(height: 10),
                  ],

                  // Low Stock Alert
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          Ar.lowStockAlertField,
                          style: TextStyle(fontSize: 12),
                        ),
                      ),
                      IconButton(
                        onPressed: () {
                          if (_lowStockThreshold > 1) {
                            setState(() => _lowStockThreshold--);
                          }
                        },
                        icon: const Icon(Icons.remove_circle_outline, size: 20),
                      ),
                      Text(
                        '$_lowStockThreshold',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      IconButton(
                        onPressed: () {
                          setState(() => _lowStockThreshold++);
                        },
                        icon: const Icon(Icons.add_circle_outline, size: 20),
                      ),
                    ],
                  ),
                ],
              ],

              const SizedBox(height: 22),

              // ═══════════════════════════════════════════════════════════
              // STEP 4: زر الحفظ والتفعيل الآمن (Save & Activate CTA)
              // ═══════════════════════════════════════════════════════════
              ElevatedButton.icon(
                onPressed: _selectedDrugInfo == null ? null : _saveMedicine,
                icon: const Icon(Icons.check_circle_outline, size: 22),
                label: Text(
                  _selectedDrugInfo == null
                      ? Ar.selectDrugRequired
                      : (isEditing ? Ar.updateMedicineBtn : Ar.saveMedicineBtn),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15.5,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: const Color(0xFF0D9488),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  disabledBackgroundColor: Colors.grey.withValues(alpha: 0.3),
                ),
              ),

              if (isEditing) ...[
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  onPressed: _confirmDeleteMedicine,
                  icon: const Icon(
                    Icons.delete_outline,
                    color: Colors.red,
                    size: 20,
                  ),
                  label: const Text(
                    Ar.deleteMedicineTitle,
                    style: TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                      fontSize: 14.5,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    side: const BorderSide(color: Colors.red, width: 1.2),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _saveMedicine() {
    if (_selectedDrugInfo == null) return;

    DateTime? lastTaken;
    DateTime? dynamicNext;
    String? rescheduleNote;

    if (_firstDoseStatus != FirstDoseStatus.notYet) {
      lastTaken = _firstDoseTakenDateTime;
      dynamicNext = _firstDoseTakenDateTime.add(
        Duration(hours: _intervalHours),
      );
      if (_type == MedicineType.treatment) {
        rescheduleNote =
            'تم تحديد جدول الجرعات بناءً على موعد أول جرعة تم أخذها (${AppDateUtils.formatTimeOfDay(TimeOfDay.fromDateTime(_firstDoseTakenDateTime))})';
      } else {
        rescheduleNote = 'سيبدأ فاصل الأمان الدوائي من وقت أول جرعة';
      }
    } else {
      lastTaken = null;
      dynamicNext = null;
      rescheduleNote = null;
    }

    final medicine = Medicine(
      id: widget.initialMedicine?.id ??
          'med_${DateTime.now().millisecondsSinceEpoch}',
      name: _buildFullMedicineName(),
      type: _type,
      form: _form,
      totalPills: _totalPills,
      pillsPerDose: _pillsPerDose,
      lowStockThreshold: _lowStockThreshold,
      instructions: _foodRelationText,
      scheduledTimes: _scheduledTimes,
      firstDoseTime: _firstDoseTime,
      lastTakenTime: lastTaken,
      dynamicNextDoseTime: dynamicNext,
      dynamicRescheduleNote: rescheduleNote,
      minSafeIntervalHours: _minSafeIntervalHours,
      intervalHours: _intervalHours,
      maxDailyDoses: _maxDailyDoses,
      colorValue: _colorValue,
      profileId: _selectedProfileId,
      activeIngredient: _selectedDrugInfo!.genericName,
    );

    widget.onSave(medicine);
    Navigator.pop(context);
  }

  Widget _buildFirstDoseTimingCard({
    required bool isDark,
    required ThemeData theme,
  }) {
    final accentColor = _type == MedicineType.painkiller
        ? const Color(0xFFEF4444)
        : const Color(0xFF8B5CF6);

    final isTaken = _firstDoseStatus != FirstDoseStatus.notYet;
    final nextDoseTime = _firstDoseTakenDateTime.add(
      Duration(hours: _intervalHours),
    );

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark
            ? (accentColor == const Color(0xFFEF4444)
                ? const Color(0xFF3B1212)
                : const Color(0xFF1E1B4B))
            : (accentColor == const Color(0xFFEF4444)
                ? const Color(0xFFFEF2F2)
                : const Color(0xFFF5F3FF)),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: accentColor.withValues(alpha: 0.35),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.access_time_filled_rounded,
                  color: accentColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      Ar.whenDidYouTakeFirstDoseTitle,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14.5,
                        color: isDark ? Colors.white : accentColor,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      Ar.whenDidYouTakeFirstDoseSubtitle,
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark ? Colors.grey[300] : Colors.grey[700],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // 4 Preset Choice Chips
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ChoiceChip(
                label: const Text(
                  Ar.firstDoseJustNow,
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                ),
                selected: _firstDoseStatus == FirstDoseStatus.justNow,
                selectedColor: accentColor,
                labelStyle: TextStyle(
                  color: _firstDoseStatus == FirstDoseStatus.justNow
                      ? Colors.white
                      : null,
                ),
                onSelected: (val) {
                  if (val) _onFirstDoseStatusChanged(FirstDoseStatus.justNow);
                },
              ),
              ChoiceChip(
                label: const Text(
                  Ar.firstDoseToday,
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                ),
                selected: _firstDoseStatus == FirstDoseStatus.earlierToday,
                selectedColor: accentColor,
                labelStyle: TextStyle(
                  color: _firstDoseStatus == FirstDoseStatus.earlierToday
                      ? Colors.white
                      : null,
                ),
                onSelected: (val) {
                  if (val) {
                    _onFirstDoseStatusChanged(FirstDoseStatus.earlierToday);
                  }
                },
              ),
              ChoiceChip(
                label: const Text(
                  Ar.firstDoseYesterday,
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                ),
                selected: _firstDoseStatus == FirstDoseStatus.yesterday,
                selectedColor: accentColor,
                labelStyle: TextStyle(
                  color: _firstDoseStatus == FirstDoseStatus.yesterday
                      ? Colors.white
                      : null,
                ),
                onSelected: (val) {
                  if (val) {
                    _onFirstDoseStatusChanged(FirstDoseStatus.yesterday);
                  }
                },
              ),
              ChoiceChip(
                label: const Text(
                  Ar.firstDoseNotYet,
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                ),
                selected: _firstDoseStatus == FirstDoseStatus.notYet,
                selectedColor: accentColor,
                labelStyle: TextStyle(
                  color: _firstDoseStatus == FirstDoseStatus.notYet
                      ? Colors.white
                      : null,
                ),
                onSelected: (val) {
                  if (val) _onFirstDoseStatusChanged(FirstDoseStatus.notYet);
                },
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Detail Display & Time Picker Button
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: accentColor.withValues(alpha: 0.25),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  isTaken
                      ? Icons.check_circle_rounded
                      : Icons.hourglass_top_rounded,
                  color: isTaken ? const Color(0xFF10B981) : Colors.amber,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isTaken
                            ? 'الوقت المسجل للجرعة الأولى:'
                            : 'موعد البدء المحدد:',
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark ? Colors.grey[400] : Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        isTaken
                            ? _formatFirstDoseSummary(_firstDoseTakenDateTime)
                            : 'سيبدأ عند ${AppDateUtils.formatTimeOfDay(_firstDoseTime)}',
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.bold,
                          color: accentColor,
                        ),
                      ),
                    ],
                  ),
                ),
                TextButton.icon(
                  onPressed: _pickCustomFirstDoseTime,
                  icon: const Icon(Icons.edit_calendar_rounded, size: 16),
                  label: const Text(
                    'تعديل ⏱️',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                  style: TextButton.styleFrom(
                    foregroundColor: accentColor,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // Dynamic Projection Banner
          if (isTaken) ...[
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFF0D9488).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFF0D9488).withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.auto_awesome_rounded,
                    color: Color(0xFF0D9488),
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _type == MedicineType.treatment
                              ? Ar.nextDoseProjectedTime
                              : 'موعد انتهاء فاصل الأمان (الجرعة القادمة):',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0D9488),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _formatNextDoseSummary(nextDoseTime),
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.bold,
                            color: isDark
                                ? Colors.white
                                : const Color(0xFF0F766E),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.blue.withValues(alpha: 0.25),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.info_outline_rounded,
                    color: Colors.blue,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _type == MedicineType.treatment
                          ? 'سيتم تذكيرك بالجرعة الأولى في الموعد المجدول المحدد أعلاه، ويبدأ الجدول تلقائياً.'
                          : 'يمكنك تناول أول جرعة عند الشعور بالألم، وسيبدأ حساب فاصل الأمان تلقائياً فور تسجيلها.',
                      style: TextStyle(
                        fontSize: 11.5,
                        color: isDark ? Colors.blue[200] : Colors.blue[900],
                        height: 1.3,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          // If Treatment: Show scheduled daily times chips
          if (_type == MedicineType.treatment &&
              _scheduledTimes.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Text(
              '🗓️ جدول مواعيد التذكير اليومية المحسوبة:',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: List.generate(_scheduledTimes.length, (index) {
                final time = _scheduledTimes[index];
                final formatted = AppDateUtils.formatTimeOfDay(time);
                return Chip(
                  backgroundColor: accentColor.withValues(alpha: 0.12),
                  side: BorderSide.none,
                  avatar: CircleAvatar(
                    backgroundColor: accentColor,
                    radius: 8,
                    child: Text(
                      '${index + 1}',
                      style: const TextStyle(
                        fontSize: 8.5,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  label: Text(
                    formatted,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 11.5,
                      color: accentColor,
                    ),
                  ),
                );
              }),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSectionHeader({
    required IconData icon,
    required String title,
    required Color color,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLockedField({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.grey.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.lock_rounded, size: 14, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildStepperButton({
    required IconData icon,
    required bool enabled,
    required VoidCallback onPressed,
  }) {
    return InkWell(
      onTap: enabled ? onPressed : null,
      borderRadius: BorderRadius.circular(30),
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: enabled
              ? const Color(0xFF0D9488).withValues(alpha: 0.15)
              : Colors.grey.withValues(alpha: 0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          color: enabled ? const Color(0xFF0D9488) : Colors.grey,
          size: 20,
        ),
      ),
    );
  }

  void _confirmDeleteMedicine() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(Ar.deleteMedicineTitle),
        content: Text(Ar.confirmDeletePrompt(widget.initialMedicine!.name)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(Ar.cancelBtn),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pop(context);
              widget.onDelete?.call();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text(Ar.confirmDeleteBtn),
          ),
        ],
      ),
    );
  }
}
