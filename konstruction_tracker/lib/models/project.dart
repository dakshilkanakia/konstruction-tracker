import 'package:cloud_firestore/cloud_firestore.dart';

class Project {
  final String id;
  final String name;
  final double totalBudget;
  final DateTime startDate;
  final String location;
  final String generalContractor;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isArchived;
  final List<Map<String, dynamic>> notes;
  final double? materialsBudget;
  final double? machineryBudget;

  Project({
    required this.id,
    required this.name,
    required this.totalBudget,
    required this.startDate,
    required this.location,
    required this.generalContractor,
    required this.createdAt,
    required this.updatedAt,
    this.isArchived = false,
    this.notes = const [],
    this.materialsBudget,
    this.machineryBudget,
  });

  // Calculate used budget (will be implemented with components and materials)
  double get usedBudget => 0.0; // TODO: Calculate from components, materials, labor

  double get remainingBudget => totalBudget - usedBudget;

  double get budgetProgress => totalBudget > 0 ? (usedBudget / totalBudget) : 0.0;

  int get daysSinceStart => DateTime.now().difference(startDate).inDays;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'totalBudget': totalBudget,
      'startDate': Timestamp.fromDate(startDate),
      'location': location,
      'generalContractor': generalContractor,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'isArchived': isArchived,
      'notes': notes,
      'materialsBudget': materialsBudget,
      'machineryBudget': machineryBudget,
    };
  }

  factory Project.fromMap(Map<String, dynamic> map) {
    return Project(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      totalBudget: (map['totalBudget'] ?? 0).toDouble(),
      startDate: (map['startDate'] as Timestamp).toDate(),
      location: map['location'] ?? '',
      generalContractor: map['generalContractor'] ?? '',
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      updatedAt: (map['updatedAt'] as Timestamp).toDate(),
      isArchived: map['isArchived'] ?? false,
      notes: List<Map<String, dynamic>>.from(map['notes'] ?? []),
      materialsBudget: map['materialsBudget']?.toDouble(),
      machineryBudget: map['machineryBudget']?.toDouble(),
    );
  }

  Project copyWith({
    String? id,
    String? name,
    double? totalBudget,
    DateTime? startDate,
    String? location,
    String? generalContractor,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isArchived,
    List<Map<String, dynamic>>? notes,
    double? materialsBudget,
    double? machineryBudget,
  }) {
    return Project(
      id: id ?? this.id,
      name: name ?? this.name,
      totalBudget: totalBudget ?? this.totalBudget,
      startDate: startDate ?? this.startDate,
      location: location ?? this.location,
      generalContractor: generalContractor ?? this.generalContractor,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isArchived: isArchived ?? this.isArchived,
      notes: notes ?? this.notes,
      materialsBudget: materialsBudget ?? this.materialsBudget,
      machineryBudget: machineryBudget ?? this.machineryBudget,
    );
  }
}
