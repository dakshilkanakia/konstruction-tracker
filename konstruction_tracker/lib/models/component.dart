import 'package:cloud_firestore/cloud_firestore.dart';

class Component {
  final String id;
  final String projectId;
  final String name;
  final double totalArea; // in square feet
  final double completedArea; // in square feet
  final double componentBudget; // total budget allocated for this component
  final double amountUsed; // amount actually spent on this component
  final double totalConcrete; // total concrete needed in cubic yards
  final double concretePoured; // concrete already poured in cubic yards
  final double originalCompletedArea; // original manual completed area (before labor sync)
  final double originalAmountUsed; // original manual amount used (before labor sync)
  final double originalConcretePoured; // original manual concrete poured (before labor sync)
  final bool isManuallyCompleted; // manual completion status
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
    required this.totalConcrete,
    required this.concretePoured,
    required this.originalCompletedArea,
    required this.originalAmountUsed,
    required this.originalConcretePoured,
    required this.isManuallyCompleted,
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

  // Concrete Progress (allows values above 100% for overpour)
  double get concreteProgressPercentage => totalConcrete > 0 ? (concretePoured / totalConcrete) : 0.0;
  double get remainingConcrete => totalConcrete - concretePoured;
  bool get isConcreteCompleted => concretePoured >= totalConcrete;
  bool get isConcreteWarning => concreteProgressPercentage > 0.8;
  
  // Overall Progress (average of area, budget, and concrete progress)
  double get overallProgressPercentage => (areaProgressPercentage + budgetProgressPercentage + concreteProgressPercentage) / 3;
  
  // Overall completion status (manual override or automatic)
  bool get isCompleted => isManuallyCompleted || (isAreaCompleted && !isBudgetExceeded);
  
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
      'totalConcrete': totalConcrete,
      'concretePoured': concretePoured,
      'originalCompletedArea': originalCompletedArea,
      'originalAmountUsed': originalAmountUsed,
      'originalConcretePoured': originalConcretePoured,
      'isManuallyCompleted': isManuallyCompleted,
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
      totalConcrete: (map['totalConcrete'] ?? 0.0).toDouble(),
      concretePoured: (map['concretePoured'] ?? 0.0).toDouble(),
      originalCompletedArea: (map['originalCompletedArea'] ?? 0.0).toDouble(),
      originalAmountUsed: (map['originalAmountUsed'] ?? 0.0).toDouble(),
      originalConcretePoured: (map['originalConcretePoured'] ?? 0.0).toDouble(),
      isManuallyCompleted: map['isManuallyCompleted'] ?? false,
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
    double? totalConcrete,
    double? concretePoured,
    double? originalCompletedArea,
    double? originalAmountUsed,
    double? originalConcretePoured,
    bool? isManuallyCompleted,
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
      totalConcrete: totalConcrete ?? this.totalConcrete,
      concretePoured: concretePoured ?? this.concretePoured,
      originalCompletedArea: originalCompletedArea ?? this.originalCompletedArea,
      originalAmountUsed: originalAmountUsed ?? this.originalAmountUsed,
      originalConcretePoured: originalConcretePoured ?? this.originalConcretePoured,
      isManuallyCompleted: isManuallyCompleted ?? this.isManuallyCompleted,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
