import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/medicine.dart';
import '../models/user_profile.dart';
import '../services/storage_service.dart';
import '../services/reminder_service.dart';
import '../widgets/add_medicine_sheet.dart';
import '../widgets/dose_log_sheet.dart';
import '../widgets/refill_dialog.dart';
import '../widgets/notification_banner.dart';
import '../widgets/doctor_report_sheet.dart';
import '../widgets/interaction_guide_sheet.dart';
import 'today_doses_tab.dart';
import 'painkillers_tab.dart';
import 'pharmacy_stock_tab.dart';
import 'history_tab.dart';
import 'drug_encyclopedia_screen.dart';
import 'barcode_scanner_screen.dart';
import '../ar.dart';

class HomeScreen extends StatefulWidget {
  final StorageService storageService;
  final ReminderService reminderService;
  final VoidCallback onToggleTheme;
  final bool isDarkMode;

  const HomeScreen({
    super.key,
    required this.storageService,
    required this.reminderService,
    required this.onToggleTheme,
    required this.isDarkMode,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    widget.reminderService.addListener(_onReminderUpdate);
    widget.storageService.addListener(_onReminderUpdate);
  }

  @override
  void dispose() {
    widget.reminderService.removeListener(_onReminderUpdate);
    widget.storageService.removeListener(_onReminderUpdate);
    super.dispose();
  }

  void _onReminderUpdate() {
    if (mounted) setState(() {});
  }

  void _openAddMedicineSheet([Medicine? existing]) {
    final activeId = widget.storageService.getActiveProfileId();
    final profiles = widget.storageService.getProfiles();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => AddMedicineSheet(
        initialMedicine: existing,
        currentProfileId: activeId,
        profiles: profiles,
        onSave: (med) async {
          if (existing != null) {
            await widget.storageService.updateMedicine(med);
          } else {
            await widget.storageService.addMedicine(med);
          }
          setState(() {});
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                existing != null
                    ? Ar.medicineUpdatedSuccess
                    : Ar.medicineAddedSuccess,
              ),
              backgroundColor: const Color(0xFF0D9488),
            ),
          );
        },
        onDelete: existing == null
            ? null
            : () async {
                await widget.storageService.deleteMedicine(existing.id);
                setState(() {});
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(Ar.medicineDeletedSuccess),
                    backgroundColor: Colors.red,
                  ),
                );
              },
      ),
    );
  }

  void _openBarcodeScanner() async {
    final result = await Navigator.push<BarcodeScanResult>(
      context,
      MaterialPageRoute(builder: (_) => const BarcodeScannerScreen()),
    );
    if (result != null) {
      if (result.drug != null) {
        final drug = result.drug!;
        final newMed = Medicine(
          id: 'med_${DateTime.now().millisecondsSinceEpoch}',
          name: drug.tradeName,
          type: drug.type,
          form: drug.defaultForm,
          totalPills: 30,
          pillsPerDose: 1,
          lowStockThreshold: 5,
          instructions: drug.instructions,
          intervalHours: drug.defaultIntervalHours,
          minSafeIntervalHours: drug.defaultIntervalHours,
          activeIngredient: drug.genericName,
          colorValue: drug.isRare
              ? 0xFF8B5CF6
              : (drug.type == MedicineType.painkiller
                    ? 0xFFEF4444
                    : 0xFF0D9488),
        );
        _openAddMedicineSheet(newMed);
      } else {
        final newMed = Medicine(
          id: 'med_${DateTime.now().millisecondsSinceEpoch}',
          name: 'دواء جديد (${result.barcode})',
          type: MedicineType.treatment,
          totalPills: 30,
        );
        _openAddMedicineSheet(newMed);
      }
    }
  }

  void _openTakeDoseSheet(Medicine medicine) {
    final safety = medicine.isPainkiller
        ? widget.reminderService.getPainkillerSafety(medicine)
        : null;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => DoseLogSheet(
        medicine: medicine,
        safetyInfo: safety,
        onConfirmed: (log) async {
          // Dynamic dose recording: restarts timer for next dose from actual intake time!
          await widget.reminderService.recordDoseIntake(
            medicine: medicine,
            pillsTaken: log.pillsTaken,
            painLevel: log.painLevel,
            notes: log.notes,
          );
          setState(() {});

          // Check if low stock after dose
          final updated = widget.storageService.getMedicines().firstWhere(
            (m) => m.id == medicine.id,
          );
          if (updated.isLowStock) {
            await widget.reminderService.triggerLowStockNotification(updated);
          }

          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(Ar.doseRecordedSuccess(medicine.name)),
              backgroundColor: const Color(0xFF10B981),
            ),
          );
        },
      ),
    );
  }

  void _openRefillDialog(Medicine medicine) {
    showDialog(
      context: context,
      builder: (ctx) => RefillStockDialog(
        medicine: medicine,
        onConfirm: (newTotal) async {
          final updated = medicine.copyWith(totalPills: newTotal);
          await widget.storageService.updateMedicine(updated);
          if (!mounted) return;
          setState(() {});
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                Ar.stockUpdatedSuccess(
                  medicine.name,
                  newTotal,
                  medicine.unitLabel,
                ),
              ),
              backgroundColor: const Color(0xFF0D9488),
            ),
          );
        },
      ),
    );
  }

  void _openNotificationCenter() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => NotificationCenterSheet(
        storageService: widget.storageService,
        reminderService: widget.reminderService,
        onTakeDose: _openTakeDoseSheet,
      ),
    ).then((_) => setState(() {}));
  }

  void _openDoctorReportSheet() {
    final activeProfile = widget.storageService.getActiveProfile();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => DoctorReportSheet(
        storageService: widget.storageService,
        profile: activeProfile,
      ),
    );
  }

  void _openInteractionGuideSheet() {
    final activeProfileId = widget.storageService.getActiveProfileId();
    final medicines = widget.storageService.getMedicines(
      forProfileId: activeProfileId,
    );
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => InteractionGuideSheet(medicines: medicines),
    );
  }

  IconData _getProfileIcon(int code) {
    switch (code) {
      case 0xe491:
        return Icons.person;
      case 0xe25d:
        return Icons.elderly;
      case 0xe25e:
        return Icons.elderly_woman;
      case 0xe17a:
        return Icons.child_care;
      case 0xe40f:
        return Icons.medication;
      case 0xe3e3:
        return Icons.local_pharmacy;
      case 0xe28b:
        return Icons.favorite;
      default:
        return Icons.person;
    }
  }

  void _openProfileDialog() {
    final profiles = widget.storageService.getProfiles();
    final currentId = widget.storageService.getActiveProfileId();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Row(
          children: [
            Icon(Icons.family_restroom_rounded, color: Color(0xFF0D9488)),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                Ar.familyProfilesMenu,
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ...profiles.map((p) {
              final isSelected = p.id == currentId;
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: Color(p.colorValue).withValues(alpha: 0.2),
                  child: Icon(
                    _getProfileIcon(p.iconCode),
                    color: Color(p.colorValue),
                  ),
                ),
                title: Text(
                  p.name,
                  style: TextStyle(
                    fontWeight: isSelected
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
                ),
                subtitle: Text('${Ar.relationPrefix}${p.relation}'),
                trailing: isSelected
                    ? const Icon(Icons.check_circle, color: Color(0xFF0D9488))
                    : null,
                onTap: () async {
                  await widget.storageService.setActiveProfileId(p.id);
                  if (ctx.mounted) Navigator.pop(ctx);
                  if (mounted) setState(() {});
                },
              );
            }),
            const Divider(),
            TextButton.icon(
              onPressed: () {
                Navigator.pop(ctx);
                _showAddProfileDialog();
              },
              icon: const Icon(Icons.person_add_alt_1),
              label: const Text(Ar.addNewProfileBtn),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddProfileDialog() {
    final nameCtrl = TextEditingController();
    final relationCtrl = TextEditingController(text: Ar.fatherRelationDefault);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text(Ar.addProfileDialogTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(labelText: Ar.profileNameLabel),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: relationCtrl,
              decoration: const InputDecoration(labelText: Ar.relationLabel),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(Ar.cancel),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nameCtrl.text.trim().isNotEmpty) {
                final newProfile = UserProfile(
                  id: 'prof_${DateTime.now().millisecondsSinceEpoch}',
                  name: nameCtrl.text.trim(),
                  relation: relationCtrl.text.trim(),
                  colorValue: 0xFF3B82F6,
                );
                await widget.storageService.addProfile(newProfile);
                await widget.storageService.setActiveProfileId(newProfile.id);
                if (ctx.mounted) Navigator.pop(ctx);
                if (mounted) setState(() {});
              }
            },
            child: const Text(Ar.add),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final activeProfile = widget.storageService.getActiveProfile();
    final unreadNotifs = widget.storageService
        .getNotifications()
        .where((n) => !n.isRead)
        .length;
    final activeBanner = widget.reminderService.latestActiveBanner;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: const Color(0xFF0D9488).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.medication_rounded,
                  color: Color(0xFF0D9488),
                  size: 24,
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      Ar.appName,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    // Active Family Profile Chip
                    InkWell(
                      onTap: _openProfileDialog,
                      borderRadius: BorderRadius.circular(10),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Flexible(
                            child: Text(
                              activeProfile.name,
                              style: const TextStyle(
                                fontSize: 11,
                                color: Color(0xFF0D9488),
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const Icon(
                            Icons.arrow_drop_down,
                            size: 16,
                            color: Color(0xFF0D9488),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            // Barcode & QR Scanner button
            IconButton(
              icon: const Icon(Icons.qr_code_scanner_rounded, size: 24),
              onPressed: _openBarcodeScanner,
              tooltip: Ar.scanBarcodeTooltip,
            ),
            // Notification Center button with badge
            Stack(
              alignment: Alignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.notifications_outlined, size: 26),
                  onPressed: _openNotificationCenter,
                  tooltip: Ar.notificationsTooltip,
                ),
                if (unreadNotifs > 0)
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Color(0xFFEF4444),
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 16,
                        minHeight: 16,
                      ),
                      child: Text(
                        '$unreadNotifs',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
            // More Tools & Options Menu (Organized & Uncluttered)
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert_rounded, size: 26),
              tooltip: Ar.moreAndTools,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              onSelected: (val) {
                switch (val) {
                  case 'scan':
                    _openBarcodeScanner();
                    break;
                  case 'encyclopedia':
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => DrugEncyclopediaScreen(
                          onAddMedicineDirectly: (med) async {
                            await widget.storageService.addMedicine(med);
                            setState(() {});
                            if (!context.mounted) return;
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  Ar.medAddedSuccessNamed(med.name),
                                ),
                                backgroundColor: const Color(0xFF0D9488),
                              ),
                            );
                          },
                          onOpenCustomAdd: () {
                            Navigator.pop(context);
                            _openAddMedicineSheet();
                          },
                        ),
                      ),
                    );
                    break;
                  case 'interactions':
                    _openInteractionGuideSheet();
                    break;
                  case 'report':
                    _openDoctorReportSheet();
                    break;
                  case 'profiles':
                    _openProfileDialog();
                    break;
                  case 'theme':
                    widget.onToggleTheme();
                    break;
                }
              },
              itemBuilder: (ctx) => [
                const PopupMenuItem(
                  value: 'scan',
                  child: Row(
                    children: [
                      Icon(
                        Icons.qr_code_scanner_rounded,
                        color: Color(0xFF0D9488),
                        size: 20,
                      ),
                      SizedBox(width: 10),
                      Text(Ar.scanBarcodeBtn),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'encyclopedia',
                  child: Row(
                    children: [
                      Icon(
                        Icons.menu_book_rounded,
                        color: Color(0xFF0D9488),
                        size: 20,
                      ),
                      SizedBox(width: 10),
                      Text(Ar.encyclopediaMenu),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'interactions',
                  child: Row(
                    children: [
                      Icon(
                        Icons.security_rounded,
                        color: Color(0xFFEF4444),
                        size: 20,
                      ),
                      SizedBox(width: 10),
                      Text(Ar.interactionsMenu),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'report',
                  child: Row(
                    children: [
                      Icon(
                        Icons.assignment_turned_in_outlined,
                        color: Color(0xFF0D9488),
                        size: 20,
                      ),
                      SizedBox(width: 10),
                      Text(Ar.doctorReportMenu),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'profiles',
                  child: Row(
                    children: [
                      Icon(
                        Icons.family_restroom_rounded,
                        color: Color(0xFF0D9488),
                        size: 20,
                      ),
                      SizedBox(width: 10),
                      Text(Ar.familyProfilesMenu),
                    ],
                  ),
                ),
                const PopupMenuDivider(),
                PopupMenuItem(
                  value: 'theme',
                  child: Row(
                    children: [
                      Icon(
                        widget.isDarkMode
                            ? Icons.light_mode_rounded
                            : Icons.dark_mode_rounded,
                        color: widget.isDarkMode
                            ? Colors.amber
                            : Colors.grey[700],
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Text(widget.isDarkMode ? Ar.lightMode : Ar.darkMode),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(width: 4),
          ],
        ),
        body: Stack(
          children: [
            // Body views
            IndexedStack(
              index: _currentIndex,
              children: [
                TodayDosesTab(
                  storageService: widget.storageService,
                  reminderService: widget.reminderService,
                  onTakeDose: _openTakeDoseSheet,
                  onRefill: _openRefillDialog,
                  onAddMedicine: () => _openAddMedicineSheet(),
                ),
                PainkillersTab(
                  storageService: widget.storageService,
                  reminderService: widget.reminderService,
                  onTakeDose: _openTakeDoseSheet,
                  onRefill: _openRefillDialog,
                  onAddMedicine: () => _openAddMedicineSheet(),
                  onEdit: (med) => _openAddMedicineSheet(med),
                  onDelete: (id) async {
                    await widget.storageService.deleteMedicine(id);
                    setState(() {});
                  },
                ),
                PharmacyStockTab(
                  storageService: widget.storageService,
                  reminderService: widget.reminderService,
                  onTakeDose: _openTakeDoseSheet,
                  onRefill: _openRefillDialog,
                  onEdit: (med) => _openAddMedicineSheet(med),
                  onDelete: (id) async {
                    await widget.storageService.deleteMedicine(id);
                    setState(() {});
                  },
                  onAddMedicine: () => _openAddMedicineSheet(),
                ),
                HistoryTab(storageService: widget.storageService),
              ],
            ),

            // In-app Alert Banner if active
            if (activeBanner != null)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: InAppNotificationBanner(
                  notification: activeBanner,
                  onDismiss: () => widget.reminderService.dismissBanner(),
                ),
              ),
          ],
        ),
        bottomNavigationBar: _buildCustomBottomBar(
          context,
          Theme.of(context).brightness == Brightness.dark,
        ),
      ),
    );
  }

  Widget _buildCustomBottomBar(BuildContext context, bool isDark) {
    final bgColor = isDark ? const Color(0xFF0F172A) : Colors.white;
    final borderColor = isDark
        ? const Color(0xFF1E293B)
        : const Color(0xFFE2E8F0);

    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        border: Border(top: BorderSide(color: borderColor, width: 1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.06),
            blurRadius: 18,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 66,
          child: Row(
            children: [
              // Tab 0: الجرعات
              Expanded(
                child: _buildNavTabItem(
                  index: 0,
                  label: Ar.navToday,
                  icon: Icons.calendar_today_outlined,
                  selectedIcon: Icons.calendar_today_rounded,
                  isDark: isDark,
                ),
              ),
              // Tab 1: أدويتي
              Expanded(
                child: _buildNavTabItem(
                  index: 1,
                  label: Ar.navMedicines,
                  icon: Icons.medication_outlined,
                  selectedIcon: Icons.medication_rounded,
                  isDark: isDark,
                ),
              ),

              // Central Hero Action Button: (+)
              Expanded(child: _buildCenterAddButton(isDark)),

              // Tab 2: صيدليتي
              Expanded(
                child: _buildNavTabItem(
                  index: 2,
                  label: Ar.navPharmacy,
                  icon: Icons.local_pharmacy_outlined,
                  selectedIcon: Icons.local_pharmacy_rounded,
                  isDark: isDark,
                ),
              ),
              // Tab 3: سجل الالتزام
              Expanded(
                child: _buildNavTabItem(
                  index: 3,
                  label: Ar.navHistory,
                  icon: Icons.history_outlined,
                  selectedIcon: Icons.history_rounded,
                  isDark: isDark,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCenterAddButton(bool isDark) {
    return Center(
      child: Tooltip(
        message: Ar.addNewMedicine,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: _openAddOptionsSheet,
            customBorder: const CircleBorder(),
            child: Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [Color(0xFF14B8A6), Color(0xFF0D9488)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF0D9488)
                        .withValues(alpha: isDark ? 0.5 : 0.35),
                    blurRadius: 14,
                    spreadRadius: 1,
                    offset: const Offset(0, 3),
                  ),
                ],
                border: Border.all(
                  color: isDark
                      ? const Color(0xFF2DD4BF).withValues(alpha: 0.35)
                      : Colors.white,
                  width: 2.5,
                ),
              ),
              child: const Icon(
                Icons.add_rounded,
                size: 30,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavTabItem({
    required int index,
    required String label,
    required IconData icon,
    required IconData selectedIcon,
    required bool isDark,
  }) {
    final isSelected = _currentIndex == index;
    final primaryColor = isDark
        ? const Color(0xFF2DD4BF)
        : const Color(0xFF0D9488);
    final unselectedColor = isDark
        ? const Color(0xFF64748B)
        : const Color(0xFF94A3B8);

    return InkWell(
      onTap: () => setState(() => _currentIndex = index),
      borderRadius: BorderRadius.circular(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            decoration: BoxDecoration(
              color: isSelected
                  ? (isDark
                        ? const Color(0xFF14B8A6).withValues(alpha: 0.2)
                        : const Color(0xFF0D9488).withValues(alpha: 0.12))
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              isSelected ? selectedIcon : icon,
              color: isSelected ? primaryColor : unselectedColor,
              size: 22,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            style: GoogleFonts.cairo(
              fontSize: 11,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              color: isSelected ? primaryColor : unselectedColor,
              letterSpacing: -0.2,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  void _openAddOptionsSheet() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 25,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Pill drag handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'إضافة سريعة لدواء',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                'اختر الطريقة الأنسب لك',
                style: TextStyle(fontSize: 12.5, color: Colors.grey[500]),
              ),
              const SizedBox(height: 20),

              // Option 1: مسح باركود العلبة بالكاميرا
              _buildAddOptionTile(
                icon: Icons.qr_code_scanner_rounded,
                iconColor: const Color(0xFF0D9488),
                title: Ar.scanBarcodeBtn,
                subtitle: 'توجيه الكاميرا لملء الاسم والعيار تلقائياً',
                badgeText: 'سريع وفوري ⚡',
                onTap: () {
                  Navigator.pop(ctx);
                  _openBarcodeScanner();
                },
              ),
              const SizedBox(height: 12),

              // Option 2: إضافة دواء لجدولي اليومي يدوياً
              _buildAddOptionTile(
                icon: Icons.medication_rounded,
                iconColor: const Color(0xFF3B82F6),
                title: Ar.addNewMedicine,
                subtitle: 'إدخال الاسم والمواعيد والجرعات يدوياً',
                onTap: () {
                  Navigator.pop(ctx);
                  _openAddMedicineSheet();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAddOptionTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    String? badgeText,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: Theme.of(context).dividerColor.withValues(alpha: 0.15),
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14.5,
                        ),
                      ),
                      if (badgeText != null) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0D9488)
                                .withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            badgeText,
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0D9488),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 11.5, color: Colors.grey[500]),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios_rounded,
              size: 14,
              color: Colors.grey,
            ),
          ],
        ),
      ),
    );
  }
}
