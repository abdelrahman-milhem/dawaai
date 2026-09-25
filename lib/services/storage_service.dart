import 'dart:io';
import 'dart:convert';
import 'dart:async';
import '../ar.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/medicine.dart';
import '../models/dose_log.dart';
import '../models/app_notification.dart';
import '../models/user_profile.dart';
import '../models/home_pharmacy.dart';

class StorageService extends ChangeNotifier {
  static const String _keyMedicines = 'dawaai_medicines_v2';
  static const String _keyLogs = 'dawaai_logs_v2';
  static const String _keyNotifications = 'dawaai_notifications_v2';
  static const String _keyProfiles = 'dawaai_profiles_v2';
  static const String _keyActiveProfile = 'dawaai_active_profile_v2';
  static const String _keyDarkMode = 'dawaai_dark_mode';
  static const String _keyHomePharmacies = 'dawaai_home_pharmacies_v2';
  static const String _keyActiveHomePharmacyId = 'dawaai_active_home_pharmacy_id_v2';

  final SharedPreferences _prefs;

  // --- IN-MEMORY ULTRA-FAST ZERO-ALLOCATION CACHES ---
  List<Medicine> _medicinesCache = [];
  List<DoseLog> _logsCache = [];
  List<AppNotificationItem> _notificationsCache = [];
  List<UserProfile> _profilesCache = [];
  List<HomePharmacy> _pharmaciesCache = [];
  String _activeProfileIdCache = 'self';
  String? _activeHomePharmacyIdCache;
  bool _isDarkModeCache = false;

  // Cached index for O(1) log lookups by medicine ID
  final Map<String, List<DoseLog>> _logsByMedicineId = {};

  StorageService(this._prefs) {
    _loadCachesFromDisk();
  }

  void _loadCachesFromDisk() {
    _isDarkModeCache = _prefs.getBool(_keyDarkMode) ?? false;
    _activeProfileIdCache = _prefs.getString(_keyActiveProfile) ?? 'self';
    _activeHomePharmacyIdCache = _prefs.getString(_keyActiveHomePharmacyId);

    // 1. Profiles
    final rawProfiles = _prefs.getStringList(_keyProfiles) ??
        _prefs.getStringList('dawaai_profiles') ??
        _prefs.getStringList('profiles');
    if (rawProfiles != null && rawProfiles.isNotEmpty) {
      try {
        _profilesCache = rawProfiles.map((item) => UserProfile.fromJson(item)).toList();
      } catch (_) {
        _profilesCache = [
          UserProfile(id: 'self', name: Ar.myProfileDefaultName, relation: Ar.myProfileRelation, colorValue: 0xFF0D9488),
        ];
      }
    } else {
      _profilesCache = [
        UserProfile(id: 'self', name: Ar.myProfileDefaultName, relation: Ar.myProfileRelation, colorValue: 0xFF0D9488),
      ];
    }

    // 2. Medicines (Support v2, v1, legacy keys)
    final rawMeds = _prefs.getStringList(_keyMedicines) ??
        _prefs.getStringList('dawaai_medicines') ??
        _prefs.getStringList('dawaai_medicines_v1') ??
        _prefs.getStringList('medicines');
    if (rawMeds != null && rawMeds.isNotEmpty) {
      try {
        _medicinesCache = rawMeds.map((item) => Medicine.fromJson(item)).toList();
      } catch (e) {
        debugPrint('Error decoding medicines: $e');
        _medicinesCache = [];
      }
    } else {
      _medicinesCache = [];
    }

    // 3. Dose Logs (Support v2, v1, legacy keys)
    final rawLogs = _prefs.getStringList(_keyLogs) ??
        _prefs.getStringList('dawaai_logs') ??
        _prefs.getStringList('dawaai_logs_v1') ??
        _prefs.getStringList('logs');
    if (rawLogs != null && rawLogs.isNotEmpty) {
      try {
        _logsCache = rawLogs.map((item) => DoseLog.fromJson(item)).toList();
      } catch (e) {
        debugPrint('Error decoding logs: $e');
        _logsCache = [];
      }
    } else {
      _logsCache = [];
    }
    _rebuildLogsIndex();

    // 4. Notifications
    final rawNotifs = _prefs.getStringList(_keyNotifications) ??
        _prefs.getStringList('dawaai_notifications') ??
        _prefs.getStringList('notifications');
    if (rawNotifs != null && rawNotifs.isNotEmpty) {
      try {
        _notificationsCache = rawNotifs.map((item) => AppNotificationItem.fromJson(item)).toList();
      } catch (e) {
        debugPrint('Error decoding notifications: $e');
        _notificationsCache = [];
      }
    } else {
      _notificationsCache = [];
    }

    // 5. Home Pharmacies
    final rawPharmacies = _prefs.getStringList(_keyHomePharmacies) ??
        _prefs.getStringList('dawaai_home_pharmacies') ??
        _prefs.getStringList('home_pharmacies');
    if (rawPharmacies != null && rawPharmacies.isNotEmpty) {
      try {
        _pharmaciesCache = rawPharmacies.map((item) => HomePharmacy.fromJson(item)).toList();
      } catch (e) {
        debugPrint('Error decoding pharmacies: $e');
        _pharmaciesCache = [];
      }
    } else {
      _pharmaciesCache = [];
    }
  }

