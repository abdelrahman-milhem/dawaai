import 'package:flutter/material.dart';

import '../ar.dart';
import '../models/medicine.dart';
import '../models/user_profile.dart';
import '../data/drug_database.dart';
import '../models/drug_info.dart';
import '../utils/date_utils.dart';
import '../screens/barcode_scanner_screen.dart';

class AddMedicineSheet extends StatefulWidget {
  final Medicine? initialMedicine;
  final String? currentProfileId;
  final List<UserProfile>? profiles;
  final Function(Medicine medicine) onSave;
  final VoidCallback? onDelete;

  const AddMedicineSheet({
    super.key,
    this.initialMedicine,
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
  DrugInfo? _selectedDrugInfo;

  late TextEditingController _nameController;
  late TextEditingController _totalPillsController;
  late TextEditingController _pillsPerDoseController;
  late TextEditingController _lowStockController;
  late TextEditingController _instructionsController;
  late TextEditingController _activeIngredientController;

  MedicineType _type = MedicineType.treatment;
  MedicineForm _form = MedicineForm.pill;
  int _minSafeIntervalHours = 6;
  int _intervalHours = 12;
  int _maxDailyDoses = 4;
  String _selectedProfileId = 'self';
  TimeOfDay _firstDoseTime = const TimeOfDay(hour: 8, minute: 0);
  int _dosesPerDay = 2; // كم مرة باليوم
  List<TimeOfDay> _scheduledTimes = [];
  int _colorValue = 0xFF0D9488;
  bool _showAdvanced = false;

  @override
  void initState() {
    super.initState();
    final med = widget.initialMedicine;
    _selectedProfileId = med?.profileId ?? widget.currentProfileId ?? 'self';
    if (med != null) {
      _nameController = TextEditingController(text: med.name);
      _totalPillsController = TextEditingController(text: '${med.totalPills}');
      _pillsPerDoseController = TextEditingController(
        text: '${med.pillsPerDose}',
      );
      _lowStockController = TextEditingController(
        text: '${med.lowStockThreshold}',
      );
      _instructionsController = TextEditingController(text: med.instructions);
      _activeIngredientController = TextEditingController(
        text: med.activeIngredient,
      );
      _type = med.type;
      _form = med.form;
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
    } else {
      _nameController = TextEditingController();
      _totalPillsController = TextEditingController(text: '30');
      _pillsPerDoseController = TextEditingController(text: '1');
      _lowStockController = TextEditingController(text: '5');
      _instructionsController = TextEditingController(text: Ar.foodAfter);
      _activeIngredientController = TextEditingController();
      _firstDoseTime = TimeOfDay.now();
      _dosesPerDay = 2;
      _intervalHours = 12;
      _colorValue = Medicine.getAutomaticColor('');
      _recalculateTimes();
    }

    _nameController.addListener(() {
      if (widget.initialMedicine == null) {
        final autoCol = Medicine.getAutomaticColor(_nameController.text);
        if (autoCol != _colorValue) {
          setState(() => _colorValue = autoCol);
        }
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

  @override
  void dispose() {
    _nameController.dispose();
    _totalPillsController.dispose();
    _pillsPerDoseController.dispose();
    _lowStockController.dispose();
    _instructionsController.dispose();
    _activeIngredientController.dispose();
    _encyclopediaSearchController.dispose();
    super.dispose();
  }

  void _onSearchEncyclopedia(String query) {
    if (query.trim().isEmpty) {
      setState(() => _encyclopediaSuggestions = []);
      return;
    }
    final results = DrugDatabase.search(query);
    setState(() {
      _encyclopediaSuggestions = results.take(4).toList();
    });
  }

  void _selectDrugSuggestion(DrugInfo drug) {
    setState(() {
      _nameController.text = drug.tradeName;
      _selectedDrugInfo = drug;
      _activeIngredientController.text = drug.genericName;
      _type = drug.type;
      _form = drug.defaultForm;
      _instructionsController.text =
          drug.instructions.contains(Ar.keywordBefore)
          ? Ar.foodBefore
          : Ar.foodAfter;
      _intervalHours = drug.defaultIntervalHours;
      _minSafeIntervalHours = drug.defaultIntervalHours;
      _colorValue = drug.isRare
          ? 0xFF8B5CF6
          : (drug.type == MedicineType.painkiller ? 0xFFEF4444 : 0xFF0D9488);
      _encyclopediaSuggestions = [];
      _encyclopediaSearchController.clear();
    });
  }

  void _scanBarcodeAndAutoFill() async {
    final result = await Navigator.push<BarcodeScanResult>(
      context,
      MaterialPageRoute(builder: (_) => const BarcodeScannerScreen()),
    );
    if (result != null) {
      if (result.drug != null) {
        _selectDrugSuggestion(result.drug!);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'تم التعرف على ${result.drug!.tradeName} بنجاح من الباركود!',
              ),
              backgroundColor: const Color(0xFF10B981),
            ),
          );
        }
      } else {
        if (_nameController.text.trim().isEmpty) {
          setState(() {
            _nameController.text = 'دواء جديد (${result.barcode})';
          });
        }
      }
    }
  }




  void _adjustPills(int delta) {
    final current = int.tryParse(_totalPillsController.text) ?? 30;
    final updated = (current + delta).clamp(0, 9999);
    setState(() {
      _totalPillsController.text = '$updated';
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isEditing = widget.initialMedicine != null;

    return Container(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
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
              // Top Drag Handle
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // Title & Close Button
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isEditing
                              ? Ar.editMedicineSheetTitle
                              : Ar.addNewMedicineSheetTitle,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          Ar.addMedElderlySubtitle,
                          style: TextStyle(fontSize: 12.5, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, size: 24),
                    tooltip: Ar.close,
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // ─── Quick Barcode Scan Banner ───
              if (!isEditing) ...[
                InkWell(
                  onTap: _scanBarcodeAndAutoFill,
                  borderRadius: BorderRadius.circular(18),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: isDark
                            ? [const Color(0xFF0F766E), const Color(0xFF042F2E)]
                            : [
                                const Color(0xFF0D9488),
                                const Color(0xFF0F766E),
                              ],
                        begin: Alignment.topRight,
                        end: Alignment.bottomLeft,
                      ),
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF0D9488)
                              .withValues(alpha: 0.25),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.qr_code_scanner_rounded,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 14),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    Ar.scanBarcodeBtn,
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                    ),
                                  ),
                                  SizedBox(width: 6),
                                  Icon(
                                    Icons.bolt_rounded,
                                    color: Colors.amber,
                                    size: 18,
                                  ),
                                ],
                              ),
                              SizedBox(height: 2),
                              Text(
                                Ar.scanBarcodeSubtitle,
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 11.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(
                          Icons.arrow_forward_ios_rounded,
                          color: Colors.white70,
                          size: 16,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 14),
              ],

              // Encyclopedia Assistant (Optional)
              if (!isEditing) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: theme.colorScheme.primary.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.search_rounded,
                            size: 20,
                            color: theme.colorScheme.primary,
                          ),
                          const SizedBox(width: 8),
                          const Flexible(
                            child: Text(
                              Ar.searchEncyclopediaOptional,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _encyclopediaSearchController,
                        onChanged: _onSearchEncyclopedia,
                        style: const TextStyle(fontSize: 14),
                        decoration: InputDecoration(
                          hintText: Ar.searchEncyclopediaHint,
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
                          ),
                          suffixIcon:
                              _encyclopediaSearchController.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear, size: 18),
                                  onPressed: () {
                                    _encyclopediaSearchController.clear();
                                    setState(
                                      () => _encyclopediaSuggestions = [],
                                    );
                                  },
                                )
                              : null,
                        ),
                      ),
                      if (_encyclopediaSuggestions.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        ..._encyclopediaSuggestions.map(
                          (drug) => ListTile(
                            dense: true,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 4,
                            ),
                            leading: const Icon(
                              Icons.auto_fix_high,
                              color: Color(0xFF0D9488),
                              size: 20,
                            ),
                            title: Text(
                              drug.tradeName,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            subtitle: Text(
                              '${drug.genericName} • ${drug.company}',
                              style: const TextStyle(fontSize: 11),
                            ),
                            trailing: const Text(
                              Ar.tapToAutoFill,
                              style: TextStyle(
                                color: Color(0xFF0D9488),
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            onTap: () => _selectDrugSuggestion(drug),
                          ),
                        ),
                      ],
                      const SizedBox(height: 4),
                      const Text(
                        Ar.customAddFreedomNote,
                        style: TextStyle(fontSize: 11, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // STEP 1: Medicine Name & Dose
              _buildSectionHeader(
                icon: Icons.edit_note_rounded,
                title: Ar.step1NameTitle,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _nameController,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
                decoration: InputDecoration(
                  labelText: Ar.medicineNameField,
                  hintText: Ar.medicineNameHintElderly,
                  prefixIcon: const Icon(Icons.medication, size: 24),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                ),
                validator: (val) => val == null || val.trim().isEmpty
                    ? Ar.medicineNameError
                    : null,
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Color(_colorValue).withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Color(_colorValue).withValues(alpha: 0.25),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 18,
                      height: 18,
                      decoration: BoxDecoration(
                        color: Color(_colorValue),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Color(_colorValue).withValues(alpha: 0.4),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        Ar.autoColorSelected,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Color(_colorValue),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              if (_selectedDrugInfo != null &&
                  _selectedDrugInfo!.availableDosages.isNotEmpty) ...[
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: theme.colorScheme.primary.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.straighten_rounded,
                            size: 16,
                            color: theme.colorScheme.primary,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              Ar.availableDosagesTitle,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        Ar.availableDosagesSubtitle,
                        style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _selectedDrugInfo!.availableDosages.map((
                          dosage,
                        ) {
                          final isSelected = _nameController.text.contains(
                            dosage,
                          );
                          return ChoiceChip(
                            label: Text(
                              dosage,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: isSelected ? Colors.white : null,
                              ),
                            ),
                            selected: isSelected,
                            selectedColor: theme.colorScheme.primary,
                            onSelected: (selected) {
                              setState(() {
                                String base = _selectedDrugInfo!.tradeName;
                                if (base.contains('(')) {
                                  base = base.split('(').first.trim();
                                }
                                _nameController.text = ' ()';
                              });
                            },
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 20),

              // STEP 2: Medicine Type
              _buildSectionHeader(
                icon: Icons.category_rounded,
                title: Ar.step2TypeTitle,
                color: const Color(0xFF3B82F6),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _buildTypeCard(
                      isSelected: _type == MedicineType.treatment,
                      icon: Icons.calendar_today_rounded,
                      title: Ar.treatmentTypeCardTitle,
                      subtitle: Ar.treatmentTypeCardDesc,
                      activeColor: const Color(0xFF0D9488),
                      onTap: () {
                        setState(() {
                          _type = MedicineType.treatment;
                          _colorValue = 0xFF0D9488;
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildTypeCard(
                      isSelected: _type == MedicineType.painkiller,
                      icon: Icons.healing_rounded,
                      title: Ar.painkillerTypeCardTitle,
                      subtitle: Ar.painkillerTypeCardDesc,
                      activeColor: const Color(0xFFEF4444),
                      onTap: () {
                        setState(() {
                          _type = MedicineType.painkiller;
                          _colorValue = 0xFFEF4444;
                        });
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // STEP 3: Stock Count (كم حبة عندك بالعلبة)
              _buildSectionHeader(
                icon: Icons.inventory_2_outlined,
                title: Ar.step3StockTitle,
                color: const Color(0xFFD97706),
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF0F172A)
                      : const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: theme.dividerColor.withValues(alpha: 0.3),
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildCounterButton(
                          icon: Icons.remove,
                          onPressed: () => _adjustPills(-1),
                        ),
                        const SizedBox(width: 16),
                        SizedBox(
                          width: 100,
                          child: TextFormField(
                            controller: _totalPillsController,
                            keyboardType: TextInputType.number,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                            ),
                            decoration: InputDecoration(
                              suffixText: Ar.unitPill,
                              contentPadding: const EdgeInsets.symmetric(
                                vertical: 8,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        _buildCounterButton(
                          icon: Icons.add,
                          onPressed: () => _adjustPills(1),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          Ar.quickAddPills,
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                        const SizedBox(width: 8),
                        ActionChip(
                          label: const Text('+10'),
                          onPressed: () => _adjustPills(10),
                        ),
                        const SizedBox(width: 6),
                        ActionChip(
                          label: const Text('+20'),
                          onPressed: () => _adjustPills(20),
                        ),
                        const SizedBox(width: 6),
                        ActionChip(
                          label: const Text('+30'),
                          onPressed: () => _adjustPills(30),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // STEP 4: Timings
              _buildSectionHeader(
                icon: Icons.schedule_rounded,
                title: Ar.step4TimingTitle,
                color: const Color(0xFF8B5CF6),
              ),
              const SizedBox(height: 10),

              if (_type == MedicineType.treatment) ...[
                // Frequency Chips
                const Text(
                  Ar.doseFrequencyTitle,
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    ChoiceChip(
                      label: const Text(Ar.freqOnceDaily),
                      selected: _dosesPerDay == 1,
                      onSelected: (val) {
                        if (val) {
                          _dosesPerDay = 1;
                          _intervalHours = 24;
                          _recalculateTimes();
                        }
                      },
                    ),
                    ChoiceChip(
                      label: const Text(Ar.freqTwiceDaily),
                      selected: _dosesPerDay == 2,
                      onSelected: (val) {
                        if (val) {
                          _dosesPerDay = 2;
                          _intervalHours = 12;
                          _recalculateTimes();
                        }
                      },
                    ),
                    ChoiceChip(
                      label: const Text(Ar.freqThreeTimes),
                      selected: _dosesPerDay == 3,
                      onSelected: (val) {
                        if (val) {
                          _dosesPerDay = 3;
                          _intervalHours = 8;
                          _recalculateTimes();
                        }
                      },
                    ),
                    ChoiceChip(
                      label: const Text(Ar.freqFourTimes),
                      selected: _dosesPerDay == 4,
                      onSelected: (val) {
                        if (val) {
                          _dosesPerDay = 4;
                          _intervalHours = 6;
                          _recalculateTimes();
                        }
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // First dose time taken (نقطة البداية)
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF1E1B4B)
                        : const Color(0xFFF5F3FF),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: const Color(0xFF8B5CF6).withValues(alpha: 0.3),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.play_circle_outline_rounded,
                            color: Color(0xFF8B5CF6),
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          const Expanded(
                            child: Text(
                              Ar.firstDoseAnchorTitle,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13.5,
                                color: Color(0xFF6D28D9),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        Ar.firstDoseAnchorDesc,
                        style: TextStyle(
                          fontSize: 11.5,
                          color: isDark ? Colors.grey[300] : Colors.grey[700],
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: theme.cardColor,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: const Color(0xFF8B5CF6)
                                    .withValues(alpha: 0.4),
                              ),
                            ),
                            child: Text(
                              AppDateUtils.formatTimeOfDay(_firstDoseTime),
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF6D28D9),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Wrap(
                              spacing: 8,
                              runSpacing: 6,
                              children: [
                                OutlinedButton.icon(
                                  onPressed: () {
                                    setState(() {
                                      _firstDoseTime = TimeOfDay.now();
                                      _recalculateTimes();
                                    });
                                  },
                                  icon: const Icon(
                                    Icons.bolt,
                                    size: 16,
                                    color: Color(0xFF8B5CF6),
                                  ),
                                  label: const Text(
                                    Ar.tookItNowBtn,
                                    style: TextStyle(fontSize: 12),
                                  ),
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 6,
                                    ),
                                  ),
                                ),
                                OutlinedButton.icon(
                                  onPressed: () async {
                                    final picked = await showTimePicker(
                                      context: context,
                                      initialTime: _firstDoseTime,
                                    );
                                    if (picked != null) {
                                      setState(() {
                                        _firstDoseTime = picked;
                                        _recalculateTimes();
                                      });
                                    }
                                  },
                                  icon: const Icon(Icons.access_time, size: 16),
                                  label: const Text(
                                    Ar.changeFirstDoseTime,
                                    style: TextStyle(fontSize: 12),
                                  ),
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 6,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // Auto calculated schedule display
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.cardColor,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: theme.dividerColor.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            Ar.autoCalculatedTimesTitle,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              Ar.autoCalculatedTimesSubtitle(
                                _scheduledTimes.length,
                              ),
                              textAlign: TextAlign.end,
                              style: const TextStyle(
                                color: Colors.grey,
                                fontSize: 11,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        children: List.generate(_scheduledTimes.length, (
                          index,
                        ) {
                          final time = _scheduledTimes[index];
                          final formatted = AppDateUtils.formatTimeOfDay(time);
                          return Chip(
                            backgroundColor: const Color(0xFF8B5CF6)
                                .withValues(alpha: 0.12),
                            side: BorderSide.none,
                            avatar: CircleAvatar(
                              backgroundColor: const Color(0xFF8B5CF6),
                              radius: 10,
                              child: Text(
                                '${index + 1}',
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            label: Text(
                              formatted,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF6D28D9),
                              ),
                            ),
                          );
                        }),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        Ar.nextDoseCalculatedFromLast,
                        style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
              ] else ...[
                // Safe Interval for Painkiller
                Text(
                  Ar.painkillerIntervalQuestion,
                  style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _buildIntervalChip(4, Ar.safeInterval4Hours),
                    _buildIntervalChip(6, Ar.safeInterval6Hours),
                    _buildIntervalChip(8, Ar.safeInterval8Hours),
                    _buildIntervalChip(12, Ar.safeInterval12Hours),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${Ar.firstDoseAnchorTitle} ${AppDateUtils.formatTimeOfDay(_firstDoseTime)}',
                        style: const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    TextButton.icon(
                      onPressed: () {
                        setState(() => _firstDoseTime = TimeOfDay.now());
                      },
                      icon: const Icon(Icons.bolt, size: 16),
                      label: const Text(
                        Ar.tookItNowBtn,
                        style: TextStyle(fontSize: 11.5),
                      ),
                    ),
                  ],
                ),
              ],

              const SizedBox(height: 20),

              // STEP 5: Food instructions
              _buildSectionHeader(
                icon: Icons.restaurant_rounded,
                title: Ar.step5FoodTitle,
                color: const Color(0xFF10B981),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children:
                    [
                      Ar.foodAfter,
                      Ar.foodBefore,
                      Ar.foodWith,
                      Ar.foodBedtime,
                    ].map((instr) {
                      final isSelected = _instructionsController.text == instr;
                      return ChoiceChip(
                        label: Text(
                          instr,
                          style: TextStyle(
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                        selected: isSelected,
                        onSelected: (selected) {
                          if (selected) {
                            setState(
                              () => _instructionsController.text = instr,
                            );
                          }
                        },
                      );
                    }).toList(),
              ),
              const SizedBox(height: 18),

              // Collapsible Advanced Settings (Optional for elderly)
              InkWell(
                onTap: () => setState(() => _showAdvanced = !_showAdvanced),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(
                            _showAdvanced
                                ? Icons.tune_rounded
                                : Icons.expand_more_rounded,
                            size: 18,
                            color: Colors.grey[700],
                          ),
                          const SizedBox(width: 8),
                          Text(
                            Ar.advancedOptionsToggle,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                      Icon(
                        _showAdvanced
                            ? Icons.keyboard_arrow_up
                            : Icons.keyboard_arrow_down,
                        color: Colors.grey,
                      ),
                    ],
                  ),
                ),
              ),

              if (_showAdvanced) ...[
                const SizedBox(height: 14),
                // Form dropdown
                DropdownButtonFormField<MedicineForm>(
                  initialValue: _form,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: Ar.medicineShapeField,
                    prefixIcon: Icon(Icons.grain),
                  ),
                  items: [
                    const DropdownMenuItem(
                      value: MedicineForm.pill,
                      child: Text(Ar.formPill),
                    ),
                    const DropdownMenuItem(
                      value: MedicineForm.capsule,
                      child: Text(Ar.formCapsule),
                    ),
                    const DropdownMenuItem(
                      value: MedicineForm.syrup,
                      child: Text(Ar.formSyrup),
                    ),
                    const DropdownMenuItem(
                      value: MedicineForm.injection,
                      child: Text(Ar.formInjection),
                    ),
                    const DropdownMenuItem(
                      value: MedicineForm.drops,
                      child: Text(Ar.formDrops),
                    ),
                    const DropdownMenuItem(
                      value: MedicineForm.inhaler,
                      child: Text(Ar.formInhaler),
                    ),
                    const DropdownMenuItem(
                      value: MedicineForm.ointment,
                      child: Text(Ar.formOintment),
                    ),
                  ],
                  onChanged: (val) {
                    if (val != null) setState(() => _form = val);
                  },
                ),
                const SizedBox(height: 12),

                // Pills per dose & Low stock threshold
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _pillsPerDoseController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: Ar.pillsPerDoseField,
                          suffixText: Ar.unitPill,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _lowStockController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: Ar.lowStockAlertField,
                          suffixText: Ar.unitPills,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Active ingredient
                TextFormField(
                  controller: _activeIngredientController,
                  decoration: const InputDecoration(
                    labelText: Ar.activeIngredientField,
                    hintText: Ar.activeIngredientHint,
                    prefixIcon: Icon(Icons.science_outlined),
                  ),
                ),
                const SizedBox(height: 12),

                // Auto Color Info
                Row(
                  children: [
                    Container(
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        color: Color(_colorValue),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Color(_colorValue).withValues(alpha: 0.4),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        Ar.autoColorHint,
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ),
                  ],
                ),
              ],

              const SizedBox(height: 24),

              // Large, Prominent Save Button
              ElevatedButton.icon(
                onPressed: () {
                  if (_formKey.currentState?.validate() ?? false) {
                    final medicine = Medicine(
                      id:
                          widget.initialMedicine?.id ??
                          'med_${DateTime.now().millisecondsSinceEpoch}',
                      name: _nameController.text.trim(),
                      type: _type,
                      form: _form,
                      totalPills:
                          int.tryParse(_totalPillsController.text) ?? 30,
                      pillsPerDose:
                          int.tryParse(_pillsPerDoseController.text) ?? 1,
                      lowStockThreshold:
                          int.tryParse(_lowStockController.text) ?? 5,
                      instructions: _instructionsController.text.trim(),
                      scheduledTimes: _scheduledTimes,
                      firstDoseTime: _firstDoseTime,
                      minSafeIntervalHours: _minSafeIntervalHours,
                      intervalHours: _intervalHours,
                      maxDailyDoses: _maxDailyDoses,
                      colorValue: _colorValue,
                      profileId: _selectedProfileId,
                      activeIngredient: _activeIngredientController.text.trim(),
                    );
                    widget.onSave(medicine);
                    Navigator.pop(context);
                  }
                },
                icon: const Icon(Icons.check_circle_outline, size: 22),
                label: Text(
                  isEditing ? Ar.updateMedicineBtn : Ar.saveMedicineBtn,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 17,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: const Color(0xFF0D9488),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),

              if (isEditing) ...[
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: _confirmDeleteMedicine,
                  icon: const Icon(
                    Icons.delete_outline,
                    color: Colors.red,
                    size: 22,
                  ),
                  label: const Text(
                    Ar.deleteMedicineTitle,
                    style: TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    side: const BorderSide(color: Colors.red, width: 1.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
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
        Text(
          title,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildTypeCard({
    required bool isSelected,
    required IconData icon,
    required String title,
    required String subtitle,
    required Color activeColor,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? activeColor.withValues(alpha: 0.12)
              : theme.cardColor,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isSelected
                ? activeColor
                : theme.dividerColor.withValues(alpha: 0.3),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, color: isSelected ? activeColor : Colors.grey, size: 28),
            const SizedBox(height: 6),
            Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: isSelected ? activeColor : null,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: const TextStyle(fontSize: 10.5, color: Colors.grey),
              textAlign: TextAlign.center,
              maxLines: 2,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCounterButton({
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(30),
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: const Color(0xFF0D9488).withValues(alpha: 0.12),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: const Color(0xFF0D9488), size: 22),
      ),
    );
  }


  Widget _buildIntervalChip(int hours, String label) {
    final isSelected = _minSafeIntervalHours == hours;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          setState(() {
            _minSafeIntervalHours = hours;
            _intervalHours = hours;
          });
        }
      },
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
