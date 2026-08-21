import 'package:flutter/material.dart';

enum PetRole {
  owner,
  coOwner,
  caregiver,
  veterinary;

  String get displayName {
    switch (this) {
      case PetRole.owner:
        return 'Owner';
      case PetRole.coOwner:
        return 'Co-Owner';
      case PetRole.caregiver:
        return 'Caregiver';
      case PetRole.veterinary:
        return 'Veterinary';
    }
  }

  String get description {
    switch (this) {
      case PetRole.owner:
        return 'Full control: can edit details, invite users, and delete profile.';
      case PetRole.coOwner:
        return 'Shared control: can edit details, log entries, and invite caregivers.';
      case PetRole.caregiver:
        return 'Limited access: can view schedule, log daily activities and medications.';
      case PetRole.veterinary:
        return 'Medical access: can view health history, manage prescriptions and vaccines.';
    }
  }

  IconData get icon {
    switch (this) {
      case PetRole.owner:
        return Icons.workspace_premium;
      case PetRole.coOwner:
        return Icons.people;
      case PetRole.caregiver:
        return Icons.pets;
      case PetRole.veterinary:
        return Icons.medical_services;
    }
  }

  Color get color {
    switch (this) {
      case PetRole.owner:
        return const Color(0xFFD97706); // Amber / Gold
      case PetRole.coOwner:
        return const Color(0xFF2563EB); // Royal Blue
      case PetRole.caregiver:
        return const Color(0xFF059669); // Emerald Green
      case PetRole.veterinary:
        return const Color(0xFF7C3AED); // Purple
    }
  }

  Color get backgroundColor {
    switch (this) {
      case PetRole.owner:
        return const Color(0xFFFEF3C7); // Light Amber
      case PetRole.coOwner:
        return const Color(0xFFDBEAFE); // Light Blue
      case PetRole.caregiver:
        return const Color(0xFFD1FAE5); // Light Green
      case PetRole.veterinary:
        return const Color(0xFFEDE9FE); // Light Purple
    }
  }

  // Permission Getters
  bool get canEditProfile => this == PetRole.owner || this == PetRole.coOwner;
  bool get canManageMembers => this == PetRole.owner || this == PetRole.coOwner;
  bool get canDeletePet => this == PetRole.owner;
  bool get canLogMedical =>
      this == PetRole.owner ||
      this == PetRole.coOwner ||
      this == PetRole.veterinary;
  bool get canLogDaily => true;

  static PetRole fromString(String value) {
    switch (value.toLowerCase()) {
      case 'owner':
        return PetRole.owner;
      case 'coowner':
      case 'co-owner':
      case 'co_owner':
        return PetRole.coOwner;
      case 'caregiver':
      case 'carer':
        return PetRole.caregiver;
      case 'veterinary':
      case 'vet':
      case 'veterinarian':
        return PetRole.veterinary;
      default:
        return PetRole.caregiver;
    }
  }
}