  void _rebuildLogsIndex() {
    _logsByMedicineId.clear();
    for (final log in _logsCache) {
      _logsByMedicineId.putIfAbsent(log.medicineId, () => []).add(log);
    }
  }

  static Future<StorageService> init() async {
    final prefs = await SharedPreferences.getInstance();
    final service = StorageService(prefs);
    await service._initSampleDataIfNeeded();
    return service;
  }

  bool isDarkMode() {
    return _isDarkModeCache;
  }

  Future<void> setDarkMode(bool value) async {
    _isDarkModeCache = value;
    await _prefs.setBool(_keyDarkMode, value);
    notifyListeners();
  }

  // --- PROFILES (وضع العائلة) ---
  List<UserProfile> getProfiles() {
    return List.unmodifiable(_profilesCache);
  }

  Future<void> saveProfiles(List<UserProfile> profiles) async {
    _profilesCache = List.from(profiles);
    final list = _profilesCache.map((p) => p.toJson()).toList();
    unawaited(_prefs.setStringList(_keyProfiles, list));
    _autoBackupToDevice();
    notifyListeners();
  }

  Future<void> addProfile(UserProfile profile) async {
    _profilesCache.add(profile);
    await saveProfiles(_profilesCache);
  }

  String getActiveProfileId() {
    return _activeProfileIdCache;
  }

  Future<void> setActiveProfileId(String id) async {
    _activeProfileIdCache = id;
    await _prefs.setString(_keyActiveProfile, id);
    notifyListeners();
  }

  UserProfile getActiveProfile() {
    final id = _activeProfileIdCache;
    return _profilesCache.firstWhere(
      (p) => p.id == id,
      orElse: () => _profilesCache.isNotEmpty
          ? _profilesCache.first
          : UserProfile(id: 'self', name: Ar.myProfileDefaultName, relation: Ar.myProfileRelation, colorValue: 0xFF0D9488),
    );
  }

  // --- MEDICINES ---
  List<Medicine> getMedicines({String? forProfileId}) {
    if (forProfileId != null && forProfileId.trim().isNotEmpty) {
      final target = forProfileId.trim().toLowerCase();
      return _medicinesCache.where((m) {
        final p = m.profileId.trim().toLowerCase();
        if (target == 'self') {
          return p == 'self' || p.isEmpty || p == 'null';
        }
        return p == target;
      }).toList(growable: false);
    }
    return List.unmodifiable(_medicinesCache);
  }

  Future<void> saveMedicines(List<Medicine> medicines) async {
    _medicinesCache = List.from(medicines);
    final list = _medicinesCache.map((m) => m.toJson()).toList();
    unawaited(_prefs.setStringList(_keyMedicines, list));
    _autoBackupToDevice();
    notifyListeners();
  }

  Future<void> addMedicine(Medicine medicine) async {
    _medicinesCache.add(medicine);
    await saveMedicines(_medicinesCache);
  }

