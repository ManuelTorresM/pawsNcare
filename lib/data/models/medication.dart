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
  final int dosesAdministeredToday;

  final bool hasStartTime;
  final bool isSavedToHistory;

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
    this.dosesAdministeredToday = 0,
    this.hasStartTime = true,
    this.isSavedToHistory = false,
  });

  int get dosesToday {
    if (administeredDate == null) return 0;
    final now = DateTime.now();
    final isToday = administeredDate!.year == now.year &&
        administeredDate!.month == now.month &&
        administeredDate!.day == now.day;
    return isToday ? dosesAdministeredToday : 0;
  }

  int get maxDosesToday {
    if (type == 'vaccine') return 1;
    switch (frequency) {
      case 'Every 8h':
        return 3;
      case 'Every 12h':
        return 2;
      case 'Every 24h':
      case 'Weekly':
      case 'Monthly':
      case 'One-time':
      default:
        return 1;
    }
  }

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
      'dosesAdministeredToday': dosesAdministeredToday,
      'hasStartTime': hasStartTime,
      'isSavedToHistory': isSavedToHistory,
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
      dosesAdministeredToday: map['dosesAdministeredToday'] ?? 0,
      hasStartTime: map['hasStartTime'] ?? true,
      isSavedToHistory: map['isSavedToHistory'] ?? false,
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
    int? dosesAdministeredToday,
    bool? hasStartTime,
    bool? isSavedToHistory,
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
      dosesAdministeredToday: dosesAdministeredToday ?? this.dosesAdministeredToday,
      hasStartTime: hasStartTime ?? this.hasStartTime,
      isSavedToHistory: isSavedToHistory ?? this.isSavedToHistory,
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
        dosesAdministeredToday,
        hasStartTime,
        isSavedToHistory,
      ];
}
