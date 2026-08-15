import 'package:equatable/equatable.dart';

class Medication extends Equatable {
  final String id;
  final String name;
  final DateTime nextDoseDate;
  final DateTime? administeredDate;
  final bool isCompleted;
  final String type; // 'flea_tick', 'heartworm', 'vaccine'

  const Medication({
    required this.id,
    required this.name,
    required this.nextDoseDate,
    this.administeredDate,
    this.isCompleted = false,
    required this.type,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'nextDoseDate': nextDoseDate.toIso8601String(),
      'administeredDate': administeredDate?.toIso8601String(),
      'isCompleted': isCompleted,
      'type': type,
    };
  }

  factory Medication.fromMap(Map<String, dynamic> map) {
    return Medication(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      nextDoseDate: DateTime.parse(map['nextDoseDate']),
      administeredDate: map['administeredDate'] != null
          ? DateTime.parse(map['administeredDate'])
          : null,
      isCompleted: map['isCompleted'] ?? false,
      type: map['type'] ?? '',
    );
  }

  @override
  List<Object?> get props => [id, name, nextDoseDate, administeredDate, isCompleted, type];
}
