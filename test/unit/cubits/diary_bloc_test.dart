import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pawsncare/data/models/diary_entry.dart';
import 'package:pawsncare/data/repositories/base_repository.dart';
import 'package:pawsncare/data/repositories/repository_selector.dart';
import 'package:pawsncare/logic/diary/diary_bloc.dart';

class MockRepositorySelector extends Mock implements RepositorySelector {}
class MockBaseRepository extends Mock implements BaseRepository {}

void main() {
  late MockRepositorySelector mockRepositorySelector;
  late MockBaseRepository mockRepository;

  final sampleEntry = DiaryEntry(
    id: 'd1',
    petId: 'p1',
    title: 'Vet Visit',
    category: 'vet',
    note: 'Annual checkup.',
    timestamp: DateTime(2026, 1, 1),
  );

  setUpAll(() {
    registerFallbackValue(sampleEntry);
  });

  setUp(() {
    mockRepositorySelector = MockRepositorySelector();
    mockRepository = MockBaseRepository();
    when(() => mockRepositorySelector.getActiveRepository())
        .thenAnswer((_) async => mockRepository);
  });

  group('DiaryBloc Unit Tests', () {
    test('initial state is DiaryInitial', () {
      expect(DiaryBloc(repositorySelector: mockRepositorySelector).state, equals(DiaryInitial()));
    });

    blocTest<DiaryBloc, DiaryState>(
      'emits [DiaryLoading, DiaryLoaded] when LoadDiary without petId succeeds',
      build: () {
        when(() => mockRepository.getAllDiaryEntries()).thenAnswer((_) async => [sampleEntry]);
        return DiaryBloc(repositorySelector: mockRepositorySelector);
      },
      act: (bloc) => bloc.add(const LoadDiary()),
      expect: () => [
        DiaryLoading(),
        DiaryLoaded([sampleEntry]),
      ],
    );

    blocTest<DiaryBloc, DiaryState>(
      'emits [DiaryLoading, DiaryLoaded] when LoadDiary with petId succeeds',
      build: () {
        when(() => mockRepository.getDiaryEntries('p1')).thenAnswer((_) async => [sampleEntry]);
        return DiaryBloc(repositorySelector: mockRepositorySelector);
      },
      act: (bloc) => bloc.add(const LoadDiary(petId: 'p1')),
      expect: () => [
        DiaryLoading(),
        DiaryLoaded([sampleEntry]),
      ],
    );

    blocTest<DiaryBloc, DiaryState>(
      'emits [DiaryLoaded] when AddDiaryEntryEvent completes',
      build: () {
        when(() => mockRepository.addDiaryEntry(any())).thenAnswer((_) async {});
        when(() => mockRepository.getDiaryEntries('p1')).thenAnswer((_) async => [sampleEntry]);
        return DiaryBloc(repositorySelector: mockRepositorySelector);
      },
      act: (bloc) => bloc.add(AddDiaryEntryEvent(sampleEntry)),
      expect: () => [
        DiaryLoaded([sampleEntry]),
      ],
    );

    blocTest<DiaryBloc, DiaryState>(
      'emits [DiaryLoaded] when DeleteDiaryEntryEvent completes',
      build: () {
        when(() => mockRepository.deleteDiaryEntry('d1')).thenAnswer((_) async {});
        when(() => mockRepository.getDiaryEntries('p1')).thenAnswer((_) async => []);
        return DiaryBloc(repositorySelector: mockRepositorySelector);
      },
      act: (bloc) => bloc.add(const DeleteDiaryEntryEvent('d1', currentPetId: 'p1')),
      expect: () => [
        const DiaryLoaded([]),
      ],
    );
  });
}