  Future<void> updateMedicine(Medicine medicine) async {
    final index = _medicinesCache.indexWhere((m) => m.id == medicine.id);
    if (index != -1) {
      _medicinesCache[index] = medicine;
      await saveMedicines(_medicinesCache);
    }
  }

  Future<void> deleteMedicine(String id) async {
    _medicinesCache.removeWhere((m) => m.id == id);
    await saveMedicines(_medicinesCache);
  }

  // --- DOSE LOGS ---
  List<DoseLog> getLogs({String? forMedicineId}) {
    if (forMedicineId != null) {
      return _logsByMedicineId[forMedicineId] ?? const [];
    }
    return List.unmodifiable(_logsCache);
  }

  Future<void> saveLogs(List<DoseLog> logs) async {
    _logsCache = List.from(logs);
    _rebuildLogsIndex();
    final list = _logsCache.map((l) => l.toJson()).toList();
    unawaited(_prefs.setStringList(_keyLogs, list));
    _autoBackupToDevice();
    notifyListeners();
  }

  Future<void> addDoseLog(DoseLog log, {DateTime? recalculatedNextDose, String? note}) async {
    _logsCache.insert(0, log);
    _logsByMedicineId.putIfAbsent(log.medicineId, () => []).insert(0, log);

    final logStrings = _logsCache.map((l) => l.toJson()).toList();
    unawaited(_prefs.setStringList(_keyLogs, logStrings));

    // Decrement stock & update dynamic next dose time + last taken time in memory & disk!
    final index = _medicinesCache.indexWhere((m) => m.id == log.medicineId);
    if (index != -1) {
      final current = _medicinesCache[index];
      final newCount = (current.totalPills - log.pillsTaken).clamp(0, 99999);
      _medicinesCache[index] = current.copyWith(
        totalPills: newCount,
        lastTakenTime: log.takenAt,
        dynamicNextDoseTime: recalculatedNextDose,
        dynamicRescheduleNote: note,
      );
      final medStrings = _medicinesCache.map((m) => m.toJson()).toList();
      unawaited(_prefs.setStringList(_keyMedicines, medStrings));
    }

    _autoBackupToDevice();
    notifyListeners();
  }

  // --- NOTIFICATIONS ---
  List<AppNotificationItem> getNotifications() {
    return List.unmodifiable(_notificationsCache);
  }

  Future<void> saveNotifications(List<AppNotificationItem> items) async {
    _notificationsCache = List.from(items);
    final list = _notificationsCache.map((i) => i.toJson()).toList();
    unawaited(_prefs.setStringList(_keyNotifications, list));
    notifyListeners();
  }

  Future<void> addNotification(AppNotificationItem item) async {
    _notificationsCache.insert(0, item);
    if (_notificationsCache.length > 50) {
      _notificationsCache.removeRange(50, _notificationsCache.length);
    }
    await saveNotifications(_notificationsCache);
  }

  Future<void> markAllNotificationsRead() async {
    for (var item in _notificationsCache) {
      item.isRead = true;
    }
    await saveNotifications(_notificationsCache);
  }

  Future<void> clearNotifications() async {
    _notificationsCache.clear();
    await _prefs.remove(_keyNotifications);
    notifyListeners();
  }

  // --- HOME PHARMACY & SHARED INVENTORY (صيدلية المنزل والمخزون المشترك) ---
  List<HomePharmacy> getHomePharmacies() {
    return List.unmodifiable(_pharmaciesCache);
  }

  Future<void> saveHomePharmacies(List<HomePharmacy> pharmacies) async {
    _pharmaciesCache = List.from(pharmacies);
    final list = _pharmaciesCache.map((p) => p.toJson()).toList();
    unawaited(_prefs.setStringList(_keyHomePharmacies, list));
    _autoBackupToDevice();
    notifyListeners();
  }

  String? getActiveHomePharmacyId() {
    return _activeHomePharmacyIdCache;
  }

  Future<void> setActiveHomePharmacyId(String? id) async {
    _activeHomePharmacyIdCache = id;
    if (id == null) {
      await _prefs.remove(_keyActiveHomePharmacyId);
    } else {
      await _prefs.setString(_keyActiveHomePharmacyId, id);
    }
    notifyListeners();
  }

