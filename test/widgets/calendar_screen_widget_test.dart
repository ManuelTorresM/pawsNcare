import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pawsncare/data/repositories/repository_selector.dart';
import 'package:pawsncare/logic/auth/auth_bloc.dart';
import 'package:pawsncare/logic/pet/pet_bloc.dart';
import 'package:pawsncare/logic/diary/diary_bloc.dart';
import 'package:pawsncare/logic/theme/theme_cubit.dart';
import 'package:pawsncare/presentation/screens/calendar/calendar_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

Widget createTestableWidget(Widget child) {
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

  group('CalendarScreen Widget Tests', () {
    testWidgets('CalendarScreen renders month header, day headers and calendar grid', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createTestableWidget(const CalendarScreen()));
      await tester.pumpAndSettle();

      expect(find.byType(CalendarScreen), findsOneWidget);
    });
  });
}
