import 'package:equatable/equatable.dart';
import 'pet_role.dart';

class SharedMember extends Equatable {
  final String id;
  final String email;
  final String name;
  final String? avatarUrl;
  final PetRole role;
  final DateTime joinedAt;
  final String status; // 'Active', 'Pending'

  const SharedMember({
    required this.id,
    required this.email,
    required this.name,
    this.avatarUrl,
    required this.role,
    required this.joinedAt,
    this.status = 'Active',
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'avatarUrl': avatarUrl,
      'role': role.name,
      'joinedAt': joinedAt.toIso8601String(),
      'status': status,
    };
  }

  factory SharedMember.fromMap(Map<String, dynamic> map) {
    return SharedMember(
      id: map['id'] ?? '',
      email: map['email'] ?? '',
      name: map['name'] ?? '',
      avatarUrl: map['avatarUrl'],
      role: PetRole.fromString(map['role'] ?? 'caregiver'),
      joinedAt: map['joinedAt'] != null
          ? DateTime.parse(map['joinedAt'])
          : DateTime.now(),
      status: map['status'] ?? 'Active',
    );
  }

  SharedMember copyWith({
    String? id,
    String? email,
    String? name,
    String? avatarUrl,
    PetRole? role,
    DateTime? joinedAt,
    String? status,
  }) {
    return SharedMember(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      role: role ?? this.role,
      joinedAt: joinedAt ?? this.joinedAt,
      status: status ?? this.status,
    );
  }

  @override
  List<Object?> get props => [
        id,
        email,
        name,
        avatarUrl,
        role,
        joinedAt,
        status,
      ];
}
