import 'package:cloud_firestore/cloud_firestore.dart';

enum LaborType { contracted, nonContracted }

class Labor {
  final String id;
  final String projectId;
  final LaborType type;
  final String description;
  final double hoursWorked;
  final double costPerHour;
  final String? workerName;
  final DateTime workDate;
  final DateTime createdAt;
  final DateTime updatedAt;
  
  // New fields for enhanced labor tracking
  final String workCategory; // Custom category for contracted work
  final double? ratePerSqFt; // Rate per square foot for contracted work
  final double? workAreaSqFt; // Square feet completed for contracted work
  final double? fixedHourlyRate; // Fixed rate for non-contracted work
  final String subcontractorCompany; // Company name
  final int numberOfWorkers; // Number of workers on field
  final double totalHours; // Total hours worked

  Labor({
    required this.id,
    required this.projectId,
    required this.type,
    required this.description,
    required this.hoursWorked,
    required this.costPerHour,
    this.workerName,
    required this.workDate,
    required this.createdAt,
    required this.updatedAt,
    required this.workCategory,
    this.ratePerSqFt,
    this.workAreaSqFt,
    this.fixedHourlyRate,
    required this.subcontractorCompany,
    required this.numberOfWorkers,
    required this.totalHours,
  });

  // Calculate total cost based on work type
  double get totalCost {
    if (type == LaborType.contracted) {
      // For contracted work: rate per sq ft × work area
      if (ratePerSqFt != null && workAreaSqFt != null) {
        return ratePerSqFt! * workAreaSqFt!;
      }
      // Fallback to old calculation if new fields are not set
      return hoursWorked * costPerHour;
    } else {
      // For non-contracted work: fixed rate × total hours
      if (fixedHourlyRate != null) {
        return fixedHourlyRate! * totalHours;
      }
      // Fallback to old calculation if new fields are not set
      return hoursWorked * costPerHour;
    }
  }

  String get typeString => type == LaborType.contracted ? 'Contracted' : 'Non-Contracted';

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'projectId': projectId,
      'type': type.toString().split('.').last,
      'description': description,
      'hoursWorked': hoursWorked,
      'costPerHour': costPerHour,
      'workerName': workerName,
      'workDate': Timestamp.fromDate(workDate),
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'workCategory': workCategory,
      'ratePerSqFt': ratePerSqFt,
      'workAreaSqFt': workAreaSqFt,
      'fixedHourlyRate': fixedHourlyRate,
      'subcontractorCompany': subcontractorCompany,
      'numberOfWorkers': numberOfWorkers,
      'totalHours': totalHours,
    };
  }

  factory Labor.fromMap(Map<String, dynamic> map) {
    return Labor(
      id: map['id'] ?? '',
      projectId: map['projectId'] ?? '',
      type: map['type'] == 'contracted' ? LaborType.contracted : LaborType.nonContracted,
      description: map['description'] ?? '',
      hoursWorked: (map['hoursWorked'] ?? 0).toDouble(),
      costPerHour: (map['costPerHour'] ?? 0).toDouble(),
      workerName: map['workerName'],
      workDate: (map['workDate'] as Timestamp).toDate(),
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      updatedAt: (map['updatedAt'] as Timestamp).toDate(),
      workCategory: map['workCategory'] ?? '',
      ratePerSqFt: map['ratePerSqFt']?.toDouble(),
      workAreaSqFt: map['workAreaSqFt']?.toDouble(),
      fixedHourlyRate: map['fixedHourlyRate']?.toDouble(),
      subcontractorCompany: map['subcontractorCompany'] ?? '',
      numberOfWorkers: map['numberOfWorkers'] ?? 0,
      totalHours: (map['totalHours'] ?? 0).toDouble(),
    );
  }

  Labor copyWith({
    String? id,
    String? projectId,
    LaborType? type,
    String? description,
    double? hoursWorked,
    double? costPerHour,
    String? workerName,
    DateTime? workDate,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? workCategory,
    double? ratePerSqFt,
    double? workAreaSqFt,
    double? fixedHourlyRate,
    String? subcontractorCompany,
    int? numberOfWorkers,
    double? totalHours,
  }) {
    return Labor(
      id: id ?? this.id,
      projectId: projectId ?? this.projectId,
      type: type ?? this.type,
      description: description ?? this.description,
      hoursWorked: hoursWorked ?? this.hoursWorked,
      costPerHour: costPerHour ?? this.costPerHour,
      workerName: workerName ?? this.workerName,
      workDate: workDate ?? this.workDate,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      workCategory: workCategory ?? this.workCategory,
      ratePerSqFt: ratePerSqFt ?? this.ratePerSqFt,
      workAreaSqFt: workAreaSqFt ?? this.workAreaSqFt,
      fixedHourlyRate: fixedHourlyRate ?? this.fixedHourlyRate,
      subcontractorCompany: subcontractorCompany ?? this.subcontractorCompany,
      numberOfWorkers: numberOfWorkers ?? this.numberOfWorkers,
      totalHours: totalHours ?? this.totalHours,
    );
  }
}
