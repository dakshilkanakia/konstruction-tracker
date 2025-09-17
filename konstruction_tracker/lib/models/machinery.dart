import 'package:cloud_firestore/cloud_firestore.dart';

enum MachineryType { rental, owned }

class Machinery {
  final String id;
  final String projectId;
  final String name;
  final MachineryType type;
  final double hoursUsed;
  final double costPerHour;
  final String? operatorName;
  final DateTime createdAt;
  final DateTime updatedAt;

  Machinery({
    required this.id,
    required this.projectId,
    required this.name,
    required this.type,
    required this.hoursUsed,
    required this.costPerHour,
    this.operatorName,
    required this.createdAt,
    required this.updatedAt,
  });

  double get totalCost => hoursUsed * costPerHour;

  String get typeString => type == MachineryType.rental ? 'Rental' : 'Owned';

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'projectId': projectId,
      'name': name,
      'type': type.toString().split('.').last,
      'hoursUsed': hoursUsed,
      'costPerHour': costPerHour,
      'operatorName': operatorName,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  factory Machinery.fromMap(Map<String, dynamic> map) {
    return Machinery(
      id: map['id'] ?? '',
      projectId: map['projectId'] ?? '',
      name: map['name'] ?? '',
      type: map['type'] == 'rental' ? MachineryType.rental : MachineryType.owned,
      hoursUsed: (map['hoursUsed'] ?? 0).toDouble(),
      costPerHour: (map['costPerHour'] ?? 0).toDouble(),
      operatorName: map['operatorName'],
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      updatedAt: (map['updatedAt'] as Timestamp).toDate(),
    );
  }

  Machinery copyWith({
    String? id,
    String? projectId,
    String? name,
    MachineryType? type,
    double? hoursUsed,
    double? costPerHour,
    String? operatorName,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Machinery(
      id: id ?? this.id,
      projectId: projectId ?? this.projectId,
      name: name ?? this.name,
      type: type ?? this.type,
      hoursUsed: hoursUsed ?? this.hoursUsed,
      costPerHour: costPerHour ?? this.costPerHour,
      operatorName: operatorName ?? this.operatorName,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