  HomePharmacy? getActiveHomePharmacy() {
    final id = _activeHomePharmacyIdCache;
    if (id == null) return null;
    try {
      return _pharmaciesCache.firstWhere((p) => p.id.toUpperCase() == id.toUpperCase());
    } catch (_) {
      return null;
    }
  }

  Future<HomePharmacy> createHomePharmacy({
    required String name,
    required String password,
    required String adminName,
    String? customId,
  }) async {
    final pharmacies = List<HomePharmacy>.from(_pharmaciesCache);
    final id = (customId != null && customId.trim().isNotEmpty)
        ? customId.trim().toUpperCase()
        : 'HOME-${(100 + pharmacies.length * 17 + DateTime.now().millisecond % 899)}';

    final admin = HomePharmacyMember(
      id: 'member_${DateTime.now().millisecondsSinceEpoch}',
      name: adminName.trim().isNotEmpty ? adminName.trim() : 'مدير الخزانة',
      role: 'admin',
      avatarColor: 0xFF0D9488,
    );

    final newPharmacy = HomePharmacy(
      id: id,
      name: name.trim().isNotEmpty ? name.trim() : 'صيدلية منزلنا',
      password: password.trim(),
      adminName: admin.name,
      members: [admin],
      items: [],
    );

    pharmacies.removeWhere((p) => p.id.toUpperCase() == id.toUpperCase());
    pharmacies.add(newPharmacy);
    await saveHomePharmacies(pharmacies);
    await setActiveHomePharmacyId(id);
    return newPharmacy;
  }

  Future<bool> joinHomePharmacy({
    required String id,
    required String password,
    required String memberName,
  }) async {
    final pharmacies = List<HomePharmacy>.from(_pharmaciesCache);
    final cleanId = id.trim().toUpperCase();
    final cleanPass = password.trim();

    final index = pharmacies.indexWhere(
      (p) => p.id.toUpperCase() == cleanId && p.password == cleanPass,
    );

    if (index == -1) {
      return false;
    }

    final pharmacy = pharmacies[index];
    final memberCleanName = memberName.trim().isNotEmpty ? memberName.trim() : 'فرد جديد';

    final exists = pharmacy.members.any((m) => m.name.toLowerCase() == memberCleanName.toLowerCase());
    if (!exists) {
      final newMember = HomePharmacyMember(
        id: 'member_${DateTime.now().millisecondsSinceEpoch}',
        name: memberCleanName,
        role: 'member',
        avatarColor: 0xFF3B82F6,
      );
      pharmacy.members.add(newMember);
      await saveHomePharmacies(pharmacies);
    }

    await setActiveHomePharmacyId(pharmacy.id);
    return true;
  }

  Future<void> leaveActiveHomePharmacy() async {
    await setActiveHomePharmacyId(null);
  }

  Future<void> addHomeItem(HomePharmacyItem item) async {
    final activeId = _activeHomePharmacyIdCache;
    if (activeId == null) return;
    final pharmacies = List<HomePharmacy>.from(_pharmaciesCache);
    final index = pharmacies.indexWhere((p) => p.id.toUpperCase() == activeId.toUpperCase());
    if (index != -1) {
      pharmacies[index].items.add(item);
      await saveHomePharmacies(pharmacies);
    }
  }

  Future<void> updateHomeItem(HomePharmacyItem item) async {
    final activeId = _activeHomePharmacyIdCache;
    if (activeId == null) return;
    final pharmacies = List<HomePharmacy>.from(_pharmaciesCache);
    final index = pharmacies.indexWhere((p) => p.id.toUpperCase() == activeId.toUpperCase());
    if (index != -1) {
      final itemIdx = pharmacies[index].items.indexWhere((i) => i.id == item.id);
      if (itemIdx != -1) {
        pharmacies[index].items[itemIdx] = item;
        await saveHomePharmacies(pharmacies);
      }
    }
  }

