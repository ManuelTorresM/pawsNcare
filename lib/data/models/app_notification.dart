import 'package:equatable/equatable.dart';

enum NotificationCategory {
  medication,
  vaccine,
  feeding,
  hydration,
  system,
}

extension NotificationCategoryExtension on NotificationCategory {
  String get displayName {
    switch (this) {
      case NotificationCategory.medication:
        return 'Medication';
      case NotificationCategory.vaccine:
        return 'Vaccination';
      case NotificationCategory.feeding:
        return 'Feeding';
      case NotificationCategory.hydration:
        return 'Hydration';
      case NotificationCategory.system:
        return 'Alert';
    }
  }
}

class AppNotification extends Equatable {
  final String id;
  final String title;
  final String body;
  final String petName;
  final String petAvatarUrl;
  final NotificationCategory category;
  final DateTime timestamp;
  final bool isRead;

  const AppNotification({
    required this.id,
    required this.title,
    required this.body,
    this.petName = '',
    this.petAvatarUrl = '',
    required this.category,
    required this.timestamp,
    this.isRead = false,
  });

  AppNotification copyWith({
    String? id,
    String? title,
    String? body,
    String? petName,
    String? petAvatarUrl,
    NotificationCategory? category,
    DateTime? timestamp,
    bool? isRead,
  }) {
    return AppNotification(
      id: id ?? this.id,
      title: title ?? this.title,
      body: body ?? this.body,
      petName: petName ?? this.petName,
      petAvatarUrl: petAvatarUrl ?? this.petAvatarUrl,
      category: category ?? this.category,
      timestamp: timestamp ?? this.timestamp,
      isRead: isRead ?? this.isRead,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'body': body,
      'petName': petName,
      'petAvatarUrl': petAvatarUrl,
      'category': category.name,
      'timestamp': timestamp.toIso8601String(),
      'isRead': isRead,
    };
  }

  factory AppNotification.fromMap(Map<String, dynamic> map) {
    return AppNotification(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      body: map['body'] ?? '',
      petName: map['petName'] ?? '',
      petAvatarUrl: map['petAvatarUrl'] ?? '',
      category: NotificationCategory.values.firstWhere(
        (c) => c.name == map['category'],
        orElse: () => NotificationCategory.system,
      ),
      timestamp: map['timestamp'] != null
          ? DateTime.parse(map['timestamp'])
          : DateTime.now(),
      isRead: map['isRead'] ?? false,
    );
  }

  @override
  List<Object?> get props => [
        id,
        title,
        body,
        petName,
        petAvatarUrl,
        category,
        timestamp,
        isRead,
      ];
}
