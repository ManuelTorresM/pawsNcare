import 'package:equatable/equatable.dart';
import 'pet_role.dart';

class PetInvitation extends Equatable {
  final String id;
  final String petId;
  final String petName;
  final String petBreed;
  final String petAvatarUrl;
  final String ownerId;
  final String ownerName;
  final String recipientEmail;
  final String recipientUsername;
  final PetRole role;
  final String status; // 'Pending', 'Active', 'Declined'
  final DateTime createdAt;

  const PetInvitation({
    required this.id,
    required this.petId,
    required this.petName,
    required this.petBreed,
    required this.petAvatarUrl,
    required this.ownerId,
    required this.ownerName,
    required this.recipientEmail,
    this.recipientUsername = '',
    required this.role,
    this.status = 'Pending',
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'petId': petId,
      'petName': petName,
      'petBreed': petBreed,
      'petAvatarUrl': petAvatarUrl,
      'ownerId': ownerId,
      'ownerName': ownerName,
      'recipientEmail': recipientEmail,
      'recipientUsername': recipientUsername,
      'role': role.name,
      'status': status,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory PetInvitation.fromMap(Map<String, dynamic> map) {
    return PetInvitation(
      id: map['id'] ?? '',
      petId: map['petId'] ?? '',
      petName: map['petName'] ?? '',
      petBreed: map['petBreed'] ?? '',
      petAvatarUrl: map['petAvatarUrl'] ?? '',
      ownerId: map['ownerId'] ?? '',
      ownerName: map['ownerName'] ?? '',
      recipientEmail: map['recipientEmail'] ?? '',
      recipientUsername: map['recipientUsername'] ?? '',
      role: PetRole.values.firstWhere(
        (r) => r.name == map['role'],
        orElse: () => PetRole.coOwner,
      ),
      status: map['status'] ?? 'Pending',
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'])
          : DateTime.now(),
    );
  }

  PetInvitation copyWith({
    String? id,
    String? petId,
    String? petName,
    String? petBreed,
    String? petAvatarUrl,
    String? ownerId,
    String? ownerName,
    String? recipientEmail,
    String? recipientUsername,
    PetRole? role,
    String? status,
    DateTime? createdAt,
  }) {
    return PetInvitation(
      id: id ?? this.id,
      petId: petId ?? this.petId,
      petName: petName ?? this.petName,
      petBreed: petBreed ?? this.petBreed,
      petAvatarUrl: petAvatarUrl ?? this.petAvatarUrl,
      ownerId: ownerId ?? this.ownerId,
      ownerName: ownerName ?? this.ownerName,
      recipientEmail: recipientEmail ?? this.recipientEmail,
      recipientUsername: recipientUsername ?? this.recipientUsername,
      role: role ?? this.role,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        petId,
        petName,
        petBreed,
        petAvatarUrl,
        ownerId,
        ownerName,
        recipientEmail,
        recipientUsername,
        role,
        status,
        createdAt,
      ];
}
