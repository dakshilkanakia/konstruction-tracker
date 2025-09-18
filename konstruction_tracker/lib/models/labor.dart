import 'package:cloud_firestore/cloud_firestore.dart';

enum LaborType { contracted, nonContracted }
enum LaborEntryType { contract, progress } // New: Contract setup vs Progress entry

class Labor {
  final String id;
  final String projectId;
  final LaborType type;
  final LaborEntryType entryType; // Contract setup vs Progress entry
  final String workCategory; // Custom category (e.g., "Sidewalk Installation")
  
  // Contract setup fields (for entryType = contract)
  final double? totalSqFt; // Total square feet for the contract
  final double? ratePerSqFt; // Rate per square foot
  
  // Progress entry fields (for entryType = progress)
  final String? contractId; // Links to the contract this progress belongs to
  final double? completedSqFt; // Square feet completed in this entry
  final DateTime? workDate; // Date work was completed
  final String? subcontractorCompany; // Optional company name
  
  // Non-contracted work fields
  final double? totalBudget; // Total budget for work setup (non-contracted)
  final double? hoursWorked; // For non-contracted work progress
  final double? fixedHourlyRate; // Fixed hourly rate for non-contracted
  final int? numberOfWorkers; // Number of workers
  final String? workSetupId; // Links to the work setup this progress belongs to (non-contracted)
  
  // Legacy fields (keeping for backward compatibility)
  final String? description;
  final double? costPerHour;
  final String? workerName;
  
  final DateTime createdAt;
  final DateTime updatedAt;

  Labor({
    required this.id,
    required this.projectId,
    required this.type,
    required this.entryType,
    required this.workCategory,
    
    // Contract setup fields
    this.totalSqFt,
    this.ratePerSqFt,
    
    // Progress entry fields
    this.contractId,
    this.completedSqFt,
    this.workDate,
    this.subcontractorCompany,
    
    // Non-contracted work fields
    this.totalBudget,
    this.hoursWorked,
    this.fixedHourlyRate,
    this.numberOfWorkers,
    this.workSetupId,
    
    // Legacy fields
    this.description,
    this.costPerHour,
    this.workerName,
    
    required this.createdAt,
    required this.updatedAt,
  });

  // Calculate total cost based on work type and entry type
  double get totalCost {
    if (type == LaborType.contracted) {
      if (entryType == LaborEntryType.contract) {
        // Contract setup: total contract value
        if (ratePerSqFt != null && totalSqFt != null) {
          return ratePerSqFt! * totalSqFt!;
        }
      } else if (entryType == LaborEntryType.progress) {
        // Progress entry: cost for completed work
        if (ratePerSqFt != null && completedSqFt != null) {
          return ratePerSqFt! * completedSqFt!;
        }
      }
    } else {
      // Non-contracted work
      if (entryType == LaborEntryType.contract) {
        // Work setup: total budget value
        if (totalBudget != null) {
          return totalBudget!;
        }
      } else if (entryType == LaborEntryType.progress) {
        // Work progress: fixed rate × hours worked
        if (fixedHourlyRate != null && hoursWorked != null) {
          return fixedHourlyRate! * hoursWorked!;
        }
      }
    }
    
    // Fallback to legacy calculation
    if (hoursWorked != null && costPerHour != null) {
      return hoursWorked! * costPerHour!;
    }
    
    return 0.0;
  }

  String get typeString => type == LaborType.contracted ? 'Contracted' : 'Non-Contracted';
  String get entryTypeString => entryType == LaborEntryType.contract ? 'Contract' : 'Progress';
  
  // Helper getters for contracts and work setups
  bool get isContract => entryType == LaborEntryType.contract;
  bool get isProgress => entryType == LaborEntryType.progress;
  bool get isContracted => type == LaborType.contracted;
  bool get isWorkSetup => !isContracted && isContract; // Non-contracted work setup
  bool get isWorkProgress => !isContracted && isProgress; // Non-contracted work progress
  
  // Calculate max hours available for work setup
  double get maxHours {
    if (isWorkSetup && totalBudget != null && fixedHourlyRate != null && fixedHourlyRate! > 0) {
      return totalBudget! / fixedHourlyRate!;
    }
    return 0.0;
  }
  
  // Progress calculation helpers (for use with a list of progress entries)
  static double calculateTotalCompleted(List<Labor> progressEntries) {
    return progressEntries
        .where((entry) => entry.isProgress && entry.completedSqFt != null)
        .fold(0.0, (sum, entry) => sum + entry.completedSqFt!);
  }
  
  // Work progress calculation helpers (for non-contracted work)
  static double calculateTotalHoursWorked(List<Labor> workProgressEntries) {
    return workProgressEntries
        .where((entry) => entry.isWorkProgress && entry.hoursWorked != null)
        .fold(0.0, (sum, entry) => sum + entry.hoursWorked!);
  }
  