  Future<void> deleteHomeItem(String itemId) async {
    final activeId = _activeHomePharmacyIdCache;
    if (activeId == null) return;
    final pharmacies = List<HomePharmacy>.from(_pharmaciesCache);
    final index = pharmacies.indexWhere((p) => p.id.toUpperCase() == activeId.toUpperCase());
    if (index != -1) {
      pharmacies[index].items.removeWhere((i) => i.id == itemId);
      await saveHomePharmacies(pharmacies);
    }
  }

  Future<void> consumeHomeItem(String itemId, int amount) async {
    final activeId = _activeHomePharmacyIdCache;
    if (activeId == null) return;
    final pharmacies = List<HomePharmacy>.from(_pharmaciesCache);
    final index = pharmacies.indexWhere((p) => p.id.toUpperCase() == activeId.toUpperCase());
    if (index != -1) {
      final itemIdx = pharmacies[index].items.indexWhere((i) => i.id == itemId);
      if (itemIdx != -1) {
        final current = pharmacies[index].items[itemIdx];
        final newQuantity = (current.quantity - amount).clamp(0, 99999);
        pharmacies[index].items[itemIdx] = current.copyWith(quantity: newQuantity);
        await saveHomePharmacies(pharmacies);
      }
    }
  }

  Future<void> refillHomeItem(String itemId, int amount) async {
    final activeId = _activeHomePharmacyIdCache;
    if (activeId == null) return;
    final pharmacies = List<HomePharmacy>.from(_pharmaciesCache);
    final index = pharmacies.indexWhere((p) => p.id.toUpperCase() == activeId.toUpperCase());
    if (index != -1) {
      final itemIdx = pharmacies[index].items.indexWhere((i) => i.id == itemId);
      if (itemIdx != -1) {
        final current = pharmacies[index].items[itemIdx];
        final newQuantity = (current.quantity + amount).clamp(0, 99999);
        pharmacies[index].items[itemIdx] = current.copyWith(quantity: newQuantity);
        await saveHomePharmacies(pharmacies);
      }
    }
  }

  // --- INITIAL DATA & PURGING MOCK DATA ---
  Future<void> _initSampleDataIfNeeded() async {
    // 1. Ensure basic default profile exists
    if (_profilesCache.isEmpty) {
      final defaultProfile = [
        UserProfile(id: 'self', name: Ar.myProfileRelation, relation: Ar.myProfileRelation, colorValue: 0xFF0D9488, iconCode: 0xe491),
      ];
      await saveProfiles(defaultProfile);
      await setActiveProfileId('self');
    }

    // 2. Initialize default household pharmacy if none exists
    if (_pharmaciesCache.isEmpty) {
      final initialHome = HomePharmacy(
        id: 'HOME-101',
        name: 'صيدلية منزل العائلة',
        password: '1234',
        adminName: 'أحمد (رب الأسرة)',
        members: [
          HomePharmacyMember(id: 'm1', name: 'أحمد', role: 'admin', avatarColor: 0xFF0D9488),
          HomePharmacyMember(id: 'm2', name: 'سارة', role: 'member', avatarColor: 0xFF8B5CF6),
          HomePharmacyMember(id: 'm3', name: 'الوالدة', role: 'member', avatarColor: 0xFFEC4899),
        ],
        items: [
          HomePharmacyItem(
            id: 'item_1',
            name: 'بانادول إكسترا (Panadol Extra)',
            form: MedicineForm.pill,
            quantity: 24,
            unit: 'قرص',
            storageLocation: 'خزانة الأدوية الرئيسية',
            expiryDate: DateTime.now().add(const Duration(days: 360)),
            addedByName: 'أحمد',
            notes: 'للصداع والحمى والآلام العامة',
          ),
          HomePharmacyItem(
            id: 'item_2',
            name: 'أوجمنتين 1 جم (Augmentin)',
            form: MedicineForm.pill,
            quantity: 8,
            unit: 'قرص',
            storageLocation: 'خزانة الأدوية الرئيسية',
            expiryDate: DateTime.now().add(const Duration(days: 180)),
            addedByName: 'سارة',
            notes: 'مضاد حيوي موصوف طبياً',
          ),
          HomePharmacyItem(
            id: 'item_3',
            name: 'شراب فينتولين (Ventolin)',
            form: MedicineForm.syrup,
            quantity: 1,
            unit: 'زجاجة',
            storageLocation: 'خزانة الأدوية الرئيسية',
            expiryDate: DateTime.now().add(const Duration(days: 240)),
            addedByName: 'الوالدة',
            notes: 'للكحة وتوسيع الشعب الهوائية',
          ),
          HomePharmacyItem(
            id: 'item_4',
            name: 'قطرة ريفريش تيرز (Refresh Tears)',
            form: MedicineForm.drops,
            quantity: 2,
            unit: 'عبوة',
            storageLocation: 'ثلاجة المطبخ',
            expiryDate: DateTime.now().add(const Duration(days: 400)),
            addedByName: 'أحمد',
            notes: 'مرطب للعين، تحفظ مبردة بالثلاجة',
          ),
          HomePharmacyItem(
            id: 'item_5',
            name: 'كريم ميبو للحروق (Mebo)',
            form: MedicineForm.ointment,
            quantity: 1,
            unit: 'أنبوب',
            storageLocation: 'حقيبة الإسعافات الأولية',
            expiryDate: DateTime.now().add(const Duration(days: 500)),
            addedByName: 'سارة',
            notes: 'للحروق والجروح السطحية',
          ),
          HomePharmacyItem(
            id: 'item_6',
            name: 'فيتامين سي 1000 مجم (Vitamin C)',
            form: MedicineForm.pill,
            quantity: 12,
            unit: 'قرص فوار',
            storageLocation: 'خزانة الأدوية الرئيسية',
            expiryDate: DateTime.now().add(const Duration(days: 300)),
            addedByName: 'أحمد',
            notes: 'للمناعة ومقاومة نزلات البرد',
          ),
        ],
      );
      await saveHomePharmacies([initialHome]);
      if (_activeHomePharmacyIdCache == null) {
        await setActiveHomePharmacyId('HOME-101');
      }
    }

    // 3. ALWAYS purge any mock/sample data so the app strictly contains user-added data only
    await purgeAllMockData();

    // 4. CORE REQUIREMENT: Automatically restore medicines from local backup if empty!
    if (_medicinesCache.isEmpty) {
      try {
        await restoreBackupFromDevice(silent: true);
      } catch (_) {}
    }
  }

