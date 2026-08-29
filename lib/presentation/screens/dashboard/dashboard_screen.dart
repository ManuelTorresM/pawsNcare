import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../logic/pet/pet_bloc.dart';
import '../../../logic/diary/diary_bloc.dart';
import '../../../logic/notifications/global_notification_service.dart';
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

  final List<GlobalKey<NavigatorState>> _navigatorKeys = [
    GlobalKey<NavigatorState>(),
    GlobalKey<NavigatorState>(),
    GlobalKey<NavigatorState>(),
    GlobalKey<NavigatorState>(),
  ];

  late final List<_NestedNavigatorObserver> _observers;

  @override
  void initState() {
    super.initState();
    _observers = List.generate(
      4,
      (index) => _NestedNavigatorObserver(() {
        if (mounted) {
          setState(() {});
        }
      }),
    );
    // Load initial data
    context.read<PetBloc>().add(LoadPets());
    context.read<DiaryBloc>().add(const LoadDiary());
  }

  void _onItemTapped(int index) {
    if (_selectedIndex == index) {
      // If tapping the already selected tab, pop all nested routes back to root
      _navigatorKeys[index].currentState?.popUntil((route) => route.isFirst);
    } else {
      setState(() {
        _selectedIndex = index;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final bool showAppBar = _navigatorKeys[_selectedIndex].currentState == null ||
        !_navigatorKeys[_selectedIndex].currentState!.canPop();

    final List<Widget> tabs = [
      Navigator(
        key: _navigatorKeys[0],
        observers: [_observers[0]],
        onGenerateRoute: (settings) => MaterialPageRoute(
          builder: (context) => HomeTab(
            onNavigateToDiary: () => _onItemTapped(1),
            onNavigateToCalendar: () => _onItemTapped(2),
          ),
        ),
      ),
      Navigator(
        key: _navigatorKeys[1],
        observers: [_observers[1]],
        onGenerateRoute: (settings) => MaterialPageRoute(
          builder: (context) => const DiaryTab(),
        ),
      ),
      Navigator(
        key: _navigatorKeys[2],
        observers: [_observers[2]],
        onGenerateRoute: (settings) => MaterialPageRoute(
          builder: (context) => const CalendarScreen(),
        ),
      ),
      Navigator(
        key: _navigatorKeys[3],
        observers: [_observers[3]],
        onGenerateRoute: (settings) => MaterialPageRoute(
          builder: (context) => const SettingsScreen(),
        ),
      ),
    ];

    final bool canPopNested = _navigatorKeys[_selectedIndex].currentState?.canPop() ?? false;

    return PopScope(
      canPop: !canPopNested,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _navigatorKeys[_selectedIndex].currentState?.pop();
      },
      child: Scaffold(
        appBar: showAppBar
            ? AppBar(
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
                  ListenableBuilder(
                    listenable: GlobalNotificationService(),
                    builder: (context, _) {
                      final unread = GlobalNotificationService().unreadCount;
                      return Stack(
                        alignment: Alignment.center,
                        children: [
                          IconButton(
                            icon: const Icon(
                              Icons.notifications_none,
                              color: AppTheme.primary,
                            ),
                            onPressed: () => GlobalNotificationService()
                                .showNotificationCenter(context),
                          ),
                          if (unread > 0)
                            Positioned(
                              right: 8,
                              top: 8,
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(
                                  color: AppTheme.tertiary,
                                  shape: BoxShape.circle,
                                ),
                                constraints: const BoxConstraints(
                                  minWidth: 16,
                                  minHeight: 16,
                                ),
                                child: Text(
                                  '$unread',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                        ],
                      );
                    },
                  ),
                ],
              )
            : null,
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
                color: Colors.black.withValues(alpha: 0.04),
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
              unselectedItemColor: AppTheme.onSurfaceVariant.withValues(alpha: 0.6),
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
      ),
    );
  }
}

class _NestedNavigatorObserver extends NavigatorObserver {
  final VoidCallback onNavigationChanged;
  _NestedNavigatorObserver(this.onNavigationChanged);

  @override
  void didPush(Route route, Route? previousRoute) {
    super.didPush(route, previousRoute);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      onNavigationChanged();
    });
  }

  @override
  void didPop(Route route, Route? previousRoute) {
    super.didPop(route, previousRoute);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      onNavigationChanged();
    });
  }

  @override
  void didRemove(Route route, Route? previousRoute) {
    super.didRemove(route, previousRoute);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      onNavigationChanged();
    });
  }

  @override
  void didReplace({Route? newRoute, Route? oldRoute}) {
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      onNavigationChanged();
    });
  }
}
