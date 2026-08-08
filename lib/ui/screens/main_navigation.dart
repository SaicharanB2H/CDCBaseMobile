import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../data/models/company_model.dart';
import '../../data/models/event_model.dart';
import '../../data/models/student_model.dart';
import '../../services/auth_service.dart';
import '../../services/data_service.dart';
import '../theme/app_theme.dart';
import 'auth_screen.dart';
import 'dashboard_screen.dart';
import 'events_screen.dart';
import 'profile_screen.dart';

class MainNavigation extends StatefulWidget {
  final StudentModel? initialStudent;

  const MainNavigation({super.key, this.initialStudent});

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

  @override
  void initState() {
    super.initState();
    student = widget.initialStudent;
    _buildPages();
    _loadData().catchError((e) {
      debugPrint('Startup load failed: $e');
    });
  }

  void _buildPages() {
    _pages = [
      DashboardScreen(
        student: student,
        companies: companies,
        events: events,
        onRefresh: () => _loadData(forceSync: true),
      ),
      EventsScreen(
        student: student,
        events: events,
        companies: companies,
      ),
      ProfileScreen(
        student: student,
        onProfileUpdated: (updated) {
          setState(() {
            student = updated;
            _buildPages();
          });
        },
        onSignOut: _handleSignOut,
      ),
    ];
  }

  Future<void> _loadData({bool forceSync = false}) async {
    setState(() {
      loading = true;
    });

    try {
      student ??= await AuthService.getCurrentStudent();

      final fetchedCompanies = await DataService.fetchCompanies(forceSync: forceSync);
      final fetchedEvents = await DataService.fetchEvents(forceSync: forceSync);

      if (mounted) {
        setState(() {
          companies = fetchedCompanies;
          events = fetchedEvents;
          _buildPages();
          loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          loading = false;
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
          onTap: (index) => setState(() => _currentIndex = index),
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
              label: 'Events & Calendar',
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
