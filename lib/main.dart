import 'package:flutter/material.dart';

import 'services/storage_service.dart';
import 'services/reminder_service.dart';
import 'services/system_notification_service.dart';
import 'services/medical_time_service.dart';
import 'theme/app_theme.dart';
import 'screens/home_screen.dart';
import 'ar.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await MedicalTimeService.init();
  final storageService = await StorageService.init();
  final reminderService = ReminderService(storageService);
  
  await SystemNotificationService.init(
    onNotificationAction: (payload) {
      reminderService.handleNotificationDoseConfirmation(payload);
    },
  );

  runApp(
    DawaaiApp(storageService: storageService, reminderService: reminderService),
  );
}

class DawaaiApp extends StatefulWidget {
  final StorageService storageService;
  final ReminderService reminderService;

  const DawaaiApp({
    super.key,
    required this.storageService,
    required this.reminderService,
  });

  @override
  State<DawaaiApp> createState() => _DawaaiAppState();
}

class _DawaaiAppState extends State<DawaaiApp> {
  late bool _isDarkMode;

  @override
  void initState() {
    super.initState();
    _isDarkMode = widget.storageService.isDarkMode();
  }

  void _toggleDarkMode() async {
    setState(() {
      _isDarkMode = !_isDarkMode;
    });
    await widget.storageService.setDarkMode(_isDarkMode);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: Ar.appFullName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme(),
      darkTheme: AppTheme.darkTheme(),
      themeMode: _isDarkMode ? ThemeMode.dark : ThemeMode.light,
      home: HomeScreen(
        storageService: widget.storageService,
        reminderService: widget.reminderService,
        onToggleTheme: _toggleDarkMode,
        isDarkMode: _isDarkMode,
      ),
    );
  }
}
