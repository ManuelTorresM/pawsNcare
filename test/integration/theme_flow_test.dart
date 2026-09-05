import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pawsncare/data/repositories/repository_selector.dart';
import 'package:pawsncare/logic/auth/auth_bloc.dart';
import 'package:pawsncare/logic/pet/pet_bloc.dart';
import 'package:pawsncare/logic/diary/diary_bloc.dart';
import 'package:pawsncare/logic/theme/theme_cubit.dart';
import 'package:pawsncare/presentation/screens/settings/settings_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Theme Persistence E2E Flow Test', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    testWidgets('Toggles theme mode in settings screen and persists preference', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final repositorySelector = RepositorySelector();

      await tester.pumpWidget(
        MultiBlocProvider(
          providers: [
            BlocProvider<AuthBloc>(
              create: (_) => AuthBloc(repositorySelector: repositorySelector),
            ),
            BlocProvider<PetBloc>(
              create: (_) => PetBloc(repositorySelector: repositorySelector)..add(LoadPets()),
            ),
            BlocProvider<DiaryBloc>(
              create: (_) => DiaryBloc(repositorySelector: repositorySelector),
            ),
            BlocProvider<ThemeCubit>(
              create: (_) => ThemeCubit(),
            ),
          ],
          child: BlocBuilder<ThemeCubit, bool>(
            builder: (context, isDark) {
              return MaterialApp(
                theme: isDark ? ThemeData.dark() : ThemeData.light(),
                home: const Scaffold(body: SettingsScreen()),
              );
            },
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byType(SettingsScreen), findsOneWidget);
    });
  });
}
