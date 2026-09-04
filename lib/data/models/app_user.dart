import 'package:equatable/equatable.dart';

class AppUser extends Equatable {
  final String uid;
  final String name;
  final String email;
  final String userCode;
  final String? avatarUrl;
  final String? phone;
  final DateTime? createdAt;

  const AppUser({
    required this.uid,
    required this.name,
    required this.email,
    required this.userCode,
    this.avatarUrl,
    this.phone,
    this.createdAt,
  });

  /// Generates a consistent 8-digit numeric personal user code derived from UID.
  static String generateUserCode(String uid) {
    if (uid.isEmpty) return '10000001';
    final hash = uid.hashCode.abs();
    final codeInt = (hash % 90000000) + 10000000;
    return codeInt.toString();
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
      'email': email,
      'userCode': userCode,
      if (avatarUrl != null) 'avatarUrl': avatarUrl,
      if (phone != null) 'phone': phone,
      if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
    };
  }

  factory AppUser.fromMap(Map<String, dynamic> map, String docId) {
    final uid = docId.isNotEmpty ? docId : (map['uid'] ?? '').toString();
    final email = (map['email'] ?? '').toString();
    final name = (map['name'] ?? '').toString();
    final storedCode = (map['userCode'] ?? '').toString();
    final userCode = storedCode.isNotEmpty ? storedCode : generateUserCode(uid);

    DateTime? createdAt;
    if (map['createdAt'] != null) {
      if (map['createdAt'] is String) {
        createdAt = DateTime.tryParse(map['createdAt']);
      }
    }

    return AppUser(
      uid: uid,
      name: name,
      email: email,
      userCode: userCode,
      avatarUrl: map['avatarUrl'],
      phone: map['phone'],
      createdAt: createdAt,
    );
  }

  AppUser copyWith({
    String? uid,
    String? name,
    String? email,
    String? userCode,
    String? avatarUrl,
    String? phone,
    DateTime? createdAt,
  }) {
    return AppUser(
      uid: uid ?? this.uid,
      name: name ?? this.name,
      email: email ?? this.email,
      userCode: userCode ?? this.userCode,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      phone: phone ?? this.phone,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [
        uid,
        name,
        email,
        userCode,
        avatarUrl,
        phone,
        createdAt,
      ];
}
