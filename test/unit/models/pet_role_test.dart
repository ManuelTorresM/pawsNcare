import 'package:flutter_test/flutter_test.dart';
import 'package:pawsncare/data/models/pet_role.dart';

void main() {
  group('PetRole Enum and Extensions Tests', () {
    test('PetRole.fromString parses various role string representations', () {
      expect(PetRole.fromString('owner'), PetRole.owner);
      expect(PetRole.fromString('coowner'), PetRole.coOwner);
      expect(PetRole.fromString('co-owner'), PetRole.coOwner);
      expect(PetRole.fromString('co_owner'), PetRole.coOwner);
      expect(PetRole.fromString('caregiver'), PetRole.caregiver);
      expect(PetRole.fromString('carer'), PetRole.caregiver);
      expect(PetRole.fromString('veterinary'), PetRole.veterinary);
      expect(PetRole.fromString('vet'), PetRole.veterinary);
      expect(PetRole.fromString('unknown'), PetRole.caregiver);
    });

    test('PetRole display names, icons, and descriptions', () {
      expect(PetRole.owner.displayName, 'Owner');
      expect(PetRole.coOwner.displayName, 'Co-Owner');
      expect(PetRole.caregiver.displayName, 'Caregiver');
      expect(PetRole.veterinary.displayName, 'Veterinary');

      expect(PetRole.owner.description, contains('Full control'));
      expect(PetRole.coOwner.description, contains('Shared control'));
      expect(PetRole.caregiver.description, contains('Limited access'));
      expect(PetRole.veterinary.description, contains('Medical access'));
    });

    test('PetRole permissions matrix', () {
      // Profile editing
      expect(PetRole.owner.canEditProfile, isTrue);
      expect(PetRole.coOwner.canEditProfile, isTrue);
      expect(PetRole.caregiver.canEditProfile, isFalse);
      expect(PetRole.veterinary.canEditProfile, isFalse);

      // Managing members
      expect(PetRole.owner.canManageMembers, isTrue);
      expect(PetRole.coOwner.canManageMembers, isTrue);
      expect(PetRole.caregiver.canManageMembers, isFalse);

      // Deleting pet
      expect(PetRole.owner.canDeletePet, isTrue);
      expect(PetRole.coOwner.canDeletePet, isFalse);
      expect(PetRole.caregiver.canDeletePet, isFalse);

      // Logging medical
      expect(PetRole.owner.canLogMedical, isTrue);
      expect(PetRole.coOwner.canLogMedical, isTrue);
      expect(PetRole.veterinary.canLogMedical, isTrue);
      expect(PetRole.caregiver.canLogMedical, isFalse);
    });
  });
}
