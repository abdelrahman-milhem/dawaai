import 'package:flutter/material.dart';

import '../ar.dart';
import '../data/drug_database.dart';
import '../models/drug_info.dart';
import '../models/medicine.dart';
import '../widgets/drug_detail_sheet.dart';
import '../widgets/pill_refresh_indicator.dart';
import 'barcode_scanner_screen.dart';

class DrugEncyclopediaScreen extends StatefulWidget {
  final Function(Medicine medicine) onAddMedicineDirectly;
  final VoidCallback onOpenCustomAdd;

  const DrugEncyclopediaScreen({
    super.key,
    required this.onAddMedicineDirectly,
    required this.onOpenCustomAdd,
  });

  @override
  State<DrugEncyclopediaScreen> createState() => _DrugEncyclopediaScreenState();
}

class _DrugEncyclopediaScreenState extends State<DrugEncyclopediaScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedCategory = Ar.allCategories;
  bool _onlyRare = false;
  List<DrugInfo> _results = DrugDatabase.allDrugs;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {
      _results = DrugDatabase.search(
        _searchController.text,
        category: _selectedCategory,
        onlyRare: _onlyRare ? true : null,
      );
    });
  }

  void _selectCategory(String cat) {
    setState(() {
      _selectedCategory = cat;
      _results = DrugDatabase.search(
        _searchController.text,
        category: _selectedCategory,
        onlyRare: _onlyRare ? true : null,
      );
    });
  }

  void _toggleRareOnly() {
    setState(() {
      _onlyRare = !_onlyRare;
      _results = DrugDatabase.search(
        _searchController.text,
        category: _selectedCategory,
        onlyRare: _onlyRare ? true : null,
      );
    });
  }

  void _showDrugDetails(DrugInfo drug) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => DrugDetailSheet(
        drug: drug,
        onAddToMyMedicines: (selectedDrug) {
          final newMed = Medicine(
            id: 'med_${DateTime.now().millisecondsSinceEpoch}',
            name: selectedDrug.tradeName,
            type: selectedDrug.type,
            form: selectedDrug.defaultForm,
            totalPills: 30,
            pillsPerDose: 1,
            lowStockThreshold: 5,
            instructions: selectedDrug.instructions,
            intervalHours: selectedDrug.defaultIntervalHours,
            minSafeIntervalHours: selectedDrug.defaultIntervalHours,
            activeIngredient: selectedDrug.genericName,
            colorValue: selectedDrug.isRare
                ? 0xFF8B5CF6
                : (selectedDrug.type == MedicineType.painkiller
                      ? 0xFFEF4444
                      : 0xFF0D9488),
          );
          widget.onAddMedicineDirectly(newMed);
        },
      ),
    );
  }

  void _scanBarcodeAndLookup() async {
    final result = await Navigator.push<BarcodeScanResult>(
      context,
      MaterialPageRoute(builder: (_) => const BarcodeScannerScreen()),
    );
    if (result != null) {
      if (result.drug != null) {
        _showDrugDetails(result.drug!);
      } else {
        setState(() {
          _searchController.text = result.barcode;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('الباركود المقروء: ${result.barcode}'),
              backgroundColor: const Color(0xFF0D9488),
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final categories = DrugDatabase.getCategories();

    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.menu_book_rounded, color: Color(0xFF0D9488)),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                Ar.encyclopediaTitle,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code_scanner_rounded),
            tooltip: Ar.scanBarcodeTooltip,
            onPressed: _scanBarcodeAndLookup,
          ),
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            tooltip: Ar.customAddTooltip,
            onPressed: widget.onOpenCustomAdd,
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Input Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            color: theme.appBarTheme.backgroundColor,
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: Ar.searchDrugHintDetailed,
                    prefixIcon: const Icon(Icons.search_rounded),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                            },
                          )
                        : IconButton(
                            icon: const Icon(
                              Icons.qr_code_scanner_rounded,
                              color: Color(0xFF0D9488),
                            ),
                            tooltip: Ar.scanBarcodeTooltip,
                            onPressed: _scanBarcodeAndLookup,
                          ),
                    filled: true,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                ),
                const SizedBox(height: 8),

                // Category Chips & Rare Toggle
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      FilterChip(
                        label: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.auto_awesome,
                              size: 14,
                              color: Color(0xFF8B5CF6),
                            ),
                            SizedBox(width: 4),
                            Text(Ar.rareMedicinesFilter),
                          ],
                        ),
                        selected: _onlyRare,
                        selectedColor: const Color(0xFF8B5CF6)
                            .withValues(alpha: 0.2),
                        onSelected: (_) => _toggleRareOnly(),
                      ),
                      const SizedBox(width: 8),
                      ...categories.map((cat) {
                        final isSel = _selectedCategory == cat;
                        return Padding(
                          padding: const EdgeInsets.only(left: 6),
                          child: ChoiceChip(
                            label: Text(cat),
                            selected: isSel,
                            onSelected: (selected) {
                              if (selected) _selectCategory(cat);
                            },
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Custom Add Banner (User is NOT forced to choose from database)
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: theme.colorScheme.primary.withValues(alpha: 0.25),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.edit_note_rounded,
                  color: theme.colorScheme.primary,
                  size: 22,
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        Ar.customAddPromptTitle,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12.5,
                        ),
                      ),
                      Text(
                        Ar.customAddPromptDesc,
                        style: TextStyle(fontSize: 11, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: widget.onOpenCustomAdd,
                  child: const Text(
                    Ar.customAddBtnShort,
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),

          // Search Results Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  Ar.searchResultsCount(_results.length),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: Colors.grey,
                  ),
                ),
                if (_onlyRare)
                  const Text(
                    Ar.rareOnlyActiveFilter,
                    style: TextStyle(
                      fontSize: 11,
                      color: Color(0xFF8B5CF6),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
              ],
            ),
          ),

          // Drug Cards List
          Expanded(
            child: PillRefreshIndicator(
              onRefresh: () async {
                _onSearchChanged();
                await Future.delayed(const Duration(milliseconds: 400));
              },
              child: _results.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.medication_outlined,
                            size: 48,
                            color: Colors.grey,
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            Ar.noSearchResults,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            Ar.noSearchResultsDesc,
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 13, color: Colors.grey),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: widget.onOpenCustomAdd,
                            icon: const Icon(Icons.add),
                            label: const Text(Ar.addThisDrugManually),
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    itemCount: _results.length,
                    itemBuilder: (ctx, index) {
                      final drug = _results[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: InkWell(
                          onTap: () => _showDrugDetails(drug),
                          borderRadius: BorderRadius.circular(20),
                          child: Padding(
                            padding: const EdgeInsets.all(14),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: drug.isRare
                                            ? const Color(0xFF8B5CF6)
                                                  .withValues(alpha: 0.12)
                                            : (drug.type ==
                                                      MedicineType.painkiller
                                                  ? const Color(0xFFEF4444)
                                                        .withValues(alpha: 0.12)
                                                  : const Color(
                                                      0xFF0D9488,
                                                    ).withValues(alpha: 0.12)),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Icon(
                                        drug.isRare
                                            ? Icons.auto_awesome_rounded
                                            : (drug.type ==
                                                      MedicineType.painkiller
                                                  ? Icons.healing_rounded
                                                  : Icons.medication_rounded),
                                        color: drug.isRare
                                            ? const Color(0xFF8B5CF6)
                                            : (drug.type ==
                                                      MedicineType.painkiller
                                                  ? const Color(0xFFEF4444)
                                                  : const Color(0xFF0D9488)),
                                        size: 24,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  drug.tradeName,
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 15,
                                                  ),
                                                ),
                                              ),
                                              if (drug.isRare)
                                                Container(
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 6,
                                                        vertical: 2,
                                                      ),
                                                  decoration: BoxDecoration(
                                                    color: const Color(
                                                      0xFF8B5CF6,
                                                    ),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          6,
                                                        ),
                                                  ),
                                                  child: const Text(
                                                    Ar.rareBadge,
                                                    style: TextStyle(
                                                      color: Colors.white,
                                                      fontSize: 10,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                ),
                                            ],
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            Ar.scientificNameLabel(
                                              drug.genericName,
                                            ),
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: theme.colorScheme.primary,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            Ar.companyLabel(drug.company),
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: Colors.grey[600],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: isDark
                                        ? const Color(0xFF0F172A)
                                        : const Color(0xFFF8FAFC),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Icon(
                                        Icons.check_circle_outline,
                                        size: 14,
                                        color: Color(0xFF10B981),
                                      ),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: Text(
                                          Ar.indicationsLabel(drug.uses),
                                          style: const TextStyle(fontSize: 12),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (drug.availableDosages.isNotEmpty) ...[
                                  const SizedBox(height: 8),
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Padding(
                                        padding: EdgeInsets.only(top: 2),
                                        child: Icon(
                                          Icons.straighten_rounded,
                                          size: 13,
                                          color: Color(0xFF0D9488),
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      Expanded(
                                        child: Wrap(
                                          spacing: 6,
                                          runSpacing: 4,
                                          children: drug.availableDosages.map((
                                            dosage,
                                          ) {
                                            return Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 7,
                                                    vertical: 2,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: const Color(0xFF0D9488)
                                                    .withValues(alpha: 0.08),
                                                borderRadius:
                                                    BorderRadius.circular(6),
                                                border: Border.all(
                                                  color: const Color(0xFF0D9488)
                                                      .withValues(alpha: 0.2),
                                                ),
                                              ),
                                              child: Text(
                                                dosage,
                                                style: const TextStyle(
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.bold,
                                                  color: Color(0xFF0D9488),
                                                ),
                                              ),
                                            );
                                          }).toList(),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 3,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.grey.withValues(
                                          alpha: 0.12,
                                        ),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        drug.category,
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: Colors.grey[700],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Expanded(
                                      child: OutlinedButton(
                                        onPressed: () => _showDrugDetails(drug),
                                        style: OutlinedButton.styleFrom(
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 8,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              10,
                                            ),
                                          ),
                                        ),
                                        child: const Text(
                                          Ar.fullDetailsBtn,
                                          style: TextStyle(fontSize: 12),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    ElevatedButton.icon(
                                      onPressed: () {
                                        final newMed = Medicine(
                                          id: 'med_${DateTime.now().millisecondsSinceEpoch}',
                                          name: drug.tradeName,
                                          type: drug.type,
                                          form: drug.defaultForm,
                                          totalPills: 30,
                                          pillsPerDose: 1,
                                          lowStockThreshold: 5,
                                          instructions: drug.instructions,
                                          intervalHours:
                                              drug.defaultIntervalHours,
                                          minSafeIntervalHours:
                                              drug.defaultIntervalHours,
                                          activeIngredient: drug.genericName,
                                          colorValue: drug.isRare
                                              ? 0xFF8B5CF6
                                              : (drug.type ==
                                                        MedicineType.painkiller
                                                    ? 0xFFEF4444
                                                    : 0xFF0D9488),
                                        );
                                        widget.onAddMedicineDirectly(newMed);
                                      },
                                      icon: const Icon(
                                        Icons.add_rounded,
                                        size: 16,
                                      ),
                                      label: const Text(
                                        Ar.addToMySchedule,
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(
                                          0xFF0D9488,
                                        ),
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 8,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
