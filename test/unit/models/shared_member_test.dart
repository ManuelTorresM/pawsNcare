import 'package:flutter_test/flutter_test.dart';
import 'package:pawsncare/data/models/shared_member.dart';
import 'package:pawsncare/data/models/pet_role.dart';

void main() {
  group('SharedMember Model Tests', () {
    final now = DateTime(2026, 2, 1);
    final member = SharedMember(
      id: 'mem_1',
      email: 'member@paws.com',
      name: 'Member One',
      avatarUrl: 'https://example.com/mem.png',
      role: PetRole.caregiver,
      joinedAt: now,
      status: 'Active',
    );

    test('toMap and fromMap work correctly', () {
      final map = member.toMap();
      expect(map['id'], 'mem_1');
      expect(map['email'], 'member@paws.com');
      expect(map['role'], 'caregiver');
      expect(map['status'], 'Active');

      final deserialized = SharedMember.fromMap(map);
      expect(deserialized.id, member.id);
      expect(deserialized.role, PetRole.caregiver);
      expect(deserialized.email, member.email);
    });

    test('copyWith alters properties correctly', () {
      final updated = member.copyWith(role: PetRole.coOwner, status: 'Pending');
      expect(updated.role, PetRole.coOwner);
      expect(updated.status, 'Pending');
      expect(updated.email, member.email);
    });
  });
}
