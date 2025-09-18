import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/project.dart';
import '../models/component.dart';
import '../models/material.dart';
import '../models/machinery.dart';
import '../models/labor.dart';
import '../models/daily_log.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Projects CRUD
  Future<List<Project>> getProjects({bool includeArchived = false}) async {
    try {
      if (kDebugMode) print('Loading projects, includeArchived: $includeArchived');
      
      // Simplified query to avoid index issues
      QuerySnapshot snapshot = await _db.collection('projects').get();
      
      if (kDebugMode) print('Found ${snapshot.docs.length} total documents');
      
      List<Project> allProjects = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        if (kDebugMode) print('Project data: $data');
        return Project.fromMap(data);
      }).toList();
      
      // Filter in memory instead of using Firestore query
      List<Project> filteredProjects;
      if (includeArchived) {
        filteredProjects = allProjects;
      } else {
        filteredProjects = allProjects.where((p) => !p.isArchived).toList();
      }
      
      // Sort by updated date
      filteredProjects.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      
      if (kDebugMode) print('Returning ${filteredProjects.length} filtered projects');
      
      return filteredProjects;
    } catch (e) {
      if (kDebugMode) print('Error getting projects: $e');
      return [];
    }
  }

  Future<Project?> getProject(String projectId) async {
    try {
      DocumentSnapshot doc = await _db.collection('projects').doc(projectId).get();
      if (doc.exists) {
        return Project.fromMap(doc.data() as Map<String, dynamic>);
      }
    } catch (e) {
      if (kDebugMode) print('Error getting project: $e');
    }
    return null;
  }

  Future<bool> createProject(Project project) async {
    try {
      if (kDebugMode) print('Attempting to create project: ${project.name}');
      await _db.collection('projects').doc(project.id).set(project.toMap());
      if (kDebugMode) print('Project created successfully in Firestore');
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Error creating project: $e');
        print('Project data: ${project.toMap()}');
      }
      return false;
    }
  }

  Future<bool> updateProject(Project project) async {
    try {
      await _db.collection('projects').doc(project.id).update(
        project.copyWith(updatedAt: DateTime.now()).toMap(),
      );
      return true;
    } catch (e) {
      if (kDebugMode) print('Error updating project: $e');
      return false;
    }
  }

  Future<bool> deleteProject(String projectId) async {
    try {
      await _db.collection('projects').doc(projectId).delete();
      return true;
    } catch (e) {
      if (kDebugMode) print('Error deleting project: $e');
      return false;
    }
  }

  // Components CRUD
  Future<List<Component>> getProjectComponents(String projectId) async {
    try {
      if (kDebugMode) print('Loading components for project: $projectId');
      
      // Get all components and filter in memory to avoid index issues
      QuerySnapshot snapshot = await _db.collection('components').get();
      
      if (kDebugMode) print('Found ${snapshot.docs.length} total components');
      
      List<Component> allComponents = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        if (kDebugMode) print('Component data: $data');
        return Component.fromMap(data);
      }).toList();
      
      // Filter by project ID
      List<Component> projectComponents = allComponents
          .where((component) => component.projectId == projectId)
          .toList();
      
      // Sort by created date
      projectComponents.sort((a, b) => a.createdAt.compareTo(b.createdAt));
      
      if (kDebugMode) print('Returning ${projectComponents.length} components for project $projectId');
      
      return projectComponents;
    } catch (e) {
      if (kDebugMode) print('Error getting components: $e');
      return [];
    }
  }

  Future<bool> createComponent(Component component) async {
    try {
      if (kDebugMode) print('Creating component: ${component.name} for project: ${component.projectId}');
      await _db.collection('components').doc(component.id).set(component.toMap());
      if (kDebugMode) print('Component created successfully in Firestore');
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Error creating component: $e');
        print('Component data: ${component.toMap()}');
      }
      return false;
    }
  }

  Future<bool> updateComponent(Component component) async {
    try {
      await _db.collection('components').doc(component.id).update(
        component.copyWith(updatedAt: DateTime.now()).toMap(),
      );
      return true;
    } catch (e) {
      if (kDebugMode) print('Error updating component: $e');
      return false;
    }
  }

  // Materials CRUD
  Future<List<Material>> getProjectMaterials(String projectId) async {
    try {
      QuerySnapshot snapshot = await _db
          .collection('materials')
          .where('projectId', isEqualTo: projectId)
          .get();
      
      List<Material> materials = [];
      for (var doc in snapshot.docs) {
        try {
          final material = Material.fromMap(doc.data() as Map<String, dynamic>);
          materials.add(material);
        } catch (e) {
          if (kDebugMode) print('Error parsing material ${doc.id}: $e');
        }
      }
      
      print('🔥 FIRESTORE: Fetched ${materials.length} materials from Firebase for project $projectId');
      return materials;
    } catch (e) {
      if (kDebugMode) print('Error getting materials: $e');
      return [];
    }
  }

  Future<bool> createMaterial(Material material) async {
    try {
      await _db.collection('materials').doc(material.id).set(material.toMap());
      print('✅ CREATED: Material "${material.name ?? 'Unnamed'}" saved to Firebase with ID: ${material.id}');
      return true;
    } catch (e) {
      print('❌ ERROR: Failed to create material: $e');
      return false;
    }
  }

  Future<bool> updateMaterial(Material material) async {
    try {
      await _db.collection('materials').doc(material.id).update(
        material.copyWith(updatedAt: DateTime.now()).toMap(),
      );
      return true;
    } catch (e) {
      if (kDebugMode) print('Error updating material: $e');
      return false;
    }
  }

  Future<bool> deleteMaterial(String materialId) async {
    try {
      await _db.collection('materials').doc(materialId).delete();
      return true;
    } catch (e) {
      if (kDebugMode) print('Error deleting material: $e');
      return false;
    }
  }

  // Machinery CRUD
  Future<List<Machinery>> getProjectMachinery(String projectId) async {
    try {
      QuerySnapshot snapshot = await _db
          .collection('machinery')
          .where('projectId', isEqualTo: projectId)
          .get();
      return snapshot.docs.map((doc) => Machinery.fromMap(doc.data() as Map<String, dynamic>)).toList();
    } catch (e) {
      if (kDebugMode) print('Error getting machinery: $e');
      return [];
    }
  }

  Future<bool> createMachinery(Machinery machinery) async {
    try {
      await _db.collection('machinery').doc(machinery.id).set(machinery.toMap());
      return true;
    } catch (e) {
      if (kDebugMode) print('Error creating machinery: $e');
      return false;
    }
  }

  Future<bool> updateMachinery(Machinery machinery) async {
    try {
      await _db.collection('machinery').doc(machinery.id).update(
        machinery.copyWith(updatedAt: DateTime.now()).toMap(),
      );
      return true;
    } catch (e) {
      if (kDebugMode) print('Error updating machinery: $e');
      return false;
    }
  }

  Future<bool> deleteMachinery(String machineryId) async {
    try {
      await _db.collection('machinery').doc(machineryId).delete();
      return true;
    } catch (e) {
      if (kDebugMode) print('Error deleting machinery: $e');
      return false;
    }
  }

  // Labor CRUD
  Future<List<Labor>> getProjectLabor(String projectId) async {
    try {
      QuerySnapshot snapshot = await _db
          .collection('labor')
          .where('projectId', isEqualTo: projectId)
          .get(); // Removed orderBy to avoid index issues with nullable workDate
      
      List<Labor> laborList = [];
      for (var doc in snapshot.docs) {
        try {
          final labor = Labor.fromMap(doc.data() as Map<String, dynamic>);
          laborList.add(labor);
        } catch (e) {
          if (kDebugMode) print('Error parsing labor ${doc.id}: $e');
        }
      }
      
      print('🔥 FIRESTORE: Fetched ${laborList.length} labor entries from Firebase for project $projectId');
      return laborList;
    } catch (e) {
      print('❌ FIRESTORE: Error getting labor: $e');
      if (kDebugMode) print('Error getting labor: $e');
      return [];
    }
  }

  Future<bool> createLabor(Labor labor) async {
    try {
      await _db.collection('labor').doc(labor.id).set(labor.toMap());
      print('✅ FIRESTORE: Labor "${labor.workCategory}" (${labor.entryTypeString}) saved to Firebase with ID: ${labor.id}');
      return true;
    } catch (e) {
      print('❌ FIRESTORE: Failed to create labor: $e');
      if (kDebugMode) print('Error creating labor: $e');
      return false;
    }
  }

  Future<bool> updateLabor(Labor labor) async {
    try {
      await _db.collection('labor').doc(labor.id).update(
        labor.copyWith(updatedAt: DateTime.now()).toMap(),
      );
      return true;
    } catch (e) {
      if (kDebugMode) print('Error updating labor: $e');
      return false;
    }
  }

  Future<bool> deleteLabor(String laborId) async {
    try {
      await _db.collection('labor').doc(laborId).delete();
      return true;
    } catch (e) {
      if (kDebugMode) print('Error deleting labor: $e');
      return false;
    }
  }

  // Daily Logs CRUD
  Future<List<DailyLog>> getProjectDailyLogs(String projectId) async {
    try {
      QuerySnapshot snapshot = await _db
          .collection('dailyLogs')
          .where('projectId', isEqualTo: projectId)
          .orderBy('date', descending: true)
          .get();
      return snapshot.docs.map((doc) => DailyLog.fromMap(doc.data() as Map<String, dynamic>)).toList();
    } catch (e) {
      if (kDebugMode) print('Error getting daily logs: $e');
      return [];
    }
  }

  Future<bool> createDailyLog(DailyLog dailyLog) async {
    try {
      await _db.collection('dailyLogs').doc(dailyLog.id).set(dailyLog.toMap());
      return true;
    } catch (e) {
      if (kDebugMode) print('Error creating daily log: $e');
      return false;
    }
  }

  Future<bool> updateDailyLog(DailyLog dailyLog) async {
    try {
      await _db.collection('dailyLogs').doc(dailyLog.id).update(
        dailyLog.copyWith(updatedAt: DateTime.now()).toMap(),
      );
      return true;
    } catch (e) {
      if (kDebugMode) print('Error updating daily log: $e');
      return false;
    }
  }

  Future<bool> deleteDailyLog(String dailyLogId) async {
    try {
      await _db.collection('dailyLogs').doc(dailyLogId).delete();
      return true;
    } catch (e) {
      if (kDebugMode) print('Error deleting daily log: $e');
      return false;
    }
  }

  // Component-Labor Synchronization
  Future<bool> syncLaborProgressToComponent(String projectId, String workCategory, {
    double? completedSqFt,
    bool? recalculateAmountUsed,
  }) async {
    try {
      // Find component with matching name
      final components = await getProjectComponents(projectId);
      final matchingComponent = components.where((c) => c.name == workCategory).firstOrNull;
      
      if (matchingComponent == null) {
        if (kDebugMode) print('🔄 SYNC: No component found with name "$workCategory" - skipping sync');
        return true; // Not an error, just no matching component
      }

      // Calculate new values
      double newCompletedArea = matchingComponent.completedArea;
      double newAmountUsed = matchingComponent.amountUsed;

      // Update completed area from contract progress
      if (completedSqFt != null) {
        // For contract progress, we get the total completed square feet
        // We need to sum all progress entries for this work category
        final allLabor = await getProjectLabor(projectId);
        final contractProgressEntries = allLabor
            .where((l) => l.workCategory == workCategory && l.isProgress && l.isContracted)
            .toList();
        
        final totalCompletedSqFt = contractProgressEntries
            .fold(0.0, (sum, entry) => sum + (entry.completedSqFt ?? 0.0));
        
        newCompletedArea = totalCompletedSqFt;
      }

      // Recalculate amount used from all labor costs for this component
      if (recalculateAmountUsed == true) {
        final allLabor = await getProjectLabor(projectId);
        final workProgressEntries = allLabor
            .where((l) => l.workCategory == workCategory && l.isWorkProgress)
            .toList();
        
        final totalLaborCost = workProgressEntries
            .fold(0.0, (sum, entry) => sum + entry.totalCost);
        
        newAmountUsed = totalLaborCost;
      }

      // Update component if values changed
      if (newCompletedArea != matchingComponent.completedArea || newAmountUsed != matchingComponent.amountUsed) {
        final updatedComponent = matchingComponent.copyWith(
          completedArea: newCompletedArea,
          amountUsed: newAmountUsed,
          updatedAt: DateTime.now(),
        );

        final success = await updateComponent(updatedComponent);
        if (success) {
          if (kDebugMode) print('✅ SYNC: Updated component "${workCategory}" - Area: ${newCompletedArea.toStringAsFixed(1)} sq ft, Used: \$${newAmountUsed.toStringAsFixed(2)}');
        }
        return success;
      } else {
        if (kDebugMode) print('🔄 SYNC: No changes needed for component "$workCategory"');
        return true;
      }
    } catch (e) {
      if (kDebugMode) print('❌ SYNC: Error syncing labor to component: $e');
      return false;
    }
  }
}
