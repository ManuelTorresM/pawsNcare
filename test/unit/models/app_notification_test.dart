import 'package:flutter_test/flutter_test.dart';
import 'package:pawsncare/data/models/app_notification.dart';

void main() {
  group('AppNotification Model Tests', () {
    final now = DateTime(2026, 4, 1, 9, 0);
    final notification = AppNotification(
      id: 'notif_1',
      title: 'Medication Time',
      body: 'Time to give Heartgard to Bella.',
      petName: 'Bella',
      category: NotificationCategory.medication,
      timestamp: now,
      isRead: false,
    );

    test('NotificationCategory extension displayName', () {
      expect(NotificationCategory.medication.displayName, 'Medication');
      expect(NotificationCategory.vaccine.displayName, 'Vaccination');
      expect(NotificationCategory.feeding.displayName, 'Feeding');
      expect(NotificationCategory.hydration.displayName, 'Hydration');
      expect(NotificationCategory.system.displayName, 'Alert');
    });

    test('toMap and fromMap work accurately', () {
      final map = notification.toMap();
      expect(map['id'], 'notif_1');
      expect(map['category'], 'medication');
      expect(map['isRead'], false);

      final deserialized = AppNotification.fromMap(map);
      expect(deserialized.id, notification.id);
      expect(deserialized.category, NotificationCategory.medication);
      expect(deserialized.isRead, false);
    });

    test('copyWith modifies attributes correctly', () {
      final readNotif = notification.copyWith(isRead: true);
      expect(readNotif.isRead, true);
      expect(readNotif.title, notification.title);
    });
  });
}