  Future<void> purgeAllMockData() async {
    // Purge sample medicines & test residues
    final realMedicines = _medicinesCache.where(
      (m) => !m.id.startsWith('med_sample_') && !m.id.startsWith('bulk_med_') && !m.id.startsWith('test_med_')
    ).toList();
    if (realMedicines.length != _medicinesCache.length) {
      await saveMedicines(realMedicines);
    }

    // Purge sample logs & test residues
    final realLogs = _logsCache.where(
      (l) => !l.id.startsWith('log_sample_') && !l.medicineId.startsWith('bulk_med_') && !l.medicineId.startsWith('test_med_')
    ).toList();
    if (realLogs.length != _logsCache.length) {
      await saveLogs(realLogs);
    }

    // Purge sample notifications
    final realNotifs = _notificationsCache.where((n) => !n.id.startsWith('notif_welcome') && !n.id.startsWith('notif_sample')).toList();
    if (realNotifs.length != _notificationsCache.length) {
      await saveNotifications(realNotifs);
    }

    // Purge sample family profiles ('father', 'mother' defaults)
    final profiles = getProfiles();
    final realProfiles = profiles.where((p) => p.id != 'father' && p.id != 'mother').toList();
    if (realProfiles.isEmpty) {
      realProfiles.add(UserProfile(id: 'self', name: Ar.myProfileRelation, relation: Ar.myProfileRelation, colorValue: 0xFF0D9488, iconCode: 0xe491));
    }
    if (realProfiles.length != profiles.length) {
      await saveProfiles(realProfiles);
    }
  }

  // --- PERSISTENT BACKUP & RESTORE (عبر إعادة التثبيت) ---
  List<String> _getBackupCandidatePaths() {
    if (Platform.isAndroid) {
      return [
        '/storage/emulated/0/Download/dawaai_backup.json',
        '/sdcard/Download/dawaai_backup.json',
        '/storage/emulated/0/Documents/dawaai_backup.json',
      ];
    } else {
      final home = Platform.environment['USERPROFILE'] ?? Platform.environment['HOME'] ?? '.';
      return [
        '$home/Downloads/dawaai_backup.json',
        '$home/Documents/dawaai_backup.json',
        'dawaai_backup.json',
      ];
    }
  }

