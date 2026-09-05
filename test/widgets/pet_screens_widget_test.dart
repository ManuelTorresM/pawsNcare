import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pawsncare/data/models/pet.dart';
import 'package:pawsncare/data/repositories/repository_selector.dart';
import 'package:pawsncare/logic/auth/auth_bloc.dart';
import 'package:pawsncare/logic/pet/pet_bloc.dart';
import 'package:pawsncare/logic/diary/diary_bloc.dart';
import 'package:pawsncare/logic/theme/theme_cubit.dart';
import 'package:pawsncare/presentation/screens/pet/add_pet_wizard.dart';
import 'package:pawsncare/presentation/screens/pet/create_pet_step1.dart';
import 'package:pawsncare/presentation/screens/pet/pet_details_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

Widget createTestableWidget(Widget child) {
  final repositorySelector = RepositorySelector();
  return MultiBlocProvider(
    providers: [
      BlocProvider<AuthBloc>(
        create: (context) => AuthBloc(repositorySelector: repositorySelector),
      ),
      BlocProvider<PetBloc>(
        create: (context) =>
            PetBloc(repositorySelector: repositorySelector)..add(LoadPets()),
      ),
      BlocProvider<DiaryBloc>(
        create: (context) =>
            DiaryBloc(repositorySelector: repositorySelector)
              ..add(const LoadDiary()),
      ),
      BlocProvider<ThemeCubit>(create: (context) => ThemeCubit()),
    ],
    child: MaterialApp(home: child),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Pet Screens Widget Tests', () {
    testWidgets('AddPetWizard renders multi-step form wizard', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createTestableWidget(const AddPetWizard()));
      await tester.pumpAndSettle();

      expect(find.byType(AddPetWizard), findsOneWidget);
    });

    testWidgets('CreatePetStep1 renders basic info fields', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final nameCtrl = TextEditingController();
      final breedCtrl = TextEditingController();

      await tester.pumpWidget(
        createTestableWidget(
          Scaffold(
            body: CreatePetStep1(
              nameController: nameCtrl,
              breedController: breedCtrl,
              selectedSpecies: 'Dog',
              onSpeciesChanged: (_) {},
              selectedGender: 'Female',
              onGenderChanged: (_) {},
              selectedNeutered: 'Yes',
              onNeuteredChanged: (_) {},
              birthDate: DateTime(2024, 1, 1),
              onBirthDateChanged: (_) {},
              selectedAvatar: '',
              onPhotoSelectorPressed: () {},
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byType(CreatePetStep1), findsOneWidget);
      expect(find.byType(TextField), findsWidgets);
    });

    testWidgets('PetDetailsScreen renders pet information and action options', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final samplePet = Pet(
        id: 'p1',
        name: 'Luna',
        breed: 'Golden Retriever',
        ageString: '3y',
        birthDate: DateTime(2023, 1, 1),
        avatarUrl: '',
        status: 'Healthy',
        weight: 28.0,
      );

      await tester.pumpWidget(
        createTestableWidget(PetDetailsScreen(pet: samplePet)),
      );
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.textContaining('Luna'), findsWidgets);
      expect(find.textContaining('Golden Retriever'), findsWidgets);
    });
  });
}
