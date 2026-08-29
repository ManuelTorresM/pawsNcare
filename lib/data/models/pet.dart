import 'package:equatable/equatable.dart';
import 'weight_log.dart';
import 'medication.dart';
import 'pet_role.dart';
import 'shared_member.dart';

class Pet extends Equatable {
  final String id;
  final String name;
  final String breed;
  final String ageString;
  final DateTime birthDate;
  final String avatarUrl;
  final String status; // 'Healthy', 'Check Diary', 'Puppy'
  final double weight; // current weight in kg
  final List<WeightLog> weightHistory;
  final List<Medication> medications;
  final List<String> photos;

  // New fields from creation wizard
  final String species;
  final String gender;
  final String neutered;
  final List<String> medicalConditions;
  final List<String> allergies;
  final String activityLevel;
  final bool dietEnabled;
  final String foodType;
  final String feedingNotes;
  final List<String> behaviorTags;

  // Sharing & Role Access fields
  final String ownerId;
  final List<SharedMember> members;

  const Pet({
    required this.id,
    required this.name,
    required this.breed,
    required this.ageString,
    required this.birthDate,
    required this.avatarUrl,
    required this.status,
    required this.weight,
    this.weightHistory = const [],
    this.medications = const [],
    this.photos = const [],
    this.species = 'Dog',
    this.gender = 'Female',
    this.neutered = 'Yes',
    this.medicalConditions = const [],
    this.allergies = const [],
    this.activityLevel = 'Moderate',
    this.dietEnabled = true,
    this.foodType = 'Dry Kibble',
    this.feedingNotes = '',
    this.behaviorTags = const [],
    this.ownerId = '',
    this.members = const [],
  });

  // Helper getters for member categories
  List<SharedMember> get coOwners =>
      members.where((m) => m.role == PetRole.coOwner).toList();

  List<SharedMember> get caregivers =>
      members.where((m) => m.role == PetRole.caregiver).toList();

  List<SharedMember> get veterinarians =>
      members.where((m) => m.role == PetRole.veterinary).toList();

  /// Returns a sanitized minimal replica of Pet for pending invitations
  /// to protect private medical history, photos, and records until accepted.
  Pet toPendingReplica() {
    return Pet(
      id: id,
      name: name,
      breed: breed,
      ageString: ageString,
      birthDate: birthDate,
      avatarUrl: _resolveConsistentAvatarUrl(''),
      status: status,
      weight: weight,
      weightHistory: const [],
      medications: const [],
      photos: const [],
      species: species,
      gender: gender,
      neutered: neutered,
      medicalConditions: const [],
      allergies: const [],
      activityLevel: activityLevel,
      dietEnabled: dietEnabled,
      foodType: foodType,
      feedingNotes: '',
      behaviorTags: const [],
      ownerId: ownerId,
      members: members,
    );
  }

  /// Returns an image-consistent replica for shared pets.
  /// Ensures shared members receive valid network image replicas and filters out
  /// local device file paths that belong exclusively to the owner's local disk.
  Pet toConsistentImageReplica({required String currentUserId}) {
    final isOwner = ownerId.isNotEmpty && ownerId == currentUserId;
    if (isOwner) return this;

    final consistentAvatar = _resolveConsistentAvatarUrl(currentUserId);
    final consistentPhotos = photos
        .where(
          (p) =>
              p.startsWith('http://') ||
              p.startsWith('https://') ||
              p.startsWith('gs://'),
        )
        .toList();

    return copyWith(avatarUrl: consistentAvatar, photos: consistentPhotos);
  }

