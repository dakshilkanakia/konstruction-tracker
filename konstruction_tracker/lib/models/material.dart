import 'package:cloud_firestore/cloud_firestore.dart';

class Material {
  final String id;
  final String projectId;
  final String? name;
  final String? unit; // e.g., "cubic yards", "tons", "pieces"
  final double? quantityOrdered;
  final double? costPerUnit;
  final double? totalCost; // Manual total cost field
  final List<String> receiptUrls; // Firebase Storage URLs
  final DateTime createdAt;
  final DateTime updatedAt;

  Material({
    required this.id,
    required this.projectId,
    this.name,
    this.unit,
    this.quantityOrdered,
    this.costPerUnit,
    this.totalCost,
    this.receiptUrls = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  double get calculatedTotalCost {
    if (quantityOrdered != null && costPerUnit != null) {
      return quantityOrdered! * costPerUnit!;
    }
    return 0.0;
  }
  
  double get finalTotalCost {
    // Use manual total cost if provided, otherwise use calculated
    return totalCost ?? calculatedTotalCost;
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'projectId': projectId,
      'name': name,
      'unit': unit,
      'quantityOrdered': quantityOrdered,
      'costPerUnit': costPerUnit,
      'totalCost': totalCost,
      'receiptUrls': receiptUrls,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  factory Material.fromMap(Map<String, dynamic> map) {
    return Material(
      id: map['id'] ?? '',
      projectId: map['projectId'] ?? '',
      name: map['name'],
      unit: map['unit'],
      quantityOrdered: map['quantityOrdered']?.toDouble(),
      costPerUnit: map['costPerUnit']?.toDouble(),
      totalCost: map['totalCost']?.toDouble(),
      receiptUrls: List<String>.from(map['receiptUrls'] ?? []),
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      updatedAt: (map['updatedAt'] as Timestamp).toDate(),
    );
  }

  Material copyWith({
    String? id,
    String? projectId,
    String? name,
    String? unit,
    double? quantityOrdered,
    double? costPerUnit,
    double? totalCost,
    List<String>? receiptUrls,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Material(
      id: id ?? this.id,
      projectId: projectId ?? this.projectId,
      name: name ?? this.name,
      unit: unit ?? this.unit,
      quantityOrdered: quantityOrdered ?? this.quantityOrdered,
      costPerUnit: costPerUnit ?? this.costPerUnit,
      totalCost: totalCost ?? this.totalCost,
      receiptUrls: receiptUrls ?? this.receiptUrls,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
