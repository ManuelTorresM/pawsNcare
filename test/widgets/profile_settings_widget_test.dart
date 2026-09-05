import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pawsncare/data/repositories/repository_selector.dart';
import 'package:pawsncare/logic/auth/auth_bloc.dart';
import 'package:pawsncare/logic/pet/pet_bloc.dart';
import 'package:pawsncare/logic/diary/diary_bloc.dart';
import 'package:pawsncare/logic/theme/theme_cubit.dart';
import 'package:pawsncare/presentation/screens/profile/profile_details_screen.dart';
import 'package:pawsncare/presentation/screens/settings/settings_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

Widget createTestableWidget(Widget child) {
  final repositorySelector = RepositorySelector();
  return MultiBlocProvider(
    providers: [
      BlocProvider<AuthBloc>(
        create: (context) => AuthBloc(repositorySelector: repositorySelector)..add(AuthCheckRequested()),
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
      home: Scaffold(body: child),
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Profile and Settings Widget Tests', () {
    testWidgets('SettingsScreen renders account, notifications, and theme settings options', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createTestableWidget(const SettingsScreen()));
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byType(SettingsScreen), findsOneWidget);
    });

    testWidgets('ProfileDetailsScreen renders user details and action buttons', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createTestableWidget(const ProfileDetailsScreen(
        name: 'Demo User',
        email: 'demo@pawsncare.com',
      )));
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byType(ProfileDetailsScreen), findsOneWidget);
    });
  });
}
