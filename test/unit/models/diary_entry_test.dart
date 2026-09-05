import 'package:flutter_test/flutter_test.dart';
import 'package:pawsncare/data/models/diary_entry.dart';

void main() {
  group('DiaryEntry Model Tests', () {
    final timestamp = DateTime(2026, 3, 10, 14, 30);
    final entry = DiaryEntry(
      id: 'entry_01',
      petId: 'pet_001',
      title: 'Afternoon Walk',
      category: 'walk',
      note: '30 minute walk in the park.',
      timestamp: timestamp,
      severity: 'MILD',
    );

    test('Serialization and Deserialization (toMap & fromMap)', () {
      final map = entry.toMap();
      expect(map['id'], 'entry_01');
      expect(map['petId'], 'pet_001');
      expect(map['title'], 'Afternoon Walk');
      expect(map['category'], 'walk');
      expect(map['severity'], 'MILD');

      final deserialized = DiaryEntry.fromMap(map);
      expect(deserialized.id, entry.id);
      expect(deserialized.petId, entry.petId);
      expect(deserialized.title, entry.title);
      expect(deserialized.timestamp, entry.timestamp);
    });

    test('Equatable value equality', () {
      final entry2 = DiaryEntry(
        id: 'entry_01',
        petId: 'pet_001',
        title: 'Afternoon Walk',
        category: 'walk',
        note: '30 minute walk in the park.',
        timestamp: timestamp,
        severity: 'MILD',
      );
      expect(entry, equals(entry2));
    });
  });
}
