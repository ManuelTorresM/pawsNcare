import 'package:flutter_test/flutter_test.dart';
import 'package:pawsncare/data/models/pet.dart';
import 'package:pawsncare/data/models/pet_role.dart';
import 'package:pawsncare/data/models/shared_member.dart';
import 'package:pawsncare/data/models/weight_log.dart';

void main() {
  group('Pet Model Tests', () {
    final now = DateTime(2026, 1, 1);
    final pet = Pet(
      id: 'pet_001',
      name: 'Bella',
      breed: 'Labrador Retriever',
      ageString: '2y 4m',
      birthDate: now,
      avatarUrl: 'https://example.com/bella.png',
      status: 'Healthy',
      weight: 24.5,
      weightHistory: [
        WeightLog(id: 'w1', weight: 24.5, date: now, note: 'Initial checkup'),
      ],
      species: 'Dog',
      gender: 'Female',
      neutered: 'Yes',
      medicalConditions: const ['None'],
      allergies: const ['Pollen'],
      activityLevel: 'High',
      dietEnabled: true,
      foodType: 'Dry Kibble',
      feedingNotes: '2 cups twice daily',
      behaviorTags: const ['Friendly', 'Playful'],
      ownerId: 'user_owner',
      members: [
        SharedMember(
          id: 'user_co',
          email: 'co@mail.com',
          name: 'CoOwner',
          role: PetRole.coOwner,
          joinedAt: now,
        ),
        SharedMember(
          id: 'user_care',
          email: 'care@mail.com',
          name: 'Caregiver',
          role: PetRole.caregiver,
          joinedAt: now,
        ),
        SharedMember(
          id: 'user_vet',
          email: 'vet@mail.com',
          name: 'Doctor',
          role: PetRole.veterinary,
          joinedAt: now,
        ),
      ],
    );

    test('Serialization and Deserialization (toMap & fromMap)', () {
      final map = pet.toMap();
      expect(map['id'], 'pet_001');
      expect(map['name'], 'Bella');
      expect(map['weight'], 24.5);
      expect(map['species'], 'Dog');

      final deserialized = Pet.fromMap(map);
      expect(deserialized.id, pet.id);
      expect(deserialized.name, pet.name);
      expect(deserialized.weight, pet.weight);
      expect(deserialized.weightHistory.length, 1);
      expect(deserialized.members.length, 3);
    });

    test('Helper getters for member categories (coOwners, caregivers, veterinarians)', () {
      expect(pet.coOwners.length, 1);
      expect(pet.coOwners.first.name, 'CoOwner');
      expect(pet.caregivers.length, 1);
      expect(pet.caregivers.first.name, 'Caregiver');
      expect(pet.veterinarians.length, 1);
      expect(pet.veterinarians.first.name, 'Doctor');
    });

    test('toPendingReplica sanitizes medical and personal details', () {
      final replica = pet.toPendingReplica();
      expect(replica.id, pet.id);
      expect(replica.name, pet.name);
      expect(replica.weightHistory, isEmpty);
      expect(replica.medications, isEmpty);
      expect(replica.photos, isEmpty);
      expect(replica.medicalConditions, isEmpty);
      expect(replica.allergies, isEmpty);
    });

    test('toConsistentImageReplica handles owner vs non-owner avatar URLs correctly', () {
      // For owner
      final ownerReplica = pet.toConsistentImageReplica(currentUserId: 'user_owner');
      expect(ownerReplica.avatarUrl, 'https://example.com/bella.png');

      // For non-owner with local path avatar
      final localPet = pet.copyWith(avatarUrl: '/data/user/0/cache/image.png');
      final nonOwnerReplica = localPet.toConsistentImageReplica(currentUserId: 'user_co');
      expect(nonOwnerReplica.avatarUrl, '');
    });

    test('copyWith updates specified fields correctly', () {
      final updated = pet.copyWith(weight: 25.0, status: 'Active');
      expect(updated.weight, 25.0);
      expect(updated.status, 'Active');
      expect(updated.name, 'Bella');
    });
  });
}
