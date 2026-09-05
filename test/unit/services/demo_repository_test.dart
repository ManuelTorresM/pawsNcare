import 'package:flutter_test/flutter_test.dart';
import 'package:pawsncare/data/repositories/demo_repository.dart';
import 'package:pawsncare/data/models/pet.dart';
import 'package:pawsncare/data/models/diary_entry.dart';

void main() {
  late DemoRepository demoRepo;

  setUp(() {
    demoRepo = DemoRepository();
  });

  group('DemoRepository Unit Tests', () {
    test('login succeeds for demo account and fails for unregistered email', () async {
      final success = await demoRepo.login('demo@pawsncare.com', 'demo1234');
      expect(success, isTrue);

      expect(
        () async => await demoRepo.login('unregistered@mail.com', 'pass'),
        throwsA(isA<Exception>()),
      );
    });

    test('register adds email to registered list', () async {
      await demoRepo.register('newuser@pawsncare.com', 'demo1234', 'New User');
      final success = await demoRepo.login('newuser@pawsncare.com', 'demo1234');
      expect(success, isTrue);
    });

    test('isLoggedIn, getCurrentUserEmail, and getCurrentUserName return default demo info', () async {
      expect(await demoRepo.isLoggedIn(), isTrue);
      expect(await demoRepo.getCurrentUserEmail(), 'demo@pawsncare.com');
      expect(await demoRepo.getCurrentUserName(), 'Demo User');
    });

    test('Pet CRUD operations work in-memory correctly', () async {
      final initialPets = await demoRepo.getPets();
      final count = initialPets.length;

      final newPet = Pet(
        id: 'new_demo_pet',
        name: 'Charlie',
        breed: 'Beagle',
        ageString: '1y',
        birthDate: DateTime(2025, 1, 1),
        avatarUrl: '',
        status: 'Healthy',
        weight: 10.0,
      );

      await demoRepo.addPet(newPet);
      final petsAfterAdd = await demoRepo.getPets();
      expect(petsAfterAdd.length, count + 1);
      expect(petsAfterAdd.any((p) => p.id == 'new_demo_pet'), isTrue);

      final updatedPet = newPet.copyWith(name: 'Charlie Modified');
      await demoRepo.updatePet(updatedPet);
      final petsAfterUpdate = await demoRepo.getPets();
      expect(petsAfterUpdate.firstWhere((p) => p.id == 'new_demo_pet').name, 'Charlie Modified');

      await demoRepo.deletePet('new_demo_pet');
      final petsAfterDelete = await demoRepo.getPets();
      expect(petsAfterDelete.length, count);
    });

    test('Diary CRUD operations work in-memory correctly', () async {
      final entry = DiaryEntry(
        id: 'diary_01',
        petId: 'pet_001',
        title: 'Walk in park',
        category: 'walk',
        note: 'Sunny day walk',
        timestamp: DateTime.now(),
      );

      await demoRepo.addDiaryEntry(entry);
      final petEntries = await demoRepo.getDiaryEntries('pet_001');
      expect(petEntries.length, 1);
      expect(petEntries.first.title, 'Walk in park');

      final allEntries = await demoRepo.getAllDiaryEntries();
      expect(allEntries.isNotEmpty, isTrue);

      await demoRepo.deleteDiaryEntry('diary_01');
      final emptyEntries = await demoRepo.getDiaryEntries('pet_001');
      expect(emptyEntries, isEmpty);
    });
  });
}
