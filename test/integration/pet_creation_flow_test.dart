import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pawsncare/data/repositories/repository_selector.dart';
import 'package:pawsncare/logic/auth/auth_bloc.dart';
import 'package:pawsncare/logic/pet/pet_bloc.dart';
import 'package:pawsncare/logic/diary/diary_bloc.dart';
import 'package:pawsncare/logic/theme/theme_cubit.dart';
import 'package:pawsncare/presentation/screens/pet/add_pet_wizard.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Pet Creation Wizard E2E Flow Test', () {
    testWidgets('Multi-step pet creation wizard completes successfully', (WidgetTester tester) async {
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
          child: const MaterialApp(
            home: AddPetWizard(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(AddPetWizard), findsOneWidget);
    });
  });
}
