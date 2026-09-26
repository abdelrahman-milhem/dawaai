import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../ar.dart';
import '../models/medicine.dart';
import '../models/home_pharmacy.dart';
import '../services/storage_service.dart';
import '../services/reminder_service.dart';
import '../utils/date_utils.dart';
import '../services/medical_time_service.dart';
import '../widgets/pill_refresh_indicator.dart';
import '../widgets/pharmacy_qr_dialog.dart';
import '../widgets/pharmacy_qr_scanner_dialog.dart';

class PharmacyStockTab extends StatefulWidget {
  final StorageService storageService;
  final ReminderService reminderService;
  final Function(Medicine medicine) onTakeDose;
  final Function(Medicine medicine) onRefill;
  final Function(Medicine medicine) onEdit;
  final Function(String id) onDelete;
  final VoidCallback onAddMedicine;

  const PharmacyStockTab({
    super.key,
    required this.storageService,
    required this.reminderService,
    required this.onTakeDose,
    required this.onRefill,
    required this.onEdit,
    required this.onDelete,
    required this.onAddMedicine,
  });

  @override
  State<PharmacyStockTab> createState() => _PharmacyStockTabState();
}

class _PharmacyStockTabState extends State<PharmacyStockTab> {
  String _searchQuery = '';
  String _selectedFilter =
      'all'; // 'all', 'cabinet', 'fridge', 'firstAid', 'lowStock', 'expiring'
  bool _showPassword = false;

  HomePharmacy? get _activePharmacy =>
      widget.storageService.getActiveHomePharmacy();

