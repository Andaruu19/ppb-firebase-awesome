import 'package:cloud_firestore/cloud_firestore.dart';

class Task{
  String? id;
  String? title;
  String? description;
  bool? isCompleted;
  DateTime reminderDateTime;
  int? notificationId;

  Task({
    this.id,
    required this.title,
    this.description,
    required this.reminderDateTime,
    this.isCompleted = false,
    this.notificationId,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'isCompleted': isCompleted,
      'reminderDateTime': Timestamp.fromDate(reminderDateTime),
      'notificationId': notificationId,
    };
  }

  factory Task.fromMap(Map<String, dynamic> map, String documentId) {
    return Task(
      id: documentId,
      title: map['title'],
      description: map['description'],
      reminderDateTime: (map['reminderDateTime'] as Timestamp).toDate(),
      isCompleted: map['isDone'] ?? false,
      notificationId: map['notificationId'],
    );
  }

}