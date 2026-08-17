import 'package:equatable/equatable.dart';
import 'weight_log.dart';
import 'medication.dart';

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
  final List<String> allergies;
  final String activityLevel;
  final bool dietEnabled;
  final String foodType;
  final String feedingNotes;
  final List<String> behaviorTags;

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
    this.allergies = const [],
    this.activityLevel = 'Moderate',
    this.dietEnabled = true,
    this.foodType = 'Dry Kibble',
    this.feedingNotes = '',
    this.behaviorTags = const [],
  });

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
      'allergies': allergies,
      'activityLevel': activityLevel,
      'dietEnabled': dietEnabled,
      'foodType': foodType,
      'feedingNotes': feedingNotes,
      'behaviorTags': behaviorTags,
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
              (map['weightHistory'] as List).map((x) => WeightLog.fromMap(x)))
          : const [],
      medications: map['medications'] != null
          ? List<Medication>.from(
              (map['medications'] as List).map((x) => Medication.fromMap(x)))
          : const [],
      photos: map['photos'] != null ? List<String>.from(map['photos']) : const [],
      species: map['species'] ?? 'Dog',
      gender: map['gender'] ?? 'Female',
      neutered: map['neutered'] ?? 'Yes',
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
    List<String>? allergies,
    String? activityLevel,
    bool? dietEnabled,
    String? foodType,
    String? feedingNotes,
    List<String>? behaviorTags,
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
      allergies: allergies ?? this.allergies,
      activityLevel: activityLevel ?? this.activityLevel,
      dietEnabled: dietEnabled ?? this.dietEnabled,
      foodType: foodType ?? this.foodType,
      feedingNotes: feedingNotes ?? this.feedingNotes,
      behaviorTags: behaviorTags ?? this.behaviorTags,
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
        allergies,
        activityLevel,
        dietEnabled,
        foodType,
        feedingNotes,
        behaviorTags,
      ];
}
