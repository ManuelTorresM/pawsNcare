import 'package:equatable/equatable.dart';

class Medication extends Equatable {
  final String id;
  final String name;
  final DateTime nextDoseDate;
  final DateTime? administeredDate;
  final bool isCompleted;
  final String type; // 'flea_tick', 'heartworm', 'vaccine'
  final String lotNumber;
  final String dose;
  final String route;
  final String frequency;
  final DateTime? startDate;
  final DateTime? endDate;
  final bool remindersEnabled;

  const Medication({
    required this.id,
    required this.name,
    required this.nextDoseDate,
    this.administeredDate,
    this.isCompleted = false,
    required this.type,
    this.lotNumber = '',
    this.dose = '',
    this.route = '',
    this.frequency = '',
    this.startDate,
    this.endDate,
    this.remindersEnabled = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'nextDoseDate': nextDoseDate.toIso8601String(),
      'administeredDate': administeredDate?.toIso8601String(),
      'isCompleted': isCompleted,
      'type': type,
      'lotNumber': lotNumber,
      'dose': dose,
      'route': route,
      'frequency': frequency,
      'startDate': startDate?.toIso8601String(),
      'endDate': endDate?.toIso8601String(),
      'remindersEnabled': remindersEnabled,
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
      lotNumber: map['lotNumber'] ?? '',
      dose: map['dose'] ?? '',
      route: map['route'] ?? '',
      frequency: map['frequency'] ?? '',
      startDate: map['startDate'] != null
          ? DateTime.parse(map['startDate'])
          : null,
      endDate: map['endDate'] != null
          ? DateTime.parse(map['endDate'])
          : null,
      remindersEnabled: map['remindersEnabled'] ?? false,
    );
  }

  Medication copyWith({
    String? id,
    String? name,
    DateTime? nextDoseDate,
    DateTime? administeredDate,
    bool? isCompleted,
    String? type,
    String? lotNumber,
    String? dose,
    String? route,
    String? frequency,
    DateTime? startDate,
    DateTime? endDate,
    bool? remindersEnabled,
  }) {
    return Medication(
      id: id ?? this.id,
      name: name ?? this.name,
      nextDoseDate: nextDoseDate ?? this.nextDoseDate,
      administeredDate: administeredDate ?? this.administeredDate,
      isCompleted: isCompleted ?? this.isCompleted,
      type: type ?? this.type,
      lotNumber: lotNumber ?? this.lotNumber,
      dose: dose ?? this.dose,
      route: route ?? this.route,
      frequency: frequency ?? this.frequency,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      remindersEnabled: remindersEnabled ?? this.remindersEnabled,
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        nextDoseDate,
        administeredDate,
        isCompleted,
        type,
        lotNumber,
        dose,
        route,
        frequency,
        startDate,
        endDate,
        remindersEnabled,
      ];
}