  static double calculateWorkProgressPercentage(double maxHours, double workedHours) {
    if (maxHours <= 0) return 0.0;
    return (workedHours / maxHours * 100).clamp(0.0, 100.0);
  }
  
  static double calculateProgressPercentage(double totalSqFt, double completedSqFt) {
    if (totalSqFt <= 0) return 0.0;
    return (completedSqFt / totalSqFt * 100).clamp(0.0, 100.0);
  }
  
  static double calculateRemainingBudget(double totalBudget, double completedBudget) {
    return (totalBudget - completedBudget).clamp(0.0, totalBudget);
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'projectId': projectId,
      'type': type.toString().split('.').last,
      'entryType': entryType.toString().split('.').last,
      'workCategory': workCategory,
      
      // Contract setup fields
      'totalSqFt': totalSqFt,
      'ratePerSqFt': ratePerSqFt,
      
      // Progress entry fields
      'contractId': contractId,
      'completedSqFt': completedSqFt,
      'workDate': workDate != null ? Timestamp.fromDate(workDate!) : null,
      'subcontractorCompany': subcontractorCompany,
      
      // Non-contracted work fields
      'totalBudget': totalBudget,
      'hoursWorked': hoursWorked,
      'fixedHourlyRate': fixedHourlyRate,
      'numberOfWorkers': numberOfWorkers,
      'workSetupId': workSetupId,
      
      // Legacy fields
      'description': description,
      'costPerHour': costPerHour,
      'workerName': workerName,
      
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  factory Labor.fromMap(Map<String, dynamic> map) {
    return Labor(
      id: map['id'] ?? '',
      projectId: map['projectId'] ?? '',
      type: map['type'] == 'contracted' ? LaborType.contracted : LaborType.nonContracted,
      entryType: map['entryType'] == 'progress' ? LaborEntryType.progress : LaborEntryType.contract,
      workCategory: map['workCategory'] ?? '',
      
      // Contract setup fields
      totalSqFt: map['totalSqFt']?.toDouble(),
      ratePerSqFt: map['ratePerSqFt']?.toDouble(),
      
      // Progress entry fields
      contractId: map['contractId'],
      completedSqFt: map['completedSqFt']?.toDouble(),
      workDate: map['workDate'] != null ? (map['workDate'] as Timestamp).toDate() : null,
      subcontractorCompany: map['subcontractorCompany'],
      
      // Non-contracted work fields
      totalBudget: map['totalBudget']?.toDouble(),
      hoursWorked: map['hoursWorked']?.toDouble(),
      fixedHourlyRate: map['fixedHourlyRate']?.toDouble(),
      numberOfWorkers: map['numberOfWorkers'],
      workSetupId: map['workSetupId'],
      
      // Legacy fields
      description: map['description'],
      costPerHour: map['costPerHour']?.toDouble(),
      workerName: map['workerName'],
      
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      updatedAt: (map['updatedAt'] as Timestamp).toDate(),
    );
  }

  Labor copyWith({
    String? id,
    String? projectId,
    LaborType? type,
    LaborEntryType? entryType,
    String? workCategory,
    
    // Contract setup fields
    double? totalSqFt,
    double? ratePerSqFt,
    
    // Progress entry fields
    String? contractId,
    double? completedSqFt,
    DateTime? workDate,
    String? subcontractorCompany,
    
    // Non-contracted work fields
    double? totalBudget,
    double? hoursWorked,
    double? fixedHourlyRate,
    int? numberOfWorkers,
    String? workSetupId,
    
    // Legacy fields
    String? description,
    double? costPerHour,
    String? workerName,
    
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Labor(
      id: id ?? this.id,
      projectId: projectId ?? this.projectId,
      type: type ?? this.type,
      entryType: entryType ?? this.entryType,
      workCategory: workCategory ?? this.workCategory,
      
      // Contract setup fields
      totalSqFt: totalSqFt ?? this.totalSqFt,
      ratePerSqFt: ratePerSqFt ?? this.ratePerSqFt,
      
      // Progress entry fields
      contractId: contractId ?? this.contractId,
      completedSqFt: completedSqFt ?? this.completedSqFt,
      workDate: workDate ?? this.workDate,
      subcontractorCompany: subcontractorCompany ?? this.subcontractorCompany,
      
      // Non-contracted work fields
      totalBudget: totalBudget ?? this.totalBudget,
      hoursWorked: hoursWorked ?? this.hoursWorked,
      fixedHourlyRate: fixedHourlyRate ?? this.fixedHourlyRate,
      numberOfWorkers: numberOfWorkers ?? this.numberOfWorkers,
      workSetupId: workSetupId ?? this.workSetupId,
      
      // Legacy fields
      description: description ?? this.description,
      costPerHour: costPerHour ?? this.costPerHour,
      workerName: workerName ?? this.workerName,
      
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
