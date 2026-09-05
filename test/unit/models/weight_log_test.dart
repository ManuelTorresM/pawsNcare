import 'package:flutter_test/flutter_test.dart';
import 'package:pawsncare/data/models/weight_log.dart';

void main() {
  group('WeightLog Model Tests', () {
    final now = DateTime(2026, 3, 1, 10, 0);
    final log = WeightLog(
      id: 'w_01',
      weight: 12.8,
      date: now,
      note: 'Routine weighing',
    );

    test('toMap and fromMap work accurately', () {
      final map = log.toMap();
      expect(map['id'], 'w_01');
      expect(map['weight'], 12.8);
      expect(map['note'], 'Routine weighing');

      final deserialized = WeightLog.fromMap(map);
      expect(deserialized.id, log.id);
      expect(deserialized.weight, 12.8);
      expect(deserialized.note, 'Routine weighing');
      expect(deserialized.date, log.date);
    });

    test('Equatable checks equality of WeightLog objects', () {
      final log2 = WeightLog(
        id: 'w_01',
        weight: 12.8,
        date: now,
        note: 'Routine weighing',
      );
      expect(log, equals(log2));
    });
  });
}
