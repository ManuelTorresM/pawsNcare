import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pawsncare/data/models/pet.dart';
import 'package:pawsncare/data/repositories/base_repository.dart';
import 'package:pawsncare/data/repositories/repository_selector.dart';
import 'package:pawsncare/logic/pet/pet_bloc.dart';

import 'package:shared_preferences/shared_preferences.dart';

class MockRepositorySelector extends Mock implements RepositorySelector {}
class MockBaseRepository extends Mock implements BaseRepository {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late MockRepositorySelector mockRepositorySelector;
  late MockBaseRepository mockRepository;

  final samplePet = Pet(
    id: 'p1',
    name: 'Max',
    breed: 'Beagle',
    ageString: '1y',
    birthDate: DateTime(2025, 1, 1),
    avatarUrl: 'https://example.com/max.jpg',
    status: 'Healthy',
    weight: 12.0,
  );

  setUpAll(() {
    registerFallbackValue(samplePet);
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    mockRepositorySelector = MockRepositorySelector();
    mockRepository = MockBaseRepository();
    when(() => mockRepositorySelector.getActiveRepository())
        .thenAnswer((_) async => mockRepository);
  });

  group('PetBloc Unit Tests', () {
    test('initial state is PetInitial', () {
      expect(PetBloc(repositorySelector: mockRepositorySelector).state, equals(PetInitial()));
    });

    blocTest<PetBloc, PetState>(
      'emits [PetLoading, PetLoaded] when LoadPets succeeds',
      build: () {
        when(() => mockRepository.getPets()).thenAnswer((_) async => [samplePet]);
        return PetBloc(repositorySelector: mockRepositorySelector);
      },
      act: (bloc) => bloc.add(LoadPets()),
      expect: () => [
        PetLoading(),
        PetLoaded(pets: [samplePet], filteredPets: [samplePet]),
      ],
    );

    blocTest<PetBloc, PetState>(
      'emits [PetLoading, PetError] when LoadPets throws an exception',
      build: () {
        when(() => mockRepository.getPets()).thenThrow(Exception('Failed to load pets'));
        return PetBloc(repositorySelector: mockRepositorySelector);
      },
      act: (bloc) => bloc.add(LoadPets()),
      expect: () => [
        PetLoading(),
        const PetError('Exception: Failed to load pets'),
      ],
    );

    blocTest<PetBloc, PetState>(
      'emits [PetLoaded] when AddPet is called',
      build: () {
        when(() => mockRepository.addPet(any())).thenAnswer((_) async {});
        when(() => mockRepository.getPets()).thenAnswer((_) async => [samplePet]);
        return PetBloc(repositorySelector: mockRepositorySelector);
      },
      act: (bloc) => bloc.add(AddPet(samplePet)),
      expect: () => [
        PetLoaded(pets: [samplePet], filteredPets: [samplePet]),
      ],
    );

    blocTest<PetBloc, PetState>(
      'emits [PetLoaded] when DeletePet is called',
      build: () {
        when(() => mockRepository.deletePet('p1')).thenAnswer((_) async {});
        when(() => mockRepository.getPets()).thenAnswer((_) async => []);
        return PetBloc(repositorySelector: mockRepositorySelector);
      },
      act: (bloc) => bloc.add(const DeletePet('p1')),
      expect: () => [
        const PetLoaded(pets: [], filteredPets: []),
      ],
    );

    blocTest<PetBloc, PetState>(
      'SearchPets filters loaded pets by query correctly',
      build: () => PetBloc(repositorySelector: mockRepositorySelector),
      seed: () => PetLoaded(
        pets: [samplePet, samplePet.copyWith(id: 'p2', name: 'Luna', breed: 'Poodle')],
        filteredPets: [samplePet, samplePet.copyWith(id: 'p2', name: 'Luna', breed: 'Poodle')],
      ),
      act: (bloc) => bloc.add(const SearchPets('Luna')),
      expect: () => [
        PetLoaded(
          pets: [samplePet, samplePet.copyWith(id: 'p2', name: 'Luna', breed: 'Poodle')],
          filteredPets: [samplePet.copyWith(id: 'p2', name: 'Luna', breed: 'Poodle')],
          searchQuery: 'Luna',
        ),
      ],
    );
  });
}
