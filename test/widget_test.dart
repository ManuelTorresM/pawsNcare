import 'package:flutter_test/flutter_test.dart';
import 'package:pawsncare/data/models/weight_log.dart';
import 'package:pawsncare/data/models/pet.dart';

void main() {
  group('Paws & Care Model Tests', () {
    test('WeightLog serialization and deserialization', () {
      final now = DateTime.now();
      final log = WeightLog(
        id: 'w1',
        weight: 28.5,
        date: now,
        note: 'Vet Visit',
      );

      final map = log.toMap();
      final fromMap = WeightLog.fromMap(map);

      expect(fromMap.id, 'w1');
      expect(fromMap.weight, 28.5);
      expect(fromMap.note, 'Vet Visit');
      expect(fromMap.date.day, now.day);
    });

    test('Pet serialization and deserialization', () {
      final now = DateTime.now();
      final pet = Pet(
        id: 'luna',
        name: 'Luna',
        breed: 'Golden Retriever',
        ageString: '3y',
        birthDate: now,
        avatarUrl: 'http://image.png',
        status: 'Healthy',
        weight: 28.5,
        weightHistory: [
          WeightLog(id: 'w1', weight: 28.5, date: now, note: 'Initial'),
        ],
        medications: const [],
        photos: const [],
      );

      final map = pet.toMap();
      final fromMap = Pet.fromMap(map);

      expect(fromMap.id, 'luna');
      expect(fromMap.name, 'Luna');
      expect(fromMap.weight, 28.5);
      expect(fromMap.weightHistory.length, 1);
      expect(fromMap.weightHistory.first.weight, 28.5);
    });
  });
}