  String _resolveConsistentAvatarUrl(String currentUserId) {
    if (avatarUrl.startsWith('http://') ||
        avatarUrl.startsWith('https://') ||
        avatarUrl.startsWith('gs://')) {
      return avatarUrl;
    }
    // If avatar is a local file path and user is not owner, return empty string for fallback
    if (ownerId.isNotEmpty &&
        ownerId != currentUserId &&
        avatarUrl.isNotEmpty) {
      return '';
    }
    return avatarUrl;
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'breed': breed,
      'ageString': ageString,
      'birthDate': birthDate.toIso8601String(),
      'avatarUrl': avatarUrl,
      'status': status,
      'weight': weight,
      'weightHistory': weightHistory.map((w) => w.toMap()).toList(),
      'medications': medications.map((m) => m.toMap()).toList(),
      'photos': photos,
      'species': species,
      'gender': gender,
      'neutered': neutered,
      'medicalConditions': medicalConditions,
      'allergies': allergies,
      'activityLevel': activityLevel,
      'dietEnabled': dietEnabled,
      'foodType': foodType,
      'feedingNotes': feedingNotes,
      'behaviorTags': behaviorTags,
      'ownerId': ownerId,
      'members': members.map((m) => m.toMap()).toList(),
    };
  }

  factory Pet.fromMap(Map<String, dynamic> map) {
    return Pet(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      breed: map['breed'] ?? '',
      ageString: map['ageString'] ?? '',
      birthDate: DateTime.parse(map['birthDate']),
      avatarUrl: map['avatarUrl'] ?? '',
      status: map['status'] ?? 'Healthy',
      weight: (map['weight'] as num).toDouble(),
      weightHistory: map['weightHistory'] != null
          ? List<WeightLog>.from(
              (map['weightHistory'] as List).map((x) => WeightLog.fromMap(x)),
            )
          : const [],
      medications: map['medications'] != null
          ? List<Medication>.from(
              (map['medications'] as List).map((x) => Medication.fromMap(x)),
            )
          : const [],
      photos: map['photos'] != null
          ? List<String>.from(map['photos'])
          : const [],
      species: map['species'] ?? 'Dog',
      gender: map['gender'] ?? 'Female',
      neutered: map['neutered'] ?? 'Yes',
      medicalConditions: map['medicalConditions'] != null
          ? List<String>.from(map['medicalConditions'])
          : const [],
      allergies: map['allergies'] != null
          ? List<String>.from(map['allergies'])
          : const [],
      activityLevel: map['activityLevel'] ?? 'Moderate',
      dietEnabled: map['dietEnabled'] ?? true,
      foodType: map['foodType'] ?? 'Dry Kibble',
      feedingNotes: map['feedingNotes'] ?? '',
      behaviorTags: map['behaviorTags'] != null
          ? List<String>.from(map['behaviorTags'])
          : const [],
      ownerId: map['ownerId'] ?? '',
      members: map['members'] != null
          ? List<SharedMember>.from(
              (map['members'] as List).map((x) => SharedMember.fromMap(x)),
            )
          : const [],
    );
  }

  Pet copyWith({
    String? id,
    String? name,
    String? breed,
    String? ageString,
    DateTime? birthDate,
    String? avatarUrl,
    String? status,
    double? weight,
    List<WeightLog>? weightHistory,
    List<Medication>? medications,
    List<String>? photos,
    String? species,
    String? gender,
    String? neutered,
    List<String>? medicalConditions,
    List<String>? allergies,
    String? activityLevel,
    bool? dietEnabled,
    String? foodType,
    String? feedingNotes,
    List<String>? behaviorTags,
    String? ownerId,
    List<SharedMember>? members,
  }) {
    return Pet(
      id: id ?? this.id,
      name: name ?? this.name,
      breed: breed ?? this.breed,
      ageString: ageString ?? this.ageString,
      birthDate: birthDate ?? this.birthDate,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      status: status ?? this.status,
      weight: weight ?? this.weight,
      weightHistory: weightHistory ?? this.weightHistory,
      medications: medications ?? this.medications,
      photos: photos ?? this.photos,
      species: species ?? this.species,
      gender: gender ?? this.gender,
      neutered: neutered ?? this.neutered,
      medicalConditions: medicalConditions ?? this.medicalConditions,
      allergies: allergies ?? this.allergies,
      activityLevel: activityLevel ?? this.activityLevel,
      dietEnabled: dietEnabled ?? this.dietEnabled,
      foodType: foodType ?? this.foodType,
      feedingNotes: feedingNotes ?? this.feedingNotes,
      behaviorTags: behaviorTags ?? this.behaviorTags,
      ownerId: ownerId ?? this.ownerId,
      members: members ?? this.members,
    );
  }

  @override
  List<Object?> get props => [
    id,
    name,
    breed,
    ageString,
    birthDate,
    avatarUrl,
    status,
    weight,
    weightHistory,
    medications,
    photos,
    species,
    gender,
    neutered,
    medicalConditions,
    allergies,
    activityLevel,
    dietEnabled,
    foodType,
    feedingNotes,
    behaviorTags,
    ownerId,
    members,
  ];
}
