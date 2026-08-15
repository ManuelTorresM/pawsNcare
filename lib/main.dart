import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_core/firebase_core.dart';
import 'data/repositories/repository_selector.dart';
import 'logic/auth/auth_bloc.dart';
import 'logic/pet/pet_bloc.dart';
import 'logic/diary/diary_bloc.dart';
import 'logic/theme/theme_cubit.dart';
import 'presentation/theme/app_theme.dart';
import 'presentation/screens/auth/login_screen.dart';
import 'presentation/screens/dashboard/dashboard_screen.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Try to initialize Firebase using local configurations.
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint("Firebase initialization failed/skipped: $e");
    // Ensure we force local mock mode if Firebase is not configured yet
    final dbSource = await RepositorySelector.getDbSource();
    if (dbSource == 'firebase') {
      await RepositorySelector.setDbSource('mock');
    }
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final repositorySelector = RepositorySelector();

    return MultiBlocProvider(
      providers: [
        BlocProvider<ThemeCubit>(create: (_) => ThemeCubit()),
        BlocProvider<AuthBloc>(
          create: (_) =>
              AuthBloc(repositorySelector: repositorySelector)
                ..add(AuthCheckRequested()),
        ),
        BlocProvider<PetBloc>(
          create: (_) => PetBloc(repositorySelector: repositorySelector),
        ),
        BlocProvider<DiaryBloc>(
          create: (_) => DiaryBloc(repositorySelector: repositorySelector),
        ),
      ],
      child: BlocBuilder<ThemeCubit, bool>(
        builder: (context, isDarkMode) {
          return MaterialApp(
            title: 'Paws & Care',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: isDarkMode ? ThemeMode.dark : ThemeMode.light,
            home: BlocBuilder<AuthBloc, AuthState>(
              builder: (context, state) {
                if (state is Authenticated) {
                  return const DashboardScreen();
                } else if (state is Unauthenticated) {
                  return const LoginScreen();
                } else if (state is AuthLoading || state is AuthInitial) {
                  return const Scaffold(
                    body: Center(
                      child: CircularProgressIndicator(color: AppTheme.primary),
                    ),
                  );
                } else {
                  return const LoginScreen();
                }
              },
            ),
          );
        },
      ),
    );
  }
}
