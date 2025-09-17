import 'package:cloud_firestore/cloud_firestore.dart';

class DailyLog {
  final String id;
  final String projectId;
  final DateTime date;
  final String? weather;
  final String? workCompleted;
  final String? materialsUsed;
  final String? issuesAndConcerns;
  final DateTime createdAt;
  final DateTime updatedAt;

  DailyLog({
    required this.id,
    required this.projectId,
    required this.date,
    this.weather,
    this.workCompleted,
    this.materialsUsed,
    this.issuesAndConcerns,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get hasContent => 
      weather?.isNotEmpty == true ||
      workCompleted?.isNotEmpty == true ||
      materialsUsed?.isNotEmpty == true ||
      issuesAndConcerns?.isNotEmpty == true;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'projectId': projectId,
      'date': Timestamp.fromDate(date),
      'weather': weather,
      'workCompleted': workCompleted,
      'materialsUsed': materialsUsed,
      'issuesAndConcerns': issuesAndConcerns,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  factory DailyLog.fromMap(Map<String, dynamic> map) {
    return DailyLog(
      id: map['id'] ?? '',
      projectId: map['projectId'] ?? '',
      date: (map['date'] as Timestamp).toDate(),
      weather: map['weather'],
      workCompleted: map['workCompleted'],
      materialsUsed: map['materialsUsed'],
      issuesAndConcerns: map['issuesAndConcerns'],
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      updatedAt: (map['updatedAt'] as Timestamp).toDate(),
    );
  }

  DailyLog copyWith({
    String? id,
    String? projectId,
    DateTime? date,
    String? weather,
    String? workCompleted,
    String? materialsUsed,
    String? issuesAndConcerns,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return DailyLog(
      id: id ?? this.id,
      projectId: projectId ?? this.projectId,
      date: date ?? this.date,
      weather: weather ?? this.weather,
      workCompleted: workCompleted ?? this.workCompleted,
      materialsUsed: materialsUsed ?? this.materialsUsed,
      issuesAndConcerns: issuesAndConcerns ?? this.issuesAndConcerns,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
