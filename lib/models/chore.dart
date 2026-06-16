import 'package:cloud_firestore/cloud_firestore.dart';

enum ChoreFrequency { oneOff, daily, weekly, monthly }

ChoreFrequency choreFrequencyFromString(String value) {
  return ChoreFrequency.values.firstWhere(
    (f) => f.name == value,
    orElse: () => ChoreFrequency.oneOff,
  );
}

class Chore {
  final String id;
  final String title;
  final String assignedTo;
  final ChoreFrequency frequency;
  final DateTime? dueDate;
  final bool completed;
  final DateTime? lastCompletedAt;

  Chore({
    required this.id,
    required this.title,
    required this.assignedTo,
    required this.frequency,
    required this.dueDate,
    required this.completed,
    required this.lastCompletedAt,
  });

  factory Chore.fromMap(String id, Map<String, dynamic> data) {
    return Chore(
      id: id,
      title: data['title'] as String? ?? '',
      assignedTo: data['assignedTo'] as String? ?? '',
      frequency: choreFrequencyFromString(data['frequency'] as String? ?? ''),
      dueDate: (data['dueDate'] as Timestamp?)?.toDate(),
      completed: data['completed'] as bool? ?? false,
      lastCompletedAt: (data['lastCompletedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'assignedTo': assignedTo,
      'frequency': frequency.name,
      'dueDate': dueDate != null ? Timestamp.fromDate(dueDate!) : null,
      'completed': completed,
      'lastCompletedAt': lastCompletedAt != null
          ? Timestamp.fromDate(lastCompletedAt!)
          : null,
    };
  }
}