  @override
  void initState() {
    super.initState();
    widget.storageService.addListener(_onStorageUpdate);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        widget.storageService.syncAllExistingMedicinesToActivePharmacy();
      }
    });
  }

  @override
  void dispose() {
    widget.storageService.removeListener(_onStorageUpdate);
    super.dispose();
  }

  void _onStorageUpdate() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final activePharmacy = _activePharmacy;

    return PillRefreshIndicator(
      onRefresh: () async {
        await MedicalTimeService.instance.syncWithNetworkTime();
        await Future.delayed(const Duration(milliseconds: 500));
        if (mounted) setState(() {});
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(left: 16, right: 16, top: 12, bottom: 100),
        child: activePharmacy == null
            ? _buildNoPharmacyState(context, isDark)
            : _buildConnectedPharmacyDashboard(context, isDark, activePharmacy),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // STATE 1: NOT IN A HOME PHARMACY (JOIN / CREATE)
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildNoPharmacyState(BuildContext context, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Futuristic Glowing Hero Banner
        Container(
          padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isDark
                  ? [const Color(0xFF0F172A), const Color(0xFF1E293B)]
                  : [const Color(0xFF0D9488), const Color(0xFF2563EB)],
              begin: Alignment.topRight,
              end: Alignment.bottomLeft,
            ),
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF0D9488).withValues(alpha: 0.35),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            children: [
              // Hologram icon effect
              Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 90,
                    height: 90,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.08),
                    ),
                  ),
                  Container(
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.15),
                    ),
                  ),
                  const Icon(
                    Icons.home_work_rounded,
                    size: 42,
                    color: Colors.white,
                  ),
                ],
              ),
              const SizedBox(height: 18),
              const Text(
                Ar.homePharmacyFuturisticTitle,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.3),
                  ),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.wifi_tethering_rounded,
                      color: Colors.white,
                      size: 16,
                    ),
                    SizedBox(width: 6),
                    Text(
                      'خزانة البيت الذكية المتصلة',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              const Text(
                Ar.joinHomeHeaderSubtitle,
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 13.5,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Action Card 0: Scan QR Code or Paste Sharing Code
        _buildActionCard(
          context,
          isDark: isDark,
          icon: Icons.qr_code_scanner_rounded,
          iconColor: const Color(0xFF0D9488),
          title: Ar.scanPharmacyQrBtn,
          subtitle: 'امسح رمز QR من هاتف مدير الصيدلية أو الصق كود المشاركة للانضمام فوراً ومزامنة جميع الأدوية والمخزون.',
          buttonText: 'مسح رمز QR أو لصق الكود',
          onTap: () async {
            final joined = await PharmacyQrScannerDialog.show(
              context,
              storageService: widget.storageService,
            );
            if (joined != null && mounted) {
              setState(() {});
            }
          },
        ),
        const SizedBox(height: 16),

        // Action Card 1: Join Home Pharmacy
        _buildActionCard(
          context,
          isDark: isDark,
          icon: Icons.key_rounded,
          iconColor: const Color(0xFF3B82F6),
          title: Ar.joinHomePharmacyAction,
          subtitle: 'لديك معرف صيدلية منزلك وكلمة السر؟ انضم الآن لتتشارك مخزون أدوية البيت مع أفراد أسرتك.',
          buttonText: 'الانضمام بواسطة المعرف وكلمة السر',
          onTap: () => _openJoinPharmacyDialog(context),
        ),
        const SizedBox(height: 16),

        // Action Card 2: Create New Home Pharmacy
        _buildActionCard(
          context,
          isDark: isDark,
          icon: Icons.add_business_rounded,
          iconColor: const Color(0xFF10B981),
          title: Ar.createHomePharmacyAction,
          subtitle: 'أنشئ صيدلية خاصة بمنزلك وحدد لها كلمة سر وشارك المعرف مع أفراد عائلتك لينضموا لها.',
          buttonText: 'إنشاء صيدلية منزل جديدة',
          onTap: () => _openCreatePharmacyDialog(context),
        ),
        const SizedBox(height: 20),

        // Quick Demo Experience Button
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF0FDF4),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: const Color(0xFF10B981).withValues(alpha: 0.4),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Row(
                children: [
                  Icon(
                    Icons.tips_and_updates_rounded,
                    color: Color(0xFF10B981),
                    size: 20,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'تجربة الصيدلية النموذجية الفورية:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Color(0xFF065F46),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              const Text(
                'يمكنك الدخول مباشرة إلى الصيدلية النموذجية الجاهزة (المعرف: HOME-101 • كلمة السر: 1234) لاكتشاف المزايا فوراً.',
                style: TextStyle(
                  fontSize: 12.5,
                  color: Color(0xFF047857),
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: () async {
                  await widget.storageService.joinHomePharmacy(
                    id: 'HOME-101',
                    password: '1234',
                    memberName: widget.storageService.getActiveProfile().name,
                  );
                  setState(() {});
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(Ar.joinedSuccessAlert),
                      backgroundColor: Color(0xFF10B981),
                    ),
                  );
                },
                icon: const Icon(Icons.flash_on_rounded, size: 18),
                label: const Text('دخول صيدلية منزل العائلة (تجربة سريعة)'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF10B981),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 11),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionCard(
    BuildContext context, {
    required bool isDark,
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required String buttonText,
    required VoidCallback onTap,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: Theme.of(context).dividerColor.withValues(alpha: 0.3),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: iconColor, size: 26),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[600],
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: onTap,
            style: ElevatedButton.styleFrom(
              backgroundColor: iconColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: Text(
              buttonText,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // STATE 2: CONNECTED TO A HOUSEHOLD PHARMACY DASHBOARD
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildConnectedPharmacyDashboard(
    BuildContext context,
    bool isDark,
    HomePharmacy pharmacy,
  ) {
    final theme = Theme.of(context);
    final items = pharmacy.items;

    // Filter items
    final filteredItems = items.where((item) {
      if (_searchQuery.trim().isNotEmpty) {
        final query = _searchQuery.toLowerCase().trim();
        final matches =
            item.name.toLowerCase().contains(query) ||
            item.notes.toLowerCase().contains(query) ||
            item.storageLocation.toLowerCase().contains(query);
        if (!matches) return false;
      }

      switch (_selectedFilter) {
        case 'cabinet':
          return item.storageLocation.contains('خزانة');
        case 'fridge':
          return item.storageLocation.contains('ثلاجة');
        case 'firstAid':
          return item.storageLocation.contains('إسعاف');
        case 'lowStock':
          return item.isLowStock;
        case 'expiring':
          return item.isExpiringSoon || item.isExpired;
        default:
          return true;
      }
    }).toList();

    final totalCount = items.length;
    final fridgeCount = items.where((i) => i.isRefrigerated).length;
    final lowStockCount = items.where((i) => i.isLowStock).length;
    final expiringCount = items
        .where((i) => i.isExpiringSoon || i.isExpired)
        .length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ─── Futuristic Connected Header ───
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isDark
                  ? [const Color(0xFF0F172A), const Color(0xFF1E3A5F)]
                  : [const Color(0xFF0D9488), const Color(0xFF1E40AF)],
              begin: Alignment.topRight,
              end: Alignment.bottomLeft,
            ),
            borderRadius: BorderRadius.circular(26),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF0D9488).withValues(alpha: 0.3),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Status Bar
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.3),
                        ),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.wifi_rounded,
                            color: Color(0xFF34D399),
                            size: 14,
                          ),
                          SizedBox(width: 5),
                          Flexible(
                            child: Text(
                              Ar.connectedToHomeNetwork,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        onPressed: () => PharmacyQrDialog.show(
                          context,
                          pharmacy: pharmacy,
                          storageService: widget.storageService,
                        ),
                        icon: const Icon(
                          Icons.qr_code_2_rounded,
                          color: Colors.white,
                          size: 24,
                        ),
                        tooltip: Ar.sharePharmacyQrBtn,
                      ),
                      PopupMenuButton<String>(
                        icon: const Icon(
                          Icons.settings_outlined,
                          color: Colors.white,
                          size: 22,
                        ),
                        tooltip: 'خيارات الصيدلية',
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        onSelected: (val) async {
                          if (val == 'share_qr') {
                            PharmacyQrDialog.show(
                              context,
                              pharmacy: pharmacy,
                              storageService: widget.storageService,
                            );
                          } else if (val == 'scan_qr') {
                            final joined = await PharmacyQrScannerDialog.show(
                              context,
                              storageService: widget.storageService,
                            );
                            if (joined != null && mounted) setState(() {});
                          } else if (val == 'leave') {
                            _confirmLeavePharmacy(context);
                          } else if (val == 'switch') {
                            _openJoinPharmacyDialog(context);
                          } else if (val == 'create') {
                            _openCreatePharmacyDialog(context);
                          }
                        },
                        itemBuilder: (ctx) => [
                          const PopupMenuItem(
                            value: 'share_qr',
                            child: Row(
                              children: [
                                Icon(
                                  Icons.qr_code_2_rounded,
                                  color: Color(0xFF0D9488),
                                  size: 20,
                                ),
                                SizedBox(width: 10),
                                Text('مشاركة الصيدلية عبر رمز QR'),
                              ],
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'scan_qr',
                            child: Row(
                              children: [
                                Icon(
                                  Icons.qr_code_scanner_rounded,
                                  color: Color(0xFF10B981),
                                  size: 20,
                                ),
                                SizedBox(width: 10),
                                Text('مسح كود صيدلية للانضمام/المزامنة'),
                              ],
                            ),
                          ),
                          const PopupMenuDivider(),
                          const PopupMenuItem(
                            value: 'switch',
                            child: Row(
                              children: [
                                Icon(
                                  Icons.swap_horiz_rounded,
                                  color: Color(0xFF3B82F6),
                                  size: 20,
                                ),
                                SizedBox(width: 10),
                                Text('الانضمام لصيدلية منزل أخرى'),
                              ],
                            ),
                          ),
                      const PopupMenuItem(
                        value: 'create',
                        child: Row(
                          children: [
                            Icon(
                              Icons.add_home_work_rounded,
                              color: Color(0xFF10B981),
                              size: 20,
                            ),
                            SizedBox(width: 10),
                            Text('إنشاء صيدلية منزل جديدة'),
                          ],
                        ),
                      ),
                      const PopupMenuDivider(),
                      const PopupMenuItem(
                        value: 'leave',
                        child: Row(
                          children: [
                            Icon(
                              Icons.logout_rounded,
                              color: Colors.red,
                              size: 20,
                            ),
                            SizedBox(width: 10),
                            Text(
                              Ar.leaveHomePharmacyAction,
                              style: TextStyle(color: Colors.red),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),

              // Title
              Text(
                pharmacy.name,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 14),

              // Credentials Hologram Box (ID and Password)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.2),
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        // ID badge
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'معرف الصيدلية (ID)',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 11,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Row(
                                children: [
                                  Text(
                                    pharmacy.id,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 1.2,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  InkWell(
                                    onTap: () {
                                      Clipboard.setData(
                                        ClipboardData(text: pharmacy.id),
                                      );
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                            const SnackBar(
                                              content: Text(
                                                'تم نسخ معرف الصيدلية!',
                                              ),
                                              duration: Duration(seconds: 2),
                                            ),
                                          );
                                    },
                                    child: const Icon(
                                      Icons.copy_rounded,
                                      color: Colors.white70,
                                      size: 16,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        Container(width: 1, height: 32, color: Colors.white24),
                        const SizedBox(width: 12),

                        // Password badge
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'رمز الدخول (PIN)',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 11,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Row(
                                children: [
                                  Text(
                                    _showPassword ? pharmacy.password : '••••',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 1.5,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  InkWell(
                                    onTap: () => setState(
                                      () => _showPassword = !_showPassword,
                                    ),
                                    child: Icon(
                                      _showPassword
                                          ? Icons.visibility_off
                                          : Icons.visibility,
                                      color: Colors.white70,
                                      size: 16,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    const Divider(height: 1, color: Colors.white24),
                    const SizedBox(height: 8),

                    Row(
                      children: [
                        // Quick Share Invite Button
                        Expanded(
                          child: InkWell(
                            onTap: () => _sharePharmacyCredentials(pharmacy),
                            borderRadius: BorderRadius.circular(10),
                            child: const Padding(
                              padding: EdgeInsets.symmetric(vertical: 4, horizontal: 4),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.share_rounded,
                                    color: Color(0xFF67E8F9),
                                    size: 15,
                                  ),
                                  SizedBox(width: 4),
                                  Flexible(
                                    child: Text(
                                      Ar.shareHomeInviteBtn,
                                      style: TextStyle(
                                        color: Color(0xFF67E8F9),
                                        fontWeight: FontWeight.bold,
                                        fontSize: 11.5,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        Container(width: 1, height: 16, color: Colors.white24),
                        // QR Code Share Button
                        Expanded(
                          child: InkWell(
                            onTap: () => PharmacyQrDialog.show(
                              context,
                              pharmacy: pharmacy,
                              storageService: widget.storageService,
                            ),
                            borderRadius: BorderRadius.circular(10),
                            child: const Padding(
                              padding: EdgeInsets.symmetric(vertical: 4, horizontal: 4),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.qr_code_2_rounded,
                                    color: Color(0xFF34D399),
                                    size: 15,
                                  ),
                                  SizedBox(width: 4),
                                  Flexible(
                                    child: Text(
                                      Ar.sharePharmacyQrBtn,
                                      style: TextStyle(
                                        color: Color(0xFF34D399),
                                        fontWeight: FontWeight.bold,
                                        fontSize: 11.5,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // ─── Household Members Row ───
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.group_rounded,
                  size: 20,
                  color: Color(0xFF0D9488),
                ),
                const SizedBox(width: 8),
                Text(
                  'أفراد المنزل (${pharmacy.members.length})',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            TextButton.icon(
              onPressed: () => _sharePharmacyCredentials(pharmacy),
              icon: const Icon(Icons.person_add_alt_1_rounded, size: 16),
              label: const Text(
                'دعوة فرد',
                style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 60,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: pharmacy.members.length + 1,
            separatorBuilder: (_, _) => const SizedBox(width: 10),
            itemBuilder: (ctx, index) {
              if (index == pharmacy.members.length) {
                // Add member invite chip
                return InkWell(
                  onTap: () => _sharePharmacyCredentials(pharmacy),
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: theme.dividerColor,
                        style: BorderStyle.solid,
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.add, size: 18, color: Color(0xFF0D9488)),
                        SizedBox(width: 4),
                        Text(
                          'دعوة فرد',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }

              final member = pharmacy.members[index];
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Color(member.avatarColor).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Color(member.avatarColor).withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircleAvatar(
                      radius: 14,
                      backgroundColor: Color(member.avatarColor),
                      child: Text(
                        member.name.isNotEmpty ? member.name[0] : 'ع',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          member.name,
                          style: const TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          member.isAdmin ? 'مدير الخزانة' : 'فرد من المنزل',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 18),

        // ─── Stats Grid ───
        Row(
          children: [
            Expanded(
              child: _buildStockStatCard(
                'إجمالي الأدوية',
                '$totalCount',
                Icons.medication_rounded,
                const Color(0xFF0D9488),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildStockStatCard(
                'في الثلاجة ❄️',
                '$fridgeCount',
                Icons.ac_unit_rounded,
                const Color(0xFF0284C7),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildStockStatCard(
                'قارب النفاذ',
                '$lowStockCount',
                Icons.warning_amber_rounded,
                const Color(0xFFDC2626),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildStockStatCard(
                'قريب الانتهاء',
                '$expiringCount',
                Icons.hourglass_bottom_rounded,
                const Color(0xFFD97706),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),

        // ─── Search Bar & Add Item Action ───
        Row(
          children: [
            Expanded(
              child: TextField(
                onChanged: (val) => setState(() => _searchQuery = val),
                decoration: InputDecoration(
                  hintText: Ar.searchHomeMedicines,
                  hintStyle: TextStyle(fontSize: 13, color: Colors.grey[500]),
                  prefixIcon: const Icon(Icons.search_rounded, size: 20),
                  filled: true,
                  fillColor: theme.cardColor,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(
                      color: theme.dividerColor.withValues(alpha: 0.3),
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(
                      color: theme.dividerColor.withValues(alpha: 0.3),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton.icon(
              onPressed: () => _openAddHomeItemDialog(context),
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text(
                'إضافة دواء',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0D9488),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 13,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // ─── Category Filter Chips ───
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildFilterChip('all', 'الكل ($totalCount)'),
              const SizedBox(width: 8),
              _buildFilterChip('cabinet', 'خزانة الأدوية'),
              const SizedBox(width: 8),
              _buildFilterChip('fridge', 'الثلاجة ❄️'),
              const SizedBox(width: 8),
              _buildFilterChip('firstAid', 'الإسعافات 🩹'),
              const SizedBox(width: 8),
              _buildFilterChip('lowStock', 'نقص المخزون ⚠️'),
              const SizedBox(width: 8),
              _buildFilterChip('expiring', 'قريب الانتهاء ⏳'),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // ─── Medicines List ───
        if (items.isEmpty)
          Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.inventory_2_outlined,
                  size: 50,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 12),
                const Text(
                  'خزانة صيدلية المنزل فارغة حالياً',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                Text(
                  'ابدأ بإضافة الأدوية المتوفرة في منزلك ليعرف الجميع ما لديكم بالبيت.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey[600], fontSize: 13),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () => _openAddHomeItemDialog(context),
                  icon: const Icon(Icons.add),
                  label: const Text('إضافة أول دواء لخزانة البيت'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0D9488),
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          )
        else if (filteredItems.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Center(
              child: Text(
                'لا توجد أدوية مطابقة للبحث أو الفلتر المحدد',
                style: TextStyle(color: Colors.grey),
              ),
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: filteredItems.length,
            itemBuilder: (ctx, index) {
              final item = filteredItems[index];
              return _buildHomeItemCard(context, item, isDark);
            },
          ),
      ],
    );
  }

  Widget _buildFilterChip(String filterKey, String label) {
    final isSelected = _selectedFilter == filterKey;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => setState(() => _selectedFilter = filterKey),
      selectedColor: const Color(0xFF0D9488),
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : Colors.grey[700],
        fontSize: 12,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    );
  }

  Widget _buildStockStatCard(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(fontSize: 9.5, color: Colors.grey[600]),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // HOME ITEM CARD
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildHomeItemCard(
    BuildContext context,
    HomePharmacyItem item,
    bool isDark,
  ) {
    final theme = Theme.of(context);
    final isLowStock = item.isLowStock;
    final isExpiring = item.isExpiringSoon;
    final isExpired = item.isExpired;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isExpired
              ? Colors.red
              : (isLowStock
                    ? Colors.orange.withValues(alpha: 0.5)
                    : theme.dividerColor.withValues(alpha: 0.25)),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Form Icon
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF0D9488).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  item.isRefrigerated
                      ? Icons.ac_unit_rounded
                      : Icons.medication_rounded,
                  color: item.isRefrigerated
                      ? const Color(0xFF0284C7)
                      : const Color(0xFF0D9488),
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),

              // Title and Storage Location
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        // Location badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.blueGrey.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.location_on_outlined,
                                size: 12,
                                color: Colors.blueGrey,
                              ),
                              const SizedBox(width: 3),
                              Text(
                                item.storageLocation,
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Colors.blueGrey,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Added By
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.grey.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'أضافه: ${item.addedByName}',
                            style: TextStyle(
                              fontSize: 10.5,
                              color: Colors.grey[600],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Quantity Badge
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: isLowStock
                          ? const Color(0xFFFEE2E2)
                          : const Color(0xFFE0F2FE),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${item.quantity} ${item.unit}',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: isLowStock
                            ? const Color(0xFFDC2626)
                            : const Color(0xFF0369A1),
                      ),
                    ),
                  ),
                  if (isLowStock) ...[
                    const SizedBox(height: 2),
                    const Text(
                      'قارب النفاذ ⚠️',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),

          if (item.notes.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              item.notes,
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],

          if (item.expiryDate != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  Icons.event_outlined,
                  size: 13,
                  color: isExpired
                      ? Colors.red
                      : (isExpiring ? Colors.orange : Colors.grey[600]),
                ),
                const SizedBox(width: 4),
                Text(
                  'الصلاحية: ${AppDateUtils.formatShortDate(item.expiryDate!)}',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: isExpired
                        ? Colors.red
                        : (isExpiring ? Colors.orange[800] : Colors.grey[600]),
                  ),
                ),
                if (isExpired) ...[
                  const SizedBox(width: 6),
                  const Text(
                    '(منتهي الصلاحية ⛔)',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ] else if (isExpiring) ...[
                  const SizedBox(width: 6),
                  const Text(
                    '(ينتهي قريباً)',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.orange,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ],
            ),
          ],

          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 8),

          // Actions Row (Responsive Wrap to prevent RenderFlex overflow)
          Wrap(
            spacing: 6,
            runSpacing: 6,
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Consume dose (-1)
                  OutlinedButton.icon(
                    onPressed: item.quantity <= 0
                        ? null
                        : () async {
                            await widget.storageService.consumeHomeItem(item.id, 1);
                            setState(() {});
                          },
                    icon: const Icon(Icons.remove, size: 15),
                    label: const Text(
                      Ar.consumeHomeDose,
                      style: TextStyle(fontSize: 11.5),
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      visualDensity: VisualDensity.compact,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),

                  // Refill stock (+)
                  OutlinedButton.icon(
                    onPressed: () => _openRefillHomeItemDialog(context, item),
                    icon: const Icon(Icons.add, size: 15),
                    label: const Text(
                      Ar.refillHomeDose,
                      style: TextStyle(fontSize: 11.5),
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      visualDensity: VisualDensity.compact,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ],
              ),

              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Import to personal daily schedule
                  IconButton(
                    icon: const Icon(
                      Icons.playlist_add_rounded,
                      size: 22,
                      color: Color(0xFF0D9488),
                    ),
                    tooltip: 'إضافة هذا الدواء لجدول جرعاتي اليومي',
                    onPressed: () => _importToPersonalSchedule(item),
                  ),

                  // Delete item
                  IconButton(
                    icon: const Icon(
                      Icons.delete_outline,
                      size: 20,
                      color: Colors.red,
                    ),
                    tooltip: 'حذف من خزانة البيت',
                    onPressed: () async {
                      await widget.storageService.deleteHomeItem(item.id);
                      setState(() {});
                    },
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // DIALOGS & ACTIONS
  // ══════════════════════════════════════════════════════════════════════════
  void _sharePharmacyCredentials(HomePharmacy pharmacy) {
    final inviteText = Ar.shareHomeInviteText(
      pharmacy.name,
      pharmacy.id,
      pharmacy.password,
    );
    Clipboard.setData(ClipboardData(text: inviteText));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(Ar.copiedToClipboard)),
          ],
        ),
        backgroundColor: const Color(0xFF10B981),
      ),
    );
  }

  void _openJoinPharmacyDialog(BuildContext context) {
    final idCtrl = TextEditingController();
    final passCtrl = TextEditingController();
    final nameCtrl = TextEditingController(
      text: widget.storageService.getActiveProfile().name,
    );

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Row(
          children: [
            Icon(Icons.vpn_key_rounded, color: Color(0xFF3B82F6)),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                Ar.joinHomeHeaderTitle,
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              Ar.joinPharmacyDialogDesc,
              style: TextStyle(fontSize: 12.5, color: Colors.grey, height: 1.4),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: idCtrl,
              textCapitalization: TextCapitalization.characters,
              decoration: const InputDecoration(
                labelText: Ar.pharmacyIdInputLabel,
                hintText: 'مثلاً: HOME-101',
                prefixIcon: Icon(Icons.fingerprint_rounded),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: passCtrl,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: Ar.pharmacyPasswordInputLabel,
                hintText: 'كلمة السر / PIN',
                prefixIcon: Icon(Icons.lock_outline_rounded),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(
                labelText: Ar.memberNameInputLabel,
                prefixIcon: Icon(Icons.person_outline_rounded),
              ),
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
              if (idCtrl.text.trim().isEmpty || passCtrl.text.trim().isEmpty) {
                return;
              }
              final success = await widget.storageService.joinHomePharmacy(
                id: idCtrl.text.trim(),
                password: passCtrl.text.trim(),
                memberName: nameCtrl.text.trim(),
              );
              if (!ctx.mounted) return;
              Navigator.pop(ctx);
              if (success) {
                setState(() {});
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(Ar.joinedSuccessAlert),
                    backgroundColor: Color(0xFF10B981),
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(Ar.invalidCredentialsAlert),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF3B82F6),
              foregroundColor: Colors.white,
            ),
            child: const Text('انضمام الآن'),
          ),
        ],
      ),
    );
  }

  void _openCreatePharmacyDialog(BuildContext context) {
    final nameCtrl = TextEditingController(text: 'صيدلية بيت العائلة');
    final idCtrl = TextEditingController(
      text: 'HOME-${100 + DateTime.now().millisecond % 899}',
    );
    final passCtrl = TextEditingController(
      text: '${1000 + DateTime.now().millisecond % 8999}',
    );
    final adminCtrl = TextEditingController(
      text: widget.storageService.getActiveProfile().name,
    );

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Row(
          children: [
            Icon(Icons.add_home_work_rounded, color: Color(0xFF10B981)),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                Ar.createHomeHeaderTitle,
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                Ar.createPharmacyDialogDesc,
                style: TextStyle(
                  fontSize: 12.5,
                  color: Colors.grey,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(
                  labelText: Ar.pharmacyNameInputLabel,
                  prefixIcon: Icon(Icons.home_outlined),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: idCtrl,
                textCapitalization: TextCapitalization.characters,
                decoration: const InputDecoration(
                  labelText: Ar.pharmacyIdInputLabel,
                  prefixIcon: Icon(Icons.badge_outlined),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: passCtrl,
                decoration: const InputDecoration(
                  labelText: Ar.pharmacyPasswordInputLabel,
                  prefixIcon: Icon(Icons.lock_outline_rounded),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: adminCtrl,
                decoration: const InputDecoration(
                  labelText: 'اسمك (مدير الخزانة)',
                  prefixIcon: Icon(Icons.person_outline_rounded),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(Ar.cancel),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nameCtrl.text.trim().isEmpty || passCtrl.text.trim().isEmpty) {
                return;
              }
              await widget.storageService.createHomePharmacy(
                name: nameCtrl.text.trim(),
                password: passCtrl.text.trim(),
                adminName: adminCtrl.text.trim(),
                customId: idCtrl.text.trim(),
              );
              if (!ctx.mounted) return;
              Navigator.pop(ctx);
              setState(() {});
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(Ar.createdSuccessAlert),
                  backgroundColor: Color(0xFF10B981),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF10B981),
              foregroundColor: Colors.white,
            ),
            child: const Text('إنشاء الصيدلية'),
          ),
        ],
      ),
    );
  }

  void _openAddHomeItemDialog(BuildContext context) {
    final nameCtrl = TextEditingController();
    final qtyCtrl = TextEditingController(text: '20');
    final unitCtrl = TextEditingController(text: 'قرص');
    final notesCtrl = TextEditingController();
    MedicineForm selectedForm = MedicineForm.pill;
    String selectedLocation = Ar.locationCabinetDefault;
    DateTime? selectedExpiry = DateTime.now().add(const Duration(days: 365));

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (modalCtx, setModalState) => Container(
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    const Icon(Icons.add_box_rounded, color: Color(0xFF0D9488)),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        Ar.addMedToHomeStock,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(ctx),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'اسم الدواء أو المستحضر',
                    hintText: 'مثلاً: بنادول، بروفين، فيتامين د...',
                    prefixIcon: Icon(Icons.medication_rounded),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: TextField(
                        controller: qtyCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'الكمية المتوفرة',
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 2,
                      child: TextField(
                        controller: unitCtrl,
                        decoration: const InputDecoration(
                          labelText: 'الوحدة (قرص، زجاجة...)',
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Location selector
                const Text(
                  'أين يحفظ هذا الدواء بالمنزل؟',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  children:
                      [
                        Ar.locationCabinetDefault,
                        Ar.locationFridgeDefault,
                        Ar.locationFirstAidDefault,
                        Ar.locationRoomDefault,
                      ].map((loc) {
                        final isSel = selectedLocation == loc;
                        return ChoiceChip(
                          label: Text(loc),
                          selected: isSel,
                          onSelected: (_) =>
                              setModalState(() => selectedLocation = loc),
                        );
                      }).toList(),
                ),
                const SizedBox(height: 14),

                // Expiry Date Picker
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'تاريخ انتهاء الصلاحية:',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate:
                              selectedExpiry ??
                              DateTime.now().add(const Duration(days: 365)),
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(
                            const Duration(days: 365 * 10),
                          ),
                        );
                        if (picked != null) {
                          setModalState(() => selectedExpiry = picked);
                        }
                      },
                      icon: const Icon(Icons.calendar_today_rounded, size: 16),
                      label: Text(
                        selectedExpiry != null
                            ? AppDateUtils.formatShortDate(selectedExpiry!)
                            : 'تحديد التاريخ',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: notesCtrl,
                  decoration: const InputDecoration(
                    labelText:
                        'ملاحظات واستخدامات (مثلاً: للصداع، خاص بالأطفال...)',
                    prefixIcon: Icon(Icons.notes_rounded),
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () async {
                    if (nameCtrl.text.trim().isEmpty) return;
                    final parsedQty = int.tryParse(qtyCtrl.text.trim()) ?? 1;
                    final userProfile = widget.storageService
                        .getActiveProfile();

                    final newItem = HomePharmacyItem(
                      id: 'item_${DateTime.now().millisecondsSinceEpoch}',
                      name: nameCtrl.text.trim(),
                      form: selectedForm,
                      quantity: parsedQty,
                      unit: unitCtrl.text.trim().isNotEmpty
                          ? unitCtrl.text.trim()
                          : 'حبة',
                      storageLocation: selectedLocation,
                      expiryDate: selectedExpiry,
                      addedByName: userProfile.name,
                      notes: notesCtrl.text.trim(),
                    );

                    await widget.storageService.addHomeItem(newItem);
                    if (!ctx.mounted) return;
                    Navigator.pop(ctx);
                    setState(() {});
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0D9488),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    'حفظ الدواء في خزانة البيت',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _openRefillHomeItemDialog(BuildContext context, HomePharmacyItem item) {
    final addCtrl = TextEditingController(text: '10');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('إعادة تعبئة ${item.name}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('الكمية الحالية: ${item.quantity} ${item.unit}'),
            const SizedBox(height: 12),
            TextField(
              controller: addCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'الكمية المضافة (شراء علبة جديدة)',
                prefixIcon: Icon(Icons.add_shopping_cart),
              ),
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
              final toAdd = int.tryParse(addCtrl.text.trim()) ?? 0;
              if (toAdd > 0) {
                await widget.storageService.refillHomeItem(item.id, toAdd);
                setState(() {});
              }
              if (!ctx.mounted) return;
              Navigator.pop(ctx);
            },
            child: const Text('إضافة للمخزون'),
          ),
        ],
      ),
    );
  }

  void _importToPersonalSchedule(HomePharmacyItem item) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: const Row(
          children: [
            Icon(Icons.playlist_add_check_rounded, color: Color(0xFF0D9488)),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'إضافة لجدولك اليومي',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: Text(
          'هل تريد إضافة "${item.name}" إلى قائمة أدويتك وجدولك اليومي لمتابعة أوقات تناولها وتنبيهاتها؟',
          style: const TextStyle(fontSize: 13.5, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(Ar.cancel),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final activeProfileId = widget.storageService
                  .getActiveProfileId();
              final isPain =
                  item.name.toLowerCase().contains('panadol') ||
                  item.name.toLowerCase().contains('بنادول') ||
                  item.name.toLowerCase().contains('بروفين') ||
                  item.name.toLowerCase().contains('مسكن');

              final newMed = Medicine(
                id: 'med_home_${DateTime.now().millisecondsSinceEpoch}',
                name: item.name,
                type: isPain ? MedicineType.painkiller : MedicineType.treatment,
                form: item.form,
                totalPills: item.quantity,
                pillsPerDose: 1,
                scheduledTimes: isPain
                    ? []
                    : [
                        const TimeOfDay(hour: 8, minute: 0),
                        const TimeOfDay(hour: 20, minute: 0),
                      ],
                profileId: activeProfileId,
                instructions: item.notes.isNotEmpty ? item.notes : Ar.foodAfter,
              );

              await widget.storageService.addMedicine(newMed);
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'تمت إضافة ${item.name} إلى جدول أدويتك اليومي بنجاح!',
                  ),
                  backgroundColor: const Color(0xFF0D9488),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0D9488),
              foregroundColor: Colors.white,
            ),
            child: const Text('نعم، أضف للجدول'),
          ),
        ],
      ),
    );
  }

  void _confirmLeavePharmacy(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: const Text('مغادرة الصيدلية المنزلية'),
        content: const Text(
          'هل تريد مغادرة هذه الصيدلية؟ يمكنك دائماً العودة إليها عن طريق إدخال معرفها وكلمة السر مجدداً.',
          style: TextStyle(fontSize: 13.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(Ar.cancel),
          ),
          ElevatedButton(
            onPressed: () async {
              await widget.storageService.leaveActiveHomePharmacy();
              if (!ctx.mounted) return;
              Navigator.pop(ctx);
              setState(() {});
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('مغادرة'),
          ),
        ],
      ),
    );
  }
}
