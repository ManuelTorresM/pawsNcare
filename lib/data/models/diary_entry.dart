import 'package:equatable/equatable.dart';

class DiaryEntry extends Equatable {
  final String id;
  final String petId;
  final String title;
  final String category; // 'food', 'walk', 'med', 'vet', 'hydration', 'medical_event'
  final String note;
  final DateTime timestamp;
  final String severity; // 'NORMAL', 'CONCERNING', 'EMERGENCY', etc.
  final bool isActive; // true = active incident, false = deactivated / resolved

  const DiaryEntry({
    required this.id,
    required this.petId,
    required this.title,
    required this.category,
    required this.note,
    required this.timestamp,
    this.severity = 'MILD',
    this.isActive = true,
  });

  DiaryEntry copyWith({
    String? id,
    String? petId,
    String? title,
    String? category,
    String? note,
    DateTime? timestamp,
    String? severity,
    bool? isActive,
  }) {
    return DiaryEntry(
      id: id ?? this.id,
      petId: petId ?? this.petId,
      title: title ?? this.title,
      category: category ?? this.category,
      note: note ?? this.note,
      timestamp: timestamp ?? this.timestamp,
      severity: severity ?? this.severity,
      isActive: isActive ?? this.isActive,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'petId': petId,
      'title': title,
      'category': category,
      'note': note,
      'timestamp': timestamp.toIso8601String(),
      'severity': severity,
      'isActive': isActive,
    };
  }

  factory DiaryEntry.fromMap(Map<String, dynamic> map) {
    return DiaryEntry(
      id: map['id'] ?? '',
      petId: map['petId'] ?? '',
      title: map['title'] ?? '',
      category: map['category'] ?? '',
      note: map['note'] ?? '',
      timestamp: DateTime.parse(map['timestamp']),
      severity: map['severity'] ?? 'MILD',
      isActive: map['isActive'] ?? true,
    );
  }

  @override
  List<Object?> get props => [id, petId, title, category, note, timestamp, severity, isActive];
}