  /// يحفظ نسخة احتياطية مشفرة/منظمة محلياً في الذاكرة المشتركة لتصمد عند حذف التطبيق
  Future<bool> exportBackupToDevice() async {
    try {
      if (Platform.environment.containsKey('FLUTTER_TEST')) return false;
      if (_medicinesCache.isEmpty) return false;

      final payload = {
        'version': 2,
        'app': 'dawaai',
        'exportedAt': DateTime.now().toIso8601String(),
        'medicines': _medicinesCache.map((m) => m.toMap()).toList(),
        'logs': _logsCache.map((l) => l.toMap()).toList(),
        'profiles': _profilesCache.map((p) => p.toMap()).toList(),
      };
      final jsonStr = json.encode(payload);

      bool written = false;
      for (final path in _getBackupCandidatePaths()) {
        try {
          final file = File(path);
          final parent = file.parent;
          if (!parent.existsSync()) {
            parent.createSync(recursive: true);
          }
          await file.writeAsString(jsonStr, flush: true);
          debugPrint('Dawaai: Backup mirrored successfully to: $path');
          written = true;
          break;
        } catch (e) {
          debugPrint('Dawaai: Candidate path unavailable ($path): $e');
        }
      }
      return written;
    } catch (e) {
      debugPrint('Dawaai: Export backup failed: $e');
      return false;
    }
  }

  /// يسترجع الأدوية تلقائياً أو يدوياً بعد إعادة تثبيت التطبيق
  Future<bool> restoreBackupFromDevice({bool silent = false}) async {
    try {
      if (Platform.environment.containsKey('FLUTTER_TEST')) return false;
      for (final path in _getBackupCandidatePaths()) {
        try {
          final file = File(path);
          final exists = await file.exists().timeout(const Duration(milliseconds: 500), onTimeout: () => false);
          if (exists) {
            final content = await file.readAsString().timeout(const Duration(seconds: 1));
            final map = json.decode(content) as Map<String, dynamic>;
            if (map.containsKey('medicines')) {
              final rawList = map['medicines'] as List;
              final medList = rawList.map((m) => Medicine.fromMap(m as Map<String, dynamic>)).toList();
              if (medList.isNotEmpty) {
                await saveMedicines(medList);
              }
            }
            if (map.containsKey('logs')) {
              final rawList = map['logs'] as List;
              final logList = rawList.map((l) => DoseLog.fromMap(l as Map<String, dynamic>)).toList();
              if (logList.isNotEmpty) {
                await saveLogs(logList);
              }
            }
            if (map.containsKey('profiles')) {
              final rawList = map['profiles'] as List;
              final profList = rawList.map((p) => UserProfile.fromMap(p as Map<String, dynamic>)).toList();
              if (profList.isNotEmpty) {
                await saveProfiles(profList);
              }
            }
            debugPrint('Dawaai: Restored backup successfully from: $path');
            return true;
          }
        } catch (e) {
          debugPrint('Dawaai: Could not read backup from $path: $e');
        }
      }
      return false;
    } catch (e) {
      debugPrint('Dawaai: Restore backup failed: $e');
      return false;
    }
  }

  void _autoBackupToDevice() {
    // تشغيل الحفظ الاحتياطي التلقائي في الخلفية دون تعطيل واجهة المستخدم
    Future.microtask(() async {
      try {
        await exportBackupToDevice();
      } catch (_) {}
    });
  }

  Future<void> clearAllUserData() async {
    _medicinesCache.clear();
    _logsCache.clear();
    _notificationsCache.clear();
    _profilesCache.clear();
    _logsByMedicineId.clear();
    await _prefs.remove(_keyMedicines);
    await _prefs.remove(_keyLogs);
    await _prefs.remove(_keyNotifications);
    await _prefs.remove(_keyProfiles);
    await _prefs.remove(_keyActiveProfile);
    await _initSampleDataIfNeeded();
  }
}

