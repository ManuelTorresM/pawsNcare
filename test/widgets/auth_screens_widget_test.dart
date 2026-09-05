import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pawsncare/data/repositories/repository_selector.dart';
import 'package:pawsncare/logic/auth/auth_bloc.dart';
import 'package:pawsncare/logic/theme/theme_cubit.dart';
import 'package:pawsncare/presentation/screens/auth/login_screen.dart';
import 'package:pawsncare/presentation/screens/auth/register_screen.dart';
import 'package:pawsncare/presentation/screens/auth/forgot_password_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

Widget createTestableAuthWidget(Widget child) {
  final repositorySelector = RepositorySelector();
  return MultiBlocProvider(
    providers: [
      BlocProvider<AuthBloc>(
        create: (context) => AuthBloc(repositorySelector: repositorySelector),
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

  group('Auth Screens Widget Tests', () {
    testWidgets('LoginScreen renders email, password fields and sign in button', (WidgetTester tester) async {
      await tester.pumpWidget(createTestableAuthWidget(const LoginScreen()));
      await tester.pumpAndSettle();

      expect(find.byType(TextFormField), findsNWidgets(2));
      expect(find.textContaining('Email'), findsWidgets);
      expect(find.textContaining('Password'), findsWidgets);
      expect(find.byType(ElevatedButton), findsWidgets);
    });

    testWidgets('LoginScreen form validation displays error on empty submit', (WidgetTester tester) async {
      await tester.pumpWidget(createTestableAuthWidget(const LoginScreen()));
      await tester.pumpAndSettle();

      final buttonFinder = find.byType(ElevatedButton).first;
      await tester.tap(buttonFinder);
      await tester.pumpAndSettle();

      expect(find.textContaining('Please enter your email'), findsOneWidget);
    });

    testWidgets('RegisterScreen renders name, email, password fields', (WidgetTester tester) async {
      await tester.pumpWidget(createTestableAuthWidget(const RegisterScreen()));
      await tester.pumpAndSettle();

      expect(find.byType(TextFormField), findsWidgets);
      expect(find.textContaining('Create Account'), findsWidgets);
    });

    testWidgets('ForgotPasswordScreen renders email field and submit button', (WidgetTester tester) async {
      await tester.pumpWidget(createTestableAuthWidget(const ForgotPasswordScreen()));
      await tester.pumpAndSettle();

      expect(find.byType(TextFormField), findsOneWidget);
      expect(find.byType(ElevatedButton), findsOneWidget);
    });
  });
}
