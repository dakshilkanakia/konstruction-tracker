import 'package:cloud_firestore/cloud_firestore.dart';

class Component {
  final String id;
  final String projectId;
  final String name;
  final double totalArea; // in square feet
  final double completedArea; // in square feet
  final double componentBudget; // total budget allocated for this component
  final double amountUsed; // amount actually spent on this component
  final DateTime createdAt;
  final DateTime updatedAt;

  Component({
    required this.id,
    required this.projectId,
    required this.name,
    required this.totalArea,
    required this.completedArea,
    required this.componentBudget,
    required this.amountUsed,
    required this.createdAt,
    required this.updatedAt,
  });

  // Area Progress
  double get areaProgressPercentage => totalArea > 0 ? (completedArea / totalArea) : 0.0;
  double get remainingArea => totalArea - completedArea;
  bool get isAreaCompleted => completedArea >= totalArea;

  // Budget Progress
  double get budgetProgressPercentage => componentBudget > 0 ? (amountUsed / componentBudget) : 0.0;
  double get remainingBudget => componentBudget - amountUsed;
  bool get isBudgetExceeded => amountUsed > componentBudget;
  bool get isBudgetWarning => budgetProgressPercentage > 0.8;
  
  // Overall Progress (average of area and budget progress)
  double get overallProgressPercentage => (areaProgressPercentage + budgetProgressPercentage) / 2;
  
  // For backward compatibility and budget calculations
  double get totalCost => amountUsed;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'projectId': projectId,
      'name': name,
      'totalArea': totalArea,
      'completedArea': completedArea,
      'componentBudget': componentBudget,
      'amountUsed': amountUsed,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  factory Component.fromMap(Map<String, dynamic> map) {
    return Component(
      id: map['id'] ?? '',
      projectId: map['projectId'] ?? '',
      name: map['name'] ?? '',
      totalArea: (map['totalArea'] ?? 0).toDouble(),
      completedArea: (map['completedArea'] ?? 0).toDouble(),
      componentBudget: (map['componentBudget'] ?? 0.0).toDouble(),
      amountUsed: (map['amountUsed'] ?? 0.0).toDouble(),
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      updatedAt: (map['updatedAt'] as Timestamp).toDate(),
    );
  }

  Component copyWith({
    String? id,
    String? projectId,
    String? name,
    double? totalArea,
    double? completedArea,
    double? componentBudget,
    double? amountUsed,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Component(
      id: id ?? this.id,
      projectId: projectId ?? this.projectId,
      name: name ?? this.name,
      totalArea: totalArea ?? this.totalArea,
      completedArea: completedArea ?? this.completedArea,
      componentBudget: componentBudget ?? this.componentBudget,
      amountUsed: amountUsed ?? this.amountUsed,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
