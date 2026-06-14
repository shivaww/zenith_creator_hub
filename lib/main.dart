import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'theme.dart';
import 'providers/providers.dart';
import 'services/storage_service.dart';
import 'services/notification_service.dart';
import 'screens/home_dashboard.dart';
import 'screens/project_manager.dart';
import 'screens/schedule_alarms.dart';
import 'screens/earnings_tracker.dart';
import 'screens/quick_notes.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  SharedPreferences? prefs;
  StorageService? storageService;
  NotificationService? notificationService;

  try {
    prefs = await SharedPreferences.getInstance();
    storageService = StorageService(prefs);
    await storageService.seedIfEmpty(); 
    
    notificationService = NotificationService();
    await notificationService.init();
  } catch (e) {
    // If initialization fails, we proceed with fallback values if possible
    // or just let Riverpod handle the UnimplementedErrors later.
  }

  runApp(
    ProviderScope(
      overrides: [
        if (prefs != null) sharedPreferencesProvider.overrideWithValue(prefs),
        if (storageService != null) storageServiceProvider.overrideWithValue(storageService),
        if (notificationService != null) notificationServiceProvider.overrideWithValue(notificationService),
      ],
      child: const ZenithApp(),
    ),
  );
}

class ZenithApp extends ConsumerWidget {
  const ZenithApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = ref.watch(themeModeProvider);

    return MaterialApp(
      title: 'Zenith Creator Hub',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: isDark ? ThemeMode.dark : ThemeMode.light,
      home: const MainLayout(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class MainLayout extends ConsumerStatefulWidget {
  const MainLayout({super.key});

  @override
  ConsumerState<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends ConsumerState<MainLayout> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    const HomeDashboard(),
    const ProjectManager(),
    const ScheduleAlarms(),
    const EarningsTracker(),
    const QuickNotes(),
  ];

  @override
  void initState() {
    super.initState();
    // Ask for permissions on first launch
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(notificationServiceProvider).requestPermissions();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isTablet = MediaQuery.of(context).size.width > 600;

    if (isTablet) {
      return Scaffold(
        body: Row(
          children: [
            NavigationRail(
              selectedIndex: _currentIndex,
              onDestinationSelected: (int index) {
                setState(() {
                  _currentIndex = index;
                });
              },
              labelType: NavigationRailLabelType.all,
              destinations: const [
                NavigationRailDestination(icon: Icon(Icons.dashboard), label: Text('Home')),
                NavigationRailDestination(icon: Icon(Icons.folder_special), label: Text('Projects')),
                NavigationRailDestination(icon: Icon(Icons.schedule), label: Text('Schedule')),
                NavigationRailDestination(icon: Icon(Icons.currency_rupee), label: Text('Earnings')),
                NavigationRailDestination(icon: Icon(Icons.note), label: Text('Notes')),
              ],
            ),
            const VerticalDivider(thickness: 1, width: 1),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: _pages[_currentIndex],
              ),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: _pages[_currentIndex],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.folder_special), label: 'Projects'),
          BottomNavigationBarItem(icon: Icon(Icons.schedule), label: 'Schedule'),
          BottomNavigationBarItem(icon: Icon(Icons.currency_rupee), label: 'Earnings'),
          BottomNavigationBarItem(icon: Icon(Icons.note), label: 'Notes'),
        ],
      ),
    );
  }
}
