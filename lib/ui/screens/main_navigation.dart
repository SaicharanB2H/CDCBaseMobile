import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../data/models/company_model.dart';
import '../../data/models/event_model.dart';
import '../../data/models/student_model.dart';
import '../../services/auth_service.dart';
import '../../services/data_service.dart';
import '../../services/update_service.dart';
import '../../utils/network_util.dart';
import '../theme/app_theme.dart';
import 'auth_screen.dart';
import 'dashboard_screen.dart';
import 'events_screen.dart';
import 'profile_screen.dart';

class MainNavigation extends StatefulWidget {
  final StudentModel? initialStudent;
  final bool forceSyncOnInit;

  const MainNavigation({super.key, this.initialStudent, this.forceSyncOnInit = false});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;
  StudentModel? student;
  List<CompanyModel> companies = [];
  List<EventModel> events = [];
  bool loading = true;
  List<Widget>? _pages;
  final ScrollController _dashboardScrollController = ScrollController();
  final ScrollController _eventsScrollController = ScrollController();

  @override
  void dispose() {
    _dashboardScrollController.dispose();
    _eventsScrollController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    student = widget.initialStudent;
    _buildPages();
    _loadData(forceSync: widget.forceSyncOnInit).catchError((e) {
      debugPrint('Startup sync failed: $e');
    });
    
    // Check for app updates
    WidgetsBinding.instance.addPostFrameCallback((_) {
      UpdateService.checkForUpdates(context);
    });
  }

  void _buildPages() {
    _pages = [
      DashboardScreen(
        student: student,
        companies: companies,
        events: events,
        scrollController: _dashboardScrollController,
        isGlobalSyncing: loading,
        onRefresh: () => _loadData(forceSync: true),
      ),
      EventsScreen(
        student: student,
        events: events,
        companies: companies,
        scrollController: _eventsScrollController,
      ),
      ProfileScreen(
        student: student,
        onProfileUpdated: (updated) {
          setState(() {
            student = updated;
            _buildPages();
          });
          _loadData(forceSync: true).catchError((_) {});
        },
        onSignOut: _handleSignOut,
      ),
    ];
  }

  Future<void> _loadData({bool forceSync = false}) async {
    setState(() {
      loading = true;
      _buildPages();
    });

    try {
      final hasInternet = await NetworkUtil.hasInternet();
      if (!hasInternet) {
        if (mounted) NetworkUtil.showNoInternetDialog(context);
        // We still let it try to fetch to get cached local data if possible,
        // or we just return if forceSync was requested.
        if (forceSync) {
          setState(() => loading = false);
          return;
        }
      }

      student ??= await AuthService.getCurrentStudent();

      final fetchedCompanies = await DataService.fetchCompanies(forceSync: forceSync);
      final fetchedEvents = await DataService.fetchEvents(forceSync: forceSync);

      if (mounted) {
        setState(() {
          companies = fetchedCompanies;
          events = fetchedEvents;
          loading = false;
          _buildPages();
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          loading = false;
          _buildPages();
        });
      }
      rethrow;
    }
  }

  Future<void> _handleSignOut() async {
    await AuthService.signOut();
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const AuthScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading && student == null) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: AppTheme.primary),
        ),
      );
    }

    return Scaffold(
      body: SafeArea(
        child: IndexedStack(
          index: _currentIndex,
          children: _pages ?? [],
        ),
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: AppTheme.surface,
          border: Border(top: BorderSide(color: AppTheme.border)),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            if (_currentIndex == 0 && index == 0) {
              // Double tap on dashboard: scroll to top
              if (_dashboardScrollController.hasClients) {
                _dashboardScrollController.animateTo(
                  0,
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOut,
                );
              }
            } else if (_currentIndex == 1 && index == 1) {
              // Double tap on events: scroll to top
              if (_eventsScrollController.hasClients) {
                _eventsScrollController.animateTo(
                  0,
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOut,
                );
              }
            } else {
              setState(() => _currentIndex = index);
            }
          },
          backgroundColor: AppTheme.surface,
          selectedItemColor: AppTheme.primary,
          unselectedItemColor: AppTheme.textSecondary,
          selectedFontSize: 12,
          unselectedFontSize: 12,
          type: BottomNavigationBarType.fixed,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(LucideIcons.layoutDashboard),
              activeIcon: Icon(LucideIcons.layoutDashboard, color: AppTheme.primary),
              label: 'Dashboard',
            ),
            BottomNavigationBarItem(
              icon: Icon(LucideIcons.calendarDays),
              activeIcon: Icon(LucideIcons.calendarDays, color: AppTheme.primary),
              label: 'Calendar & Events',
            ),
            BottomNavigationBarItem(
              icon: Icon(LucideIcons.user),
              activeIcon: Icon(LucideIcons.user, color: AppTheme.primary),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}
