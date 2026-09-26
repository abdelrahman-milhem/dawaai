import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dawaai/main.dart';
import 'package:dawaai/ar.dart';
import 'package:dawaai/models/medicine.dart';
import 'package:dawaai/models/dose_log.dart';
import 'package:dawaai/models/home_pharmacy.dart';
import 'package:dawaai/services/storage_service.dart';
import 'package:dawaai/services/reminder_service.dart';
import 'package:dawaai/data/drug_database.dart';

void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  testWidgets('Dawaai App smoke test and UI verification', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final storageService = await StorageService.init();
    final reminderService = ReminderService(storageService);

    await tester.pumpWidget(DawaaiApp(
      storageService: storageService,
      reminderService: reminderService,
    ));

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    // Verify Arabic app title 'دوائي'
    expect(find.text(Ar.appName), findsOneWidget);

    // Verify navigation tabs
    expect(find.text(Ar.navToday), findsOneWidget);
    expect(find.text(Ar.navMedicines), findsOneWidget);
    expect(find.text(Ar.navPharmacy), findsOneWidget);
    expect(find.text(Ar.navHistory), findsOneWidget);

    reminderService.dispose();
  });

  test('Next dose only logic and immediate advance upon taking dose', () async {
    SharedPreferences.setMockInitialValues({});
    final storageService = await StorageService.init();
    final reminderService = ReminderService(storageService);

    final med = Medicine(
      id: 'test_med_next',
      name: 'ميتفورمين 500 ملغ',
      type: MedicineType.treatment,
      totalPills: 30,
      pillsPerDose: 1,
      scheduledTimes: const [TimeOfDay(hour: 8, minute: 0), TimeOfDay(hour: 20, minute: 0)],
    );
    await storageService.addMedicine(med);

    // Step 1: Initial state -> Next dose must be the 8:00 AM dose
    final initialNext = reminderService.getNextDoseForMedicine(med);
    expect(initialNext, isNotNull);
    expect(initialNext!.timeOfDay.hour, equals(8));
    expect(initialNext.isToday, isTrue);
    expect(initialNext.isAllTodayCompleted, isFalse);

    // Step 2: User taps "أخذت الجرعة" -> Immediately advances to 20:00 PM dose
    final afterFirstDose = await reminderService.takeNextDoseNow(med);
    expect(afterFirstDose, isNotNull);
    expect(afterFirstDose!.timeOfDay.hour, equals(20));
    expect(afterFirstDose.isToday, isTrue);
    expect(afterFirstDose.isAllTodayCompleted, isFalse);

    // Pill stock must have decremented
    final updatedMeds = storageService.getMedicines();
    expect(updatedMeds.firstWhere((m) => m.id == med.id).totalPills, equals(29));

    // Step 3: User takes the second dose (20:00 PM) -> Today's doses completed, next is tomorrow 8:00 AM!
    final afterSecondDose = await reminderService.takeNextDoseNow(med);
    expect(afterSecondDose, isNotNull);
    expect(afterSecondDose!.isAllTodayCompleted, isTrue);
    expect(afterSecondDose.isTomorrow, isTrue);
    expect(afterSecondDose.timeOfDay.hour, equals(8));

    // Step 4: Interval-based medicine taken yesterday and app reopened today -> must NOT say completed today
    final intervalMed = Medicine(
      id: 'test_interval_med',
      name: 'أموكسيسيلين كل 8 ساعات',
      type: MedicineType.treatment,
      totalPills: 20,
      intervalHours: 8,
      lastTakenTime: DateTime.now().subtract(const Duration(hours: 14)), // taken 14 hours ago (yesterday)
    );
    final nextIntervalDose = reminderService.getNextDoseForMedicine(intervalMed);
    expect(nextIntervalDose, isNotNull);
    expect(nextIntervalDose!.isAllTodayCompleted, isFalse);
    expect(nextIntervalDose.isDueNow, isTrue);

    reminderService.dispose();
  });

  test('Collaborative Home Pharmacy creation, joining with credentials, and stock operations', () async {
    SharedPreferences.setMockInitialValues({});
    final storageService = await StorageService.init();

    // 1. Create a home pharmacy with ID and Password
    final pharmacy = await storageService.createHomePharmacy(
      name: 'صيدلية بيت الأهل',
      password: 'mypassword123',
      adminName: 'أبو أحمد',
      customId: 'HOME-777',
    );

    expect(pharmacy.id, equals('HOME-777'));
    expect(pharmacy.password, equals('mypassword123'));
    expect(pharmacy.adminName, equals('أبو أحمد'));
    expect(pharmacy.members.length, equals(1));

    // 2. Family member joins using correct ID and password
    final joinSuccess = await storageService.joinHomePharmacy(
      id: 'HOME-777',
      password: 'mypassword123',
      memberName: 'أم أحمد',
    );
    expect(joinSuccess, isTrue);

    final activePharmacy = storageService.getActiveHomePharmacy();
    expect(activePharmacy, isNotNull);
    expect(activePharmacy!.members.any((m) => m.name == 'أم أحمد'), isTrue);

    // 3. Unauthorized join attempt with wrong password must fail
    final wrongPassJoin = await storageService.joinHomePharmacy(
      id: 'HOME-777',
      password: 'wrong_password_999',
      memberName: 'شخص غريب',
    );
    expect(wrongPassJoin, isFalse);

    // 4. Add medicine to home pharmacy stock
    final newItem = HomePharmacyItem(
      id: 'home_panadol',
      name: 'بانادول فائق القوة',
      quantity: 30,
      unit: 'قرص',
      storageLocation: 'خزانة الأدوية الرئيسية',
      addedByName: 'أم أحمد',
    );
    await storageService.addHomeItem(newItem);

    final updatedPharmacy = storageService.getActiveHomePharmacy();
    expect(updatedPharmacy!.items.length, equals(1));
    expect(updatedPharmacy.items.first.quantity, equals(30));

    // 5. Member consumes dose (-1)
    await storageService.consumeHomeItem('home_panadol', 1);
    final afterConsume = storageService.getActiveHomePharmacy();
    expect(afterConsume!.items.first.quantity, equals(29));

    // 6. Member refills stock (+10)
    await storageService.refillHomeItem('home_panadol', 10);
    final afterRefill = storageService.getActiveHomePharmacy();
    expect(afterRefill!.items.first.quantity, equals(39));
  });

  test('Painkiller safe interval logic verifies safe message', () async {
    SharedPreferences.setMockInitialValues({});
    final storageService = await StorageService.init();
    final reminderService = ReminderService(storageService);

    final painkiller = Medicine(
      id: 'test_panadol',
      name: 'باراسيتامول',
      type: MedicineType.painkiller,
      totalPills: 20,
      pillsPerDose: 1,
      minSafeIntervalHours: 4,
      maxDailyDoses: 4,
    );

    // Case 1: No dose taken yet -> Safe now!
    final safetyInitial = reminderService.getPainkillerSafety(painkiller, []);
    expect(safetyInitial.isSafeNow, isTrue);
    expect(safetyInitial.statusMessage, 'يمكنك تناول المسكن الآن بأمان إذا كنت تشعر بألم');

    // Case 2: Dose taken 1 hour ago -> Not safe yet (cooldown)
    final recentLog = DoseLog(
      id: 'log_1',
      medicineId: 'test_panadol',
      medicineName: 'باراسيتامول',
      takenAt: DateTime.now().subtract(const Duration(hours: 1)),
      pillsTaken: 1,
      isPainkiller: true,
    );
    final safetyCooldown = reminderService.getPainkillerSafety(painkiller, [recentLog]);
    expect(safetyCooldown.isSafeNow, isFalse);
    expect(safetyCooldown.statusMessage.contains('يرجى الانتظار'), isTrue);

    reminderService.dispose();
  });

  test('Barcode scanning identifies medicine from DrugDatabase and auto-fills data', () {
    // 1. Scan Panadol EAN-13
    final panadol = DrugDatabase.findByBarcode('6291003440019');
    expect(panadol, isNotNull);
    expect(panadol!.id, equals('panadol'));
    expect(panadol.tradeName.contains('بنادول'), isTrue);
    expect(panadol.type, equals(MedicineType.painkiller));
    expect(panadol.defaultForm, equals(MedicineForm.pill));

    // 2. Scan Brufen EAN-13
    final brufen = DrugDatabase.findByBarcode('8002660002131');
    expect(brufen, isNotNull);
    expect(brufen!.id, equals('brufen'));
    expect(brufen.tradeName.contains('بروفين'), isTrue);

    // 3. Scan Voltaren EAN-13
    final voltaren = DrugDatabase.findByBarcode('7680398290214');
    expect(voltaren, isNotNull);
    expect(voltaren!.id, equals('voltaren'));

    // 4. Scan GS1 format (01)6291003440019
    final gs1Panadol = DrugDatabase.findByBarcode('01629100344001917261231');
    expect(gs1Panadol, isNotNull);
    expect(gs1Panadol!.id, equals('panadol'));

    // 5. Test Arab regional search: بايمول (Pymol), ريفانين (Revanin), كلافودار (Clavodar), بيودال (Biodal)
    final pymolResults = DrugDatabase.search('بايمول');
    expect(pymolResults.isNotEmpty, isTrue);
    expect(pymolResults.first.id, equals('pymol'));
    expect(pymolResults.first.company.contains('JPM'), isTrue);

    final pymolEn = DrugDatabase.search('Pymol');
    expect(pymolEn.isNotEmpty, isTrue);
    expect(pymolEn.first.id, equals('pymol'));

    final revaninResults = DrugDatabase.search('ريفانين');
    expect(revaninResults.isNotEmpty, isTrue);
    expect(revaninResults.first.id, equals('revanin'));

    final clavodarResults = DrugDatabase.search('كلافودار');
    expect(clavodarResults.isNotEmpty, isTrue);
    expect(clavodarResults.first.id, equals('clavodar'));

    final biodalResults = DrugDatabase.search('بيودال');
    expect(biodalResults.isNotEmpty, isTrue);
    expect(biodalResults.first.id, equals('biodal'));
  });

  test('Zero-resource in-memory caching handles 500 medicines and 2000 logs instantly', () async {
    SharedPreferences.setMockInitialValues({});
    final storage = await StorageService.init();

    // Add 500 medicines
    final meds = List.generate(
      500,
      (i) => Medicine(
        id: 'bulk_med_$i',
        name: 'دواء تجريبي رقم $i',
        type: MedicineType.treatment,
        scheduledTimes: [const TimeOfDay(hour: 8, minute: 0), const TimeOfDay(hour: 20, minute: 0)],
        totalPills: 100,
        pillsPerDose: 1,
      ),
    );
    await storage.saveMedicines(meds);

    // Read 500 medicines 100 times - should execute in near 0ms without JSON thrashing
    final stopwatch = Stopwatch()..start();
    for (int i = 0; i < 100; i++) {
      final list = storage.getMedicines();
      expect(list.length, equals(500));
    }
    stopwatch.stop();
    expect(stopwatch.elapsedMilliseconds, lessThan(200));

    // Test indexed logs lookup
    final logs = List.generate(
      2000,
      (i) => DoseLog(
        id: 'log_$i',
        medicineId: 'bulk_med_${i % 500}',
        medicineName: 'دواء تجريبي رقم ${i % 500}',
        takenAt: DateTime.now().subtract(Duration(hours: i)),
      ),
    );
    await storage.saveLogs(logs);

    final med0Logs = storage.getLogs(forMedicineId: 'bulk_med_0');
    expect(med0Logs.length, equals(4)); // 2000 / 500 = 4
  });

  test('Notification tap confirms dose intake and advances next scheduled time', () async {
    SharedPreferences.setMockInitialValues({});
    final storage = await StorageService.init();
    final reminder = ReminderService(storage);

    final med = Medicine(
      id: 'panadol_notif_test',
      name: 'بنادول إكسترا',
      type: MedicineType.treatment,
      totalPills: 20,
      pillsPerDose: 2,
      scheduledTimes: const [TimeOfDay(hour: 9, minute: 0), TimeOfDay(hour: 21, minute: 0)],
    );
    await storage.addMedicine(med);

    // Initial stock = 20
    expect(storage.getMedicines().first.totalPills, equals(20));

    // Simulate user tapping the notification in system tray
    await reminder.handleNotificationDoseConfirmation('panadol_notif_test');

    // Stock should decrement by 2 -> 18
    final updated = storage.getMedicines().first;
    expect(updated.totalPills, equals(18));
    expect(updated.lastTakenTime, isNotNull);

    // Dose log should be registered
    final logs = storage.getLogs(forMedicineId: 'panadol_notif_test');
    expect(logs.isNotEmpty, isTrue);
    expect(logs.first.pillsTaken, equals(2));
  });

  test('Medical Safety Engine: Early intake warning & Delayed dose dynamic rescheduling', () async {
    SharedPreferences.setMockInitialValues({});
    final storage = await StorageService.init();
    final reminder = ReminderService(storage);

    // Scenario: Medicine taken 3 times a day (8-hour interval: 08:00, 16:00, 24:00)
    final med = Medicine(
      id: 'med_safety_test',
      name: 'مضاد حيوي أوجمنتين',
      type: MedicineType.treatment,
      totalPills: 30,
      pillsPerDose: 1,
      minSafeIntervalHours: 8,
      scheduledTimes: const [
        TimeOfDay(hour: 8, minute: 0),
        TimeOfDay(hour: 16, minute: 0),
        TimeOfDay(hour: 23, minute: 59),
      ],
    );
    await storage.addMedicine(med);

    // 1. Check Safe interval hours calculation
    final interval = reminder.getSafeIntervalHours(med);
    expect(interval, equals(8)); // 24 / 3 = 8 hours

    // 2. User took dose at 10:00 AM (2 hours late from 08:00 AM scheduled dose)
    final takenAt = DateTime(2026, 9, 26, 10, 0);

    // Log dose at 10:00 AM
    await reminder.recordDoseIntake(
      medicine: med,
      pillsTaken: 1,
      customTime: takenAt,
    );

    // The next scheduled time was supposed to be 16:00 (which is only 6h from 10:00).
    // The safety engine MUST dynamically reschedule next dose to 10:00 + 8h = 18:00 PM!
    final updatedMed = storage.getMedicines().firstWhere((m) => m.id == med.id);
    expect(updatedMed.dynamicNextDoseTime, isNotNull);
    expect(updatedMed.dynamicNextDoseTime!.hour, equals(18));
    expect(updatedMed.dynamicNextDoseTime!.minute, equals(0));

    // 3. Early Intake Safety check: If user tries to take another dose at 12:00 PM (only 2h later)
    final earlyAttemptTime = DateTime(2026, 9, 26, 12, 0);
    final safetyCheck = reminder.getMedicationSafety(
      updatedMed,
      null,
      earlyAttemptTime,
    );
    expect(safetyCheck.isSafeNow, isFalse);
    expect(safetyCheck.remainingCooldown?.inMinutes, equals(360)); // 6 hours remaining (360 mins)
    expect(safetyCheck.safeIntervalHours, equals(8));

    reminder.dispose();
  });

  test('Home Pharmacy QR Export & Cross-Device Import Synchronization', () async {
    // Device A: Create Pharmacy with items
    SharedPreferences.setMockInitialValues({});
    final storageA = await StorageService.init();

    await storageA.createHomePharmacy(
      name: 'صيدلية عائلة محمد',
      password: '5566',
      adminName: 'محمد',
      customId: 'HOME-TEST-QR',
    );

    // Add an item to Pharmacy A
    final item1 = HomePharmacyItem(
      id: 'item_panadol_1',
      name: 'بنادول إكسترا',
      quantity: 24,
      unit: 'قرص',
      storageLocation: 'خزانة الصالة',
      expiryDate: DateTime.now().add(const Duration(days: 300)),
    );
    await storageA.addHomeItem(item1);

    final updatedPharmacyA = storageA.getActiveHomePharmacy()!;
    expect(updatedPharmacyA.items.length, equals(1));

    // Export QR Payload
    final qrPayload = storageA.exportPharmacyPayload(updatedPharmacyA);
    expect(qrPayload.startsWith('DAWAAI_PHARMACY_V1:'), isTrue);

    // Device B: Fresh install on another phone (empty storage)
    SharedPreferences.setMockInitialValues({});
    final storageB = await StorageService.init();
    expect(storageB.getHomePharmacies().any((p) => p.id == 'HOME-TEST-QR'), isFalse);

    // Device B scans QR code / imports payload
    final importedOnB = await storageB.importPharmacyFromPayload(
      qrPayload,
      memberName: 'فاطمة',
    );

    expect(importedOnB, isNotNull);
    expect(importedOnB!.id, equals('HOME-TEST-QR'));
    expect(importedOnB.name, equals('صيدلية عائلة محمد'));
    expect(importedOnB.items.length, equals(1));
    expect(importedOnB.items.first.name, equals('بنادول إكسترا'));
    expect(importedOnB.items.first.quantity, equals(24));
    expect(importedOnB.members.any((m) => m.name == 'فاطمة'), isTrue);
    expect(storageB.getActiveHomePharmacyId(), equals('HOME-TEST-QR'));
  });

  test('Automatic Medicine Sync & Cross-Pharmacy Migration on Leave/Switch', () async {
    SharedPreferences.setMockInitialValues({});
    final storage = await StorageService.init();

    // 1. Create Pharmacy 1 (القديمة)
    await storage.createHomePharmacy(
      name: 'صيدلية المنزل القديم',
      password: '1111',
      adminName: 'أنا',
      customId: 'PHARM-OLD',
    );
    expect(storage.getActiveHomePharmacyId(), equals('PHARM-OLD'));

    // 2. User adds a personal medicine -> must automatically appear in PHARM-OLD
    final med = Medicine(
      id: 'my_aspirin_100',
      name: 'أسبرين 100 ملغ',
      type: MedicineType.treatment,
      totalPills: 50,
      pillsPerDose: 1,
    );
    await storage.addMedicine(med);

    // Verify it automatically exists in PHARM-OLD items
    var currentPharm = storage.getActiveHomePharmacy()!;
    expect(currentPharm.items.any((i) => i.name == 'أسبرين 100 ملغ' && i.quantity == 50), isTrue);

    // 3. User switches to a new Pharmacy (الجديدة)
    await storage.createHomePharmacy(
      name: 'صيدلية المنزل الجديد',
      password: '2222',
      adminName: 'أنا',
      customId: 'PHARM-NEW',
    );
    expect(storage.getActiveHomePharmacyId(), equals('PHARM-NEW'));

    // Verify:
    // A) Medicines are now present in the new pharmacy
    final newPharm = storage.getActiveHomePharmacy()!;
    expect(newPharm.items.any((i) => i.name == 'أسبرين 100 ملغ'), isTrue);

    // B) Medicines are DELETED from the old pharmacy (PHARM-OLD)
    final oldPharmUpdated = storage.getHomePharmacies().firstWhere((p) => p.id == 'PHARM-OLD');
    expect(oldPharmUpdated.items.any((i) => i.name == 'أسبرين 100 ملغ'), isFalse);

    // 4. User leaves the new pharmacy -> personal medicines deleted from PHARM-NEW
    await storage.leaveActiveHomePharmacy();
    expect(storage.getActiveHomePharmacyId(), isNull);

    final newPharmAfterLeave = storage.getHomePharmacies().firstWhere((p) => p.id == 'PHARM-NEW');
    expect(newPharmAfterLeave.items.any((i) => i.name == 'أسبرين 100 ملغ'), isFalse);
  });
}
