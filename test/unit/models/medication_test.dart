import 'package:flutter_test/flutter_test.dart';
import 'package:pawsncare/data/models/medication.dart';

void main() {
  group('Medication Model Tests', () {
    final nextDose = DateTime(2026, 6, 15, 10, 0);
    final med = Medication(
      id: 'med_101',
      name: 'Heartgard',
      nextDoseDate: nextDose,
      type: 'heartworm',
      lotNumber: 'LOT-998',
      dose: '1 Tablet',
      route: 'Oral',
      frequency: 'Monthly',
      remindersEnabled: true,
    );

    test('Serialization and Deserialization (toMap & fromMap)', () {
      final map = med.toMap();
      expect(map['id'], 'med_101');
      expect(map['name'], 'Heartgard');
      expect(map['type'], 'heartworm');
      expect(map['remindersEnabled'], true);

      final deserialized = Medication.fromMap(map);
      expect(deserialized.id, med.id);
      expect(deserialized.name, med.name);
      expect(deserialized.nextDoseDate, med.nextDoseDate);
      expect(deserialized.remindersEnabled, med.remindersEnabled);
    });

    test('maxDosesToday returns expected dose frequencies', () {
      expect(med.copyWith(frequency: 'Every 8h').maxDosesToday, 3);
      expect(med.copyWith(frequency: 'Every 12h').maxDosesToday, 2);
      expect(med.copyWith(frequency: 'Every 24h').maxDosesToday, 1);
      expect(med.copyWith(type: 'vaccine').maxDosesToday, 1);
    });

    test('dosesToday checks if administeredDate is today', () {
      final now = DateTime.now();
      final medToday = med.copyWith(
        administeredDate: now,
        dosesAdministeredToday: 2,
      );
      expect(medToday.dosesToday, 2);

      final medYesterday = med.copyWith(
        administeredDate: now.subtract(const Duration(days: 1)),
        dosesAdministeredToday: 2,
      );
      expect(medYesterday.dosesToday, 0);

      expect(med.dosesToday, 0);
    });

    test('copyWith updates fields correctly', () {
      final updated = med.copyWith(isCompleted: true, dose: '2 Tablets');
      expect(updated.isCompleted, isTrue);
      expect(updated.dose, '2 Tablets');
      expect(updated.name, med.name);
    });
  });
}
