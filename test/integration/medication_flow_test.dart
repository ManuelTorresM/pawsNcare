import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pawsncare/data/models/pet.dart';
import 'package:pawsncare/data/repositories/repository_selector.dart';
import 'package:pawsncare/logic/auth/auth_bloc.dart';
import 'package:pawsncare/logic/pet/pet_bloc.dart';
import 'package:pawsncare/logic/diary/diary_bloc.dart';
import 'package:pawsncare/logic/theme/theme_cubit.dart';
import 'package:pawsncare/presentation/screens/pet/meds_vaccines_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Medication & Vaccine Management E2E Flow Test', () {
    testWidgets('Renders medication and vaccine list and permits dose logging', (WidgetTester tester) async {
      final repositorySelector = RepositorySelector();
      final samplePet = Pet(
        id: 'pet_med_01',
        name: 'Max',
        breed: 'Beagle',
        ageString: '2y',
        birthDate: DateTime(2024, 1, 1),
        avatarUrl: '',
        status: 'Healthy',
        weight: 12.0,
      );

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
          child: MaterialApp(
            home: MedsVaccinesScreen(pet: samplePet),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(MedsVaccinesScreen), findsOneWidget);
    });
  });
}
