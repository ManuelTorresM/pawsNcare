import 'package:flutter_test/flutter_test.dart';
import 'package:pawsncare/data/models/app_user.dart';

void main() {
  group('AppUser Model Tests', () {
    const sampleUser = AppUser(
      uid: 'user_123',
      name: 'John Doe',
      email: 'john@example.com',
      userCode: '12345678',
      avatarUrl: 'https://example.com/avatar.jpg',
      phone: '+1234567890',
    );

    test('toMap serializes AppUser correctly', () {
      final map = sampleUser.toMap();
      expect(map['uid'], 'user_123');
      expect(map['name'], 'John Doe');
      expect(map['email'], 'john@example.com');
      expect(map['userCode'], '12345678');
      expect(map['avatarUrl'], 'https://example.com/avatar.jpg');
      expect(map['phone'], '+1234567890');
    });

    test('fromMap deserializes map to AppUser correctly', () {
      final map = {
        'uid': 'user_123',
        'name': 'John Doe',
        'email': 'john@example.com',
        'userCode': '87654321',
        'avatarUrl': 'https://example.com/pic.png',
        'phone': '+987654321',
        'createdAt': '2026-01-01T12:00:00.000Z',
      };
      final user = AppUser.fromMap(map, 'doc_123');

      expect(user.uid, 'doc_123');
      expect(user.name, 'John Doe');
      expect(user.email, 'john@example.com');
      expect(user.userCode, '87654321');
      expect(user.avatarUrl, 'https://example.com/pic.png');
      expect(user.phone, '+987654321');
      expect(user.createdAt, isNotNull);
    });

    test('generateUserCode generates consistent 8-digit numeric code', () {
      final code1 = AppUser.generateUserCode('user_abc');
      final code2 = AppUser.generateUserCode('user_abc');
      expect(code1, equals(code2));
      expect(code1.length, 8);
      expect(int.tryParse(code1), isNotNull);

      final emptyCode = AppUser.generateUserCode('');
      expect(emptyCode, '10000001');
    });

    test('copyWith updates properties while retaining others', () {
      final updated = sampleUser.copyWith(name: 'Jane Doe', phone: '+111111');
      expect(updated.name, 'Jane Doe');
      expect(updated.phone, '+111111');
      expect(updated.email, sampleUser.email);
      expect(updated.uid, sampleUser.uid);
    });

    test('Equatable value equality check', () {
      const userA = AppUser(
        uid: '1',
        name: 'Alex',
        email: 'alex@mail.com',
        userCode: '10000001',
      );
      const userB = AppUser(
        uid: '1',
        name: 'Alex',
        email: 'alex@mail.com',
        userCode: '10000001',
      );

      expect(userA, equals(userB));
    });
  });
}
