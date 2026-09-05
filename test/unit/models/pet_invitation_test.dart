import 'package:flutter_test/flutter_test.dart';
import 'package:pawsncare/data/models/pet_invitation.dart';
import 'package:pawsncare/data/models/pet_role.dart';

void main() {
  group('PetInvitation Model Tests', () {
    final created = DateTime(2026, 5, 1, 10, 0);
    final invitation = PetInvitation(
      id: 'inv_01',
      petId: 'pet_001',
      petName: 'Bella',
      petBreed: 'Labrador Retriever',
      petAvatarUrl: 'https://example.com/avatar.png',
      ownerId: 'user_owner',
      ownerName: 'Alice',
      recipientEmail: 'bob@example.com',
      recipientUsername: 'Bob',
      role: PetRole.coOwner,
      status: 'Pending',
      createdAt: created,
    );

    test('toMap and fromMap work correctly', () {
      final map = invitation.toMap();
      expect(map['id'], 'inv_01');
      expect(map['recipientEmail'], 'bob@example.com');
      expect(map['role'], 'coOwner');
      expect(map['status'], 'Pending');

      final deserialized = PetInvitation.fromMap(map);
      expect(deserialized.id, invitation.id);
      expect(deserialized.recipientEmail, invitation.recipientEmail);
      expect(deserialized.role, PetRole.coOwner);
      expect(deserialized.status, 'Pending');
    });

    test('copyWith updates status to Active or Declined', () {
      final accepted = invitation.copyWith(status: 'Active');
      expect(accepted.status, 'Active');

      final declined = invitation.copyWith(status: 'Declined');
      expect(declined.status, 'Declined');
    });
  });
}
