import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pawsncare/data/repositories/demo_repository.dart';
import 'package:pawsncare/data/repositories/repository_selector.dart';
import 'package:pawsncare/logic/auth/auth_bloc.dart';
import 'package:pawsncare/logic/pet/pet_bloc.dart';
import 'package:pawsncare/logic/diary/diary_bloc.dart';
import 'package:pawsncare/logic/theme/theme_cubit.dart';
import 'package:pawsncare/presentation/screens/auth/login_screen.dart';
import 'package:pawsncare/presentation/screens/dashboard/dashboard_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Authentication E2E Flow Integration Test', () {
    late DemoRepository demoRepo;
    late RepositorySelector repositorySelector;

    setUp(() {
      demoRepo = DemoRepository();
      repositorySelector = RepositorySelector();
    });

    testWidgets('User registration and login flow end-to-end', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      await tester.pumpWidget(
        MultiBlocProvider(
          providers: [
            BlocProvider<AuthBloc>(
              create: (_) => AuthBloc(repositorySelector: repositorySelector)..add(AuthCheckRequested()),
            ),
            BlocProvider<PetBloc>(
              create: (_) => PetBloc(repositorySelector: repositorySelector),
            ),
            BlocProvider<DiaryBloc>(
              create: (_) => DiaryBloc(repositorySelector: repositorySelector),
            ),
            BlocProvider<ThemeCubit>(
              create: (_) => ThemeCubit(),
            ),
          ],
          child: MaterialApp(
            home: BlocBuilder<AuthBloc, AuthState>(
              builder: (context, state) {
                if (state is Authenticated) {
                  return const DashboardScreen();
                }
                return const LoginScreen();
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify LoginScreen is shown initially
      expect(find.byType(LoginScreen), findsOneWidget);

      // Fill in demo credentials
      final emailFields = find.byType(TextFormField);
      expect(emailFields, findsNWidgets(2));

      await tester.enterText(emailFields.first, 'demo@pawsncare.com');
      await tester.enterText(emailFields.last, 'demo1234');
      await tester.pumpAndSettle();

      // Tap Sign In button
      final signInBtn = find.byType(ElevatedButton).first;
      await tester.tap(signInBtn, warnIfMissed: false);
      await tester.pumpAndSettle();
    });
  });
}
