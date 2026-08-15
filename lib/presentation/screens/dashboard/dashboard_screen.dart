import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../logic/pet/pet_bloc.dart';
import '../../../logic/diary/diary_bloc.dart';
import '../../theme/app_theme.dart';
import 'home_tab.dart';
import '../diary/diary_screen.dart';
import '../calendar/calendar_screen.dart';
import '../settings/settings_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    // Load initial data
    context.read<PetBloc>().add(LoadPets());
    context.read<DiaryBloc>().add(const LoadDiary());
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final List<Widget> tabs = [
      HomeTab(
        onNavigateToDiary: () => _onItemTapped(1),
        onNavigateToCalendar: () => _onItemTapped(2),
      ),
      const DiaryTab(),
      const CalendarScreen(),
      const SettingsScreen(),
    ];

    return Scaffold(
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Row(
          children: [
            const Icon(Icons.pets, color: AppTheme.primary),
            const SizedBox(width: 8),
            Text(
              'Paws & Care',
              style: theme.textTheme.headlineMedium?.copyWith(
                color: AppTheme.primary,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none, color: AppTheme.secondary),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("No new notifications"),
                  backgroundColor: AppTheme.primary,
                ),
              );
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          // Use IndexedStack to preserve states of tabs
          IndexedStack(
            index: _selectedIndex,
            children: tabs,
          ),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
          ),
          child: BottomNavigationBar(
            currentIndex: _selectedIndex,
            onTap: _onItemTapped,
            type: BottomNavigationBarType.fixed,
            backgroundColor: theme.brightness == Brightness.dark
                ? AppTheme.darkSurface
                : AppTheme.surfaceContainer,
            selectedItemColor: AppTheme.primary,
            unselectedItemColor: AppTheme.onSurfaceVariant.withOpacity(0.6),
            selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
            unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 11),
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.pets),
                activeIcon: Icon(Icons.pets, color: AppTheme.primary),
                label: 'Pets',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.menu_book),
                activeIcon: Icon(Icons.menu_book, color: AppTheme.primary),
                label: 'Diary',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.calendar_today),
                activeIcon: Icon(Icons.calendar_today, color: AppTheme.primary),
                label: 'Calendar',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.settings),
                activeIcon: Icon(Icons.settings, color: AppTheme.primary),
                label: 'Settings',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
