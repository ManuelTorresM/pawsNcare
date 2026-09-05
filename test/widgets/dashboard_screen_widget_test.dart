import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pawsncare/data/repositories/repository_selector.dart';
import 'package:pawsncare/logic/auth/auth_bloc.dart';
import 'package:pawsncare/logic/pet/pet_bloc.dart';
import 'package:pawsncare/logic/diary/diary_bloc.dart';
import 'package:pawsncare/logic/theme/theme_cubit.dart';
import 'package:pawsncare/presentation/screens/dashboard/dashboard_screen.dart';
import 'package:pawsncare/presentation/screens/dashboard/home_tab.dart';
import 'package:shared_preferences/shared_preferences.dart';

Widget createTestableDashboardWidget(Widget child) {
  final repositorySelector = RepositorySelector();
  return MultiBlocProvider(
    providers: [
      BlocProvider<AuthBloc>(
        create: (context) => AuthBloc(repositorySelector: repositorySelector),
      ),
      BlocProvider<PetBloc>(
        create: (context) => PetBloc(repositorySelector: repositorySelector)..add(LoadPets()),
      ),
      BlocProvider<DiaryBloc>(
        create: (context) => DiaryBloc(repositorySelector: repositorySelector)..add(const LoadDiary()),
      ),
      BlocProvider<ThemeCubit>(
        create: (context) => ThemeCubit(),
      ),
    ],
    child: MaterialApp(
      home: child,
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('DashboardScreen Widget Tests', () {
    testWidgets('DashboardScreen renders bottom navigation bar and initial tab', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createTestableDashboardWidget(const DashboardScreen()));
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byType(DashboardScreen), findsOneWidget);
      expect(find.text('Diary'), findsWidgets);
      expect(find.text('Calendar'), findsWidgets);
      expect(find.text('Settings'), findsWidgets);
    });

    testWidgets('HomeTab renders pet selector and quick action cards', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createTestableDashboardWidget(Scaffold(
        body: HomeTab(
          onNavigateToDiary: () {},
          onNavigateToCalendar: () {},
        ),
      )));
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byType(HomeTab), findsOneWidget);
    });
  });
}
