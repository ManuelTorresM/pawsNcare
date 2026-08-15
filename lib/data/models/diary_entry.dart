import 'package:equatable/equatable.dart';

class DiaryEntry extends Equatable {
  final String id;
  final String petId;
  final String title;
  final String category; // 'food', 'walk', 'med', 'vet', 'hydration'
  final String note;
  final DateTime timestamp;

  const DiaryEntry({
    required this.id,
    required this.petId,
    required this.title,
    required this.category,
    required this.note,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'petId': petId,
      'title': title,
      'category': category,
      'note': note,
      'timestamp': timestamp.toIso8601String(),
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
    );
  }

  @override
  List<Object?> get props => [id, petId, title, category, note, timestamp];
}
