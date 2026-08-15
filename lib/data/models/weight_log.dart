import 'package:equatable/equatable.dart';

class WeightLog extends Equatable {
  final String id;
  final double weight;
  final DateTime date;
  final String note;

  const WeightLog({
    required this.id,
    required this.weight,
    required this.date,
    this.note = '',
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'weight': weight,
      'date': date.toIso8601String(),
      'note': note,
    };
  }

  factory WeightLog.fromMap(Map<String, dynamic> map) {
    return WeightLog(
      id: map['id'] ?? '',
      weight: (map['weight'] as num).toDouble(),
      date: DateTime.parse(map['date']),
      note: map['note'] ?? '',
    );
  }

  @override
  List<Object?> get props => [id, weight, date, note];
}
