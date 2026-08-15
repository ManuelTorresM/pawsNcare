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
        photos
      ];
}
