import 'package:cloud_firestore/cloud_firestore.dart';

enum MachineryType { rental, owned }

class Machinery {
  final String id;
  final String projectId;
  final String? name;
  final MachineryType? type;
  final double? hoursUsed;
  final double? costPerHour;
  final double? totalCostOverride; // Direct total cost input
  final String? operatorName;
  final DateTime createdAt;
  final DateTime updatedAt;

  Machinery({
    required this.id,
    required this.projectId,
    this.name,
    this.type,
    this.hoursUsed,
    this.costPerHour,
    this.totalCostOverride,
    this.operatorName,
    required this.createdAt,
    required this.updatedAt,
  });

  double get totalCost {
    // If both hours and cost per hour are provided, calculate
    if (hoursUsed != null && costPerHour != null) {
      return hoursUsed! * costPerHour!;
    }
    // Otherwise use direct total cost input
    if (totalCostOverride != null) {
      return totalCostOverride!;
    }
    return 0.0;
  }

  String get typeString {
    if (type == null) return 'Unknown';
    return type == MachineryType.rental ? 'Rental' : 'Owned';
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'projectId': projectId,
      'name': name,
      'type': type?.toString().split('.').last,
      'hoursUsed': hoursUsed,
      'costPerHour': costPerHour,
      'totalCostOverride': totalCostOverride,
      'operatorName': operatorName,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  factory Machinery.fromMap(Map<String, dynamic> map) {
    return Machinery(
      id: map['id'] ?? '',
      projectId: map['projectId'] ?? '',
      name: map['name'],
      type: map['type'] != null 
          ? (map['type'] == 'rental' ? MachineryType.rental : MachineryType.owned)
          : null,
      hoursUsed: map['hoursUsed']?.toDouble(),
      costPerHour: map['costPerHour']?.toDouble(),
      totalCostOverride: map['totalCostOverride']?.toDouble(),
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
    double? totalCostOverride,
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
      totalCostOverride: totalCostOverride ?? this.totalCostOverride,
      operatorName: operatorName ?? this.operatorName,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
