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

import 'presentation/widgets/global_notification_overlay.dart';
import 'logic/notifications/global_notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await RepositorySelector.setDbSource('firebase');
  await GlobalNotificationService().init();

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late final RepositorySelector _repositorySelector;
  late final ThemeCubit _themeCubit;
  late final AuthBloc _authBloc;
  late final PetBloc _petBloc;
  late final DiaryBloc _diaryBloc;

  @override
  void initState() {
    super.initState();
    _repositorySelector = RepositorySelector();
    _themeCubit = ThemeCubit();
    _authBloc = AuthBloc(repositorySelector: _repositorySelector)
      ..add(AuthCheckRequested());
    _petBloc = PetBloc(repositorySelector: _repositorySelector);
    _diaryBloc = DiaryBloc(repositorySelector: _repositorySelector);

    _petBloc.stream.listen((state) {
      if (state is PetLoaded) {
        GlobalNotificationService().syncPetEvents(state.pets);
      }
    });
  }

  @override
  void dispose() {
    _themeCubit.close();
    _authBloc.close();
    _petBloc.close();
    _diaryBloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<ThemeCubit>.value(value: _themeCubit),
        BlocProvider<AuthBloc>.value(value: _authBloc),
        BlocProvider<PetBloc>.value(value: _petBloc),
        BlocProvider<DiaryBloc>.value(value: _diaryBloc),
      ],
      child: BlocBuilder<ThemeCubit, bool>(
        builder: (context, isDarkMode) {
          return MaterialApp(
            title: 'Paws & Care',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: isDarkMode ? ThemeMode.dark : ThemeMode.light,
            builder: (context, child) {
              return GlobalNotificationOverlay(
                child: child ?? const SizedBox.shrink(),
              );
            },
            home: BlocBuilder<AuthBloc, AuthState>(
              builder: (context, state) {
                if (state is Authenticated) {
                  return const DashboardScreen();
                }
                return const LoginScreen();
              },
            ),
          );
        },
      ),
    );
  }
}
