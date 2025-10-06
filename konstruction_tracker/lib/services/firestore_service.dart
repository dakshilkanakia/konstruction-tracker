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

  Future<bool> updateComponentStatus(String componentId, bool isCompleted) async {
    try {
      await _db.collection('components').doc(componentId).update({
        'isManuallyCompleted': isCompleted,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      if (kDebugMode) print('Error updating component status: $e');
      return false;
    }
  }

  Future<bool> deleteComponent(String componentId) async {
    try {
      if (kDebugMode) print('Deleting component: $componentId');
      await _db.collection('components').doc(componentId).delete();
      if (kDebugMode) print('Component deleted successfully from Firestore');
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Error deleting component: $e');
      }
      return false;
    }
  }

  // Delete all labor entries for a specific work category
  Future<bool> deleteLaborByWorkCategory(String projectId, String workCategory) async {
    try {
      if (kDebugMode) print('Deleting labor entries for work category: $workCategory');
      
      // Get all labor entries for this work category
      final laborEntries = await getProjectLabor(projectId);
      final relatedLabor = laborEntries.where((l) => l.workCategory == workCategory).toList();
      
      if (kDebugMode) print('Found ${relatedLabor.length} labor entries to delete');
      
      // Delete each labor entry
      for (final labor in relatedLabor) {
        await _db.collection('labor').doc(labor.id).delete();
        if (kDebugMode) print('Deleted labor entry: ${labor.id}');
      }
      
      if (kDebugMode) print('Successfully deleted ${relatedLabor.length} labor entries');
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Error deleting labor entries for work category $workCategory: $e');
      }
      return false;
    }
  }

  // Delete specific "Seat Wall" labor entry (for fixing budget discrepancy)
  Future<bool> deleteSeatWallLaborEntry(String projectId) async {
    try {
      if (kDebugMode) print('🗑️ DELETING: Seat Wall labor entry for project: $projectId');
      
      // Get all labor entries for this project
      final laborEntries = await getProjectLabor(projectId);
      
      // Find the specific "Seat Wall" labor entry
      final seatWallLabor = laborEntries.where((l) => 
        l.workCategory == 'Seat Wall' && l.totalCost == 600.0
      ).toList();
      
      if (seatWallLabor.isEmpty) {
        if (kDebugMode) print('❌ No Seat Wall labor entry found with \$600 cost');
        return false;
      }
      
      if (kDebugMode) print('Found ${seatWallLabor.length} Seat Wall labor entries to delete');
      
      // Delete each Seat Wall labor entry
      for (final labor in seatWallLabor) {
        await _db.collection('labor').doc(labor.id).delete();
        if (kDebugMode) print('✅ Deleted Seat Wall labor entry: ${labor.id} (Cost: \$${labor.totalCost})');
      }
      
      if (kDebugMode) print('✅ Successfully deleted ${seatWallLabor.length} Seat Wall labor entries');
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error deleting Seat Wall labor entry: $e');
      }
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
      if (kDebugMode) print('📝 Getting daily logs for project: $projectId');
      
      // Get all daily logs and filter in memory to avoid index issues
      QuerySnapshot snapshot = await _db.collection('dailyLogs').get();
      
      if (kDebugMode) print('Found ${snapshot.docs.length} total daily logs');
      
      List<DailyLog> allLogs = [];
      for (var doc in snapshot.docs) {
        try {
          final data = doc.data() as Map<String, dynamic>;
          if (kDebugMode) print('Daily log data: $data');
          final log = DailyLog.fromMap(data);
          allLogs.add(log);
          if (kDebugMode) print('Parsed daily log: projectId=${log.projectId}, date=${log.date}');
        } catch (e) {
          if (kDebugMode) print('Error parsing daily log ${doc.id}: $e');
        }
      }
      
      // Filter by project ID
      List<DailyLog> projectLogs = allLogs
          .where((log) => log.projectId == projectId)
          .toList();
      
      if (kDebugMode) print('Filtered to ${projectLogs.length} logs for project $projectId');
      
      // Sort by date (newest first)
      projectLogs.sort((a, b) => b.date.compareTo(a.date));
      
      if (kDebugMode) print('✅ Found ${projectLogs.length} daily logs for project $projectId');
      return projectLogs;
    } catch (e) {
      if (kDebugMode) print('❌ Error getting daily logs: $e');
      return [];
    }
  }

  Future<bool> createDailyLog(DailyLog dailyLog) async {
    try {
      if (kDebugMode) print('📝 Creating daily log for project: ${dailyLog.projectId}');
      final data = dailyLog.toMap();
      if (kDebugMode) print('Daily log data to save: $data');
      await _db.collection('dailyLogs').doc(dailyLog.id).set(data);
      if (kDebugMode) print('✅ Daily log created successfully with ID: ${dailyLog.id}');
      return true;
    } catch (e) {
      if (kDebugMode) print('❌ Error creating daily log: $e');
      return false;
    }
  }

  Future<bool> updateDailyLog(DailyLog dailyLog) async {
    try {
      if (kDebugMode) print('📝 Updating daily log with ID: ${dailyLog.id}');
      await _db.collection('dailyLogs').doc(dailyLog.id).update(
        dailyLog.copyWith(updatedAt: DateTime.now()).toMap(),
      );
      if (kDebugMode) print('✅ Daily log updated successfully with ID: ${dailyLog.id}');
      return true;
    } catch (e) {
      if (kDebugMode) print('❌ Error updating daily log: $e');
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

  // Component-Labor Synchronization - Simple additive approach
  Future<bool> syncLaborProgressToComponent(String projectId, String workCategory, {bool isEdit = false}) async {
    try {
      // Find component with matching name
      final components = await getProjectComponents(projectId);
      final matchingComponent = components.where((c) => c.name == workCategory).firstOrNull;
      
      if (matchingComponent == null) {
        if (kDebugMode) print('🔄 SYNC: No component found with name "$workCategory" - skipping sync');
        return true; // Not an error, just no matching component
      }

      // Get all current labor entries for this component
      final allLabor = await getProjectLabor(projectId);
      final componentLabor = allLabor.where((l) => l.workCategory == workCategory).toList();
      
      // Calculate total completed area from all progress entries (both contract and work progress)
      final contractProgressEntries = componentLabor
          .where((l) => l.isProgress && l.isContracted)
          .toList();
      
      final workProgressEntries = componentLabor
          .where((l) => l.isProgress && !l.isContracted)
          .toList();
      
      // Sum completed area from contract progress (completedSqFt) and work progress (completedArea)
      final totalContractCompletedArea = contractProgressEntries
          .fold(0.0, (sum, entry) => sum + (entry.completedSqFt ?? 0.0));
      
      final totalWorkCompletedArea = workProgressEntries
          .fold(0.0, (sum, entry) => sum + (entry.completedArea ?? 0.0));
      
      final totalLaborCompletedArea = totalContractCompletedArea + totalWorkCompletedArea;
      
      // Sum concrete poured from contract progress entries
      final totalConcretePoured = contractProgressEntries
          .fold(0.0, (sum, entry) => sum + (entry.concretePoured ?? 0.0));
      
      // Add initial concrete poured from the contract itself
      final contract = allLabor.where((l) => l.workCategory == workCategory && l.isContract).firstOrNull;
      final initialConcretePoured = contract?.initialConcretePoured ?? 0.0;
      final totalConcretePouredWithInitial = totalConcretePoured + initialConcretePoured;
      
      // Calculate total labor cost from all labor entries
      final totalLaborCost = componentLabor
          .fold(0.0, (sum, entry) => sum + entry.totalCost);
      
      // Calculate new values preserving manual changes
      // Use simple additive approach: original manual + current labor totals
      // This ensures consistency and prevents calculation errors
      final newCompletedArea = matchingComponent.originalCompletedArea + totalLaborCompletedArea;
      final newAmountUsed = matchingComponent.originalAmountUsed + totalLaborCost;
      final newConcretePoured = matchingComponent.originalConcretePoured + totalConcretePouredWithInitial;
      
      // Debug: Check if this would cause an increase
      if (kDebugMode && newAmountUsed > matchingComponent.amountUsed) {
        final increase = newAmountUsed - matchingComponent.amountUsed;
        print('⚠️ SYNC: Component "$workCategory" amount will increase by \$${increase.toStringAsFixed(2)}');
        print('  Current: \$${matchingComponent.amountUsed.toStringAsFixed(2)}');
        print('  New: \$${newAmountUsed.toStringAsFixed(2)}');
        print('  Labor Cost: \$${totalLaborCost.toStringAsFixed(2)}');
      }

      if (kDebugMode) {
        print('🔄 SYNC: Recalculating component "$workCategory" preserving manual changes');
        print('  Current Component Area: ${matchingComponent.completedArea.toStringAsFixed(1)} sq ft');
        print('  Current Component Used: \$${matchingComponent.amountUsed.toStringAsFixed(2)}');
        print('  Current Component Concrete: ${matchingComponent.concretePoured.toStringAsFixed(1)} cu yd');
        print('  Original Manual Area: ${matchingComponent.originalCompletedArea.toStringAsFixed(1)} sq ft');
        print('  Original Manual Used: \$${matchingComponent.originalAmountUsed.toStringAsFixed(2)}');
        print('  Original Manual Concrete: ${matchingComponent.originalConcretePoured.toStringAsFixed(1)} cu yd');
        print('  Contract Progress Area: ${totalContractCompletedArea.toStringAsFixed(1)} sq ft');
        print('  Work Progress Area: ${totalWorkCompletedArea.toStringAsFixed(1)} sq ft');
        print('  Total Labor Area: ${totalLaborCompletedArea.toStringAsFixed(1)} sq ft');
        print('  Total Labor Concrete: ${totalConcretePoured.toStringAsFixed(1)} cu yd');
        print('  Initial Concrete Poured: ${initialConcretePoured.toStringAsFixed(1)} cu yd');
        print('  Total Concrete with Initial: ${totalConcretePouredWithInitial.toStringAsFixed(1)} cu yd');
        print('  Total Labor Cost: \$${totalLaborCost.toStringAsFixed(2)}');
        print('  New Component Area: ${newCompletedArea.toStringAsFixed(1)} sq ft');
        print('  New Component Used: \$${newAmountUsed.toStringAsFixed(2)}');
        print('  New Component Concrete: ${newConcretePoured.toStringAsFixed(1)} cu yd');
      }

      // Update component if values changed
      if (newCompletedArea != matchingComponent.completedArea || 
          newAmountUsed != matchingComponent.amountUsed ||
          newConcretePoured != matchingComponent.concretePoured) {
        final updatedComponent = matchingComponent.copyWith(
          completedArea: newCompletedArea,
          amountUsed: newAmountUsed,
          concretePoured: newConcretePoured,
          updatedAt: DateTime.now(),
        );

        final success = await updateComponent(updatedComponent);
        if (success) {
          if (kDebugMode) print('✅ SYNC: Updated component "${workCategory}" - Area: ${newCompletedArea.toStringAsFixed(1)} sq ft, Used: \$${newAmountUsed.toStringAsFixed(2)}, Concrete: ${newConcretePoured.toStringAsFixed(1)} cu yd');
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

  // Test method to debug daily logs issue
  Future<void> testDailyLogs(String projectId) async {
    try {
      if (kDebugMode) print('🧪 TEST: Testing daily logs for project: $projectId');
      
      // Test 1: Get all daily logs
      final allLogs = await getProjectDailyLogs(projectId);
      if (kDebugMode) print('🧪 TEST: Found ${allLogs.length} daily logs');
      
      // Test 2: Get all daily logs from Firestore directly
      final snapshot = await _db.collection('dailyLogs').get();
      if (kDebugMode) print('🧪 TEST: Found ${snapshot.docs.length} total daily logs in Firestore');
      
      // Test 3: Check each document
      for (var doc in snapshot.docs) {
        final data = doc.data();
        if (kDebugMode) print('🧪 TEST: Document ${doc.id}: projectId=${data['projectId']}, date=${data['date']}');
      }
      
    } catch (e) {
      if (kDebugMode) print('🧪 TEST: Error testing daily logs: $e');
    }
  }

  // Component-to-WorkSetup Synchronization - Update work setup remaining values from component changes
  Future<bool> syncComponentToWorkSetup(String projectId, String componentName) async {
    try {
      // Find work setup for this component
      final allLabor = await getProjectLabor(projectId);
      final workSetup = allLabor
          .where((l) => l.isWorkSetup && l.workCategory == componentName)
          .firstOrNull;
      
      if (workSetup == null) {
        if (kDebugMode) print('🔄 REVERSE_SYNC: No work setup found for component "$componentName" - skipping sync');
        return true; // Not an error, just no matching work setup
      }

      // Check if this is an existing component work setup (has remainingArea and remainingBudget)
      if (workSetup.remainingArea == null || workSetup.remainingBudget == null) {
        if (kDebugMode) print('🔄 REVERSE_SYNC: Work setup for "$componentName" is not for existing component - skipping sync');
        return true; // Not an error, just not an existing component work setup
      }

      // Get the current component to calculate new remaining values
      final components = await getProjectComponents(projectId);
      final component = components.where((c) => c.name == componentName).firstOrNull;
      
      if (component == null) {
        if (kDebugMode) print('🔄 REVERSE_SYNC: Component "$componentName" not found - skipping sync');
        return true; // Not an error, just no matching component
      }

      // For existing component work setups, remaining values should match the component's current state
      // This ensures both work setup and component cards show the same remaining values
      final newRemainingArea = component.totalArea - component.completedArea;
      final newRemainingBudget = component.componentBudget - component.amountUsed;

      if (kDebugMode) {
        print('🔄 REVERSE_SYNC: Updating work setup for component "$componentName"');
        print('  Component Total Area: ${component.totalArea.toStringAsFixed(1)} sq ft');
        print('  Component Completed Area: ${component.completedArea.toStringAsFixed(1)} sq ft');
        print('  New Remaining Area: ${newRemainingArea.toStringAsFixed(1)} sq ft');
        print('  Component Total Budget: \$${component.componentBudget.toStringAsFixed(2)}');
        print('  Component Amount Used: \$${component.amountUsed.toStringAsFixed(2)}');
        print('  New Remaining Budget: \$${newRemainingBudget.toStringAsFixed(2)}');
      }

      // Update work setup if values changed
      if (newRemainingArea != workSetup.remainingArea || newRemainingBudget != workSetup.remainingBudget) {
        final updatedWorkSetup = workSetup.copyWith(
          remainingArea: newRemainingArea,
          remainingBudget: newRemainingBudget,
          updatedAt: DateTime.now(),
        );

        final success = await updateLabor(updatedWorkSetup);
        if (success) {
          if (kDebugMode) print('✅ REVERSE_SYNC: Updated work setup for "$componentName" - Remaining Area: ${newRemainingArea.toStringAsFixed(1)} sq ft, Remaining Budget: \$${newRemainingBudget.toStringAsFixed(2)}');
        }
        return success;
      } else {
        if (kDebugMode) print('🔄 REVERSE_SYNC: No changes needed for work setup "$componentName"');
        return true;
      }
    } catch (e) {
      if (kDebugMode) print('❌ REVERSE_SYNC: Error syncing component to work setup: $e');
      return false;
    }
  }

  // Manual sync for all custom work setups in a project (for fixing existing data)
  Future<bool> syncAllCustomWorkSetups(String projectId) async {
    try {
      final allLabor = await getProjectLabor(projectId);
      final customWorkSetups = allLabor
          .where((l) => l.isWorkSetup && l.remainingArea == null)
          .toList();
      
      if (kDebugMode) print('🔄 MANUAL_SYNC: Found ${customWorkSetups.length} custom work setups to sync');
      
      bool allSuccess = true;
      for (final workSetup in customWorkSetups) {
        final success = await syncCustomWorkSetupRemainingValues(projectId, workSetup.id);
        if (!success) allSuccess = false;
      }
      
      if (kDebugMode) print('🔄 MANUAL_SYNC: Completed sync for all custom work setups');
      return allSuccess;
    } catch (e) {
      if (kDebugMode) print('❌ MANUAL_SYNC: Error syncing all custom work setups: $e');
      return false;
    }
  }

  // Custom Work Setup Sync - Update work setup remaining values for custom component work setups
  Future<bool> syncCustomWorkSetupRemainingValues(String projectId, String workSetupId) async {
    try {
      // Get the work setup
      final allLabor = await getProjectLabor(projectId);
      final workSetup = allLabor.where((l) => l.id == workSetupId && l.isWorkSetup).firstOrNull;
      
      if (workSetup == null) {
        if (kDebugMode) print('🔄 CUSTOM_WORK_SETUP_SYNC: Work setup not found with ID: $workSetupId');
        return true; // Not an error, just no matching work setup
      }

      // Check if this is a custom component work setup (not existing component)
      // For existing component work setups, both remainingArea and remainingBudget should be non-null
      // For custom component work setups, remainingArea should be null
      if (workSetup.remainingArea != null) {
        if (kDebugMode) print('🔄 CUSTOM_WORK_SETUP_SYNC: Work setup is for existing component - skipping sync');
        return true; // Not an error, just not a custom component work setup
      }

      // Get all work progress entries for this work setup
      final workProgressEntries = allLabor
          .where((l) => l.workSetupId == workSetupId && l.isWorkProgress)
          .toList();
      
      // Calculate current totals
      final totalWorkedHours = Labor.calculateTotalHoursWorked(workProgressEntries);
      final totalUsedBudget = workProgressEntries.fold(0.0, (sum, entry) => sum + entry.totalCost);
      
      // Calculate remaining values
      final originalMaxHours = workSetup.maxHours;
      final originalTotalBudget = workSetup.totalBudget ?? 0.0;
      final remainingHours = originalMaxHours - totalWorkedHours;
      final remainingBudget = originalTotalBudget - totalUsedBudget;

      if (kDebugMode) {
        print('🔄 CUSTOM_WORK_SETUP_SYNC: Updating custom work setup remaining values');
        print('  Work Setup ID: $workSetupId');
        print('  Work Setup Type: Custom Component (remainingArea is null)');
        print('  Original Max Hours: ${originalMaxHours.toStringAsFixed(1)}');
        print('  Total Worked Hours: ${totalWorkedHours.toStringAsFixed(1)}');
        print('  Remaining Hours: ${remainingHours.toStringAsFixed(1)}');
        print('  Original Total Budget: \$${originalTotalBudget.toStringAsFixed(2)}');
        print('  Total Used Budget: \$${totalUsedBudget.toStringAsFixed(2)}');
        print('  Remaining Budget: \$${remainingBudget.toStringAsFixed(2)}');
        print('  Progress Entries Count: ${workProgressEntries.length}');
      }

      // Update work setup with calculated remaining values
      final updatedWorkSetup = workSetup.copyWith(
        remainingArea: null, // Keep null for custom component work setups
        remainingBudget: remainingBudget,
        remainingHours: remainingHours,
        updatedAt: DateTime.now(),
      );

      final success = await updateLabor(updatedWorkSetup);
      if (success) {
        if (kDebugMode) {
          print('✅ CUSTOM_WORK_SETUP_SYNC: Updated custom work setup remaining values');
          print('  Updated remainingHours: ${updatedWorkSetup.remainingHours}');
          print('  Updated remainingBudget: ${updatedWorkSetup.remainingBudget}');
        }
      } else {
        if (kDebugMode) print('❌ CUSTOM_WORK_SETUP_SYNC: Failed to update work setup');
      }
      return success;
    } catch (e) {
      if (kDebugMode) print('❌ CUSTOM_WORK_SETUP_SYNC: Error syncing custom work setup remaining values: $e');
      return false;
    }
  }

  // Work Setup Remaining Values Sync - Recalculate remaining values based on component state
  Future<bool> syncWorkSetupRemainingValues(String projectId, String workSetupId) async {
    try {
      // Get the work setup
      final allLabor = await getProjectLabor(projectId);
      final workSetup = allLabor.where((l) => l.id == workSetupId && l.isWorkSetup).firstOrNull;
      
      if (workSetup == null) {
        if (kDebugMode) print('🔄 WORK_SETUP_SYNC: Work setup not found with ID: $workSetupId');
        return true; // Not an error, just no matching work setup
      }

      // Check if this is an existing component work setup
      if (workSetup.remainingArea == null || workSetup.remainingBudget == null) {
        if (kDebugMode) print('🔄 WORK_SETUP_SYNC: Work setup is not for existing component - skipping sync');
        return true; // Not an error, just not an existing component work setup
      }

      // Get the current component to calculate remaining values based on component state
      final components = await getProjectComponents(projectId);
      final component = components.where((c) => c.name == workSetup.workCategory).firstOrNull;
      
      if (component == null) {
        if (kDebugMode) print('🔄 WORK_SETUP_SYNC: Component "${workSetup.workCategory}" not found - skipping sync');
        return true; // Not an error, just no matching component
      }

      // Calculate remaining values based on component's current state
      // This ensures work setup remaining values always match the component card
      // The work setup should reflect the component's current remaining values
      final newRemainingArea = component.totalArea - component.completedArea;
      final newRemainingBudget = component.componentBudget - component.amountUsed;

      if (kDebugMode) {
        print('🔄 WORK_SETUP_SYNC: Updating work setup remaining values based on component state');
        print('  Component Total Area: ${component.totalArea.toStringAsFixed(1)} sq ft');
        print('  Component Completed Area: ${component.completedArea.toStringAsFixed(1)} sq ft');
        print('  New Remaining Area: ${newRemainingArea.toStringAsFixed(1)} sq ft');
        print('  Component Total Budget: \$${component.componentBudget.toStringAsFixed(2)}');
        print('  Component Amount Used: \$${component.amountUsed.toStringAsFixed(2)}');
        print('  New Remaining Budget: \$${newRemainingBudget.toStringAsFixed(2)}');
      }

      // Update work setup if values changed
      if (newRemainingArea != workSetup.remainingArea || newRemainingBudget != workSetup.remainingBudget) {
        final updatedWorkSetup = workSetup.copyWith(
          remainingArea: newRemainingArea,
          remainingBudget: newRemainingBudget,
          updatedAt: DateTime.now(),
        );

        final success = await updateLabor(updatedWorkSetup);
        if (success) {
          if (kDebugMode) print('✅ WORK_SETUP_SYNC: Updated work setup remaining values to match component state');
        }
        return success;
      } else {
        if (kDebugMode) print('🔄 WORK_SETUP_SYNC: No changes needed for work setup');
        return true;
      }
    } catch (e) {
      if (kDebugMode) print('❌ WORK_SETUP_SYNC: Error syncing work setup remaining values: $e');
      return false;
    }
  }

  // Project Notes Management
  Future<bool> addProjectNote(String projectId, String noteText) async {
    try {
      if (kDebugMode) print('📝 Adding note to project: $projectId');
      
      final note = {
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'text': noteText,
        'isCompleted': false,
        'createdAt': Timestamp.fromDate(DateTime.now()),
      };
      
      await _db.collection('projects').doc(projectId).update({
        'notes': FieldValue.arrayUnion([note]),
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
      
      if (kDebugMode) print('✅ Note added successfully');
      return true;
    } catch (e) {
      if (kDebugMode) print('❌ Error adding note: $e');
      return false;
    }
  }

  Future<bool> updateProjectNote(String projectId, String noteId, String newText) async {
    try {
      if (kDebugMode) print('📝 Updating note: $noteId');
      
      final project = await getProject(projectId);
      if (project == null) return false;
      
      final updatedNotes = project.notes.map((note) {
        if (note['id'] == noteId) {
          return {...note, 'text': newText};
        }
        return note;
      }).toList();
      
      await _db.collection('projects').doc(projectId).update({
        'notes': updatedNotes,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
      
      if (kDebugMode) print('✅ Note updated successfully');
      return true;
    } catch (e) {
      if (kDebugMode) print('❌ Error updating note: $e');
      return false;
    }
  }

  Future<bool> toggleProjectNote(String projectId, String noteId) async {
    try {
      if (kDebugMode) print('📝 Toggling note completion: $noteId');
      
      final project = await getProject(projectId);
      if (project == null) return false;
      
      final updatedNotes = project.notes.map((note) {
        if (note['id'] == noteId) {
          return {...note, 'isCompleted': !(note['isCompleted'] ?? false)};
        }
        return note;
      }).toList();
      
      await _db.collection('projects').doc(projectId).update({
        'notes': updatedNotes,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
      
      if (kDebugMode) print('✅ Note toggled successfully');
      return true;
    } catch (e) {
      if (kDebugMode) print('❌ Error toggling note: $e');
      return false;
    }
  }

  Future<bool> deleteProjectNote(String projectId, String noteId) async {
    try {
      if (kDebugMode) print('📝 Deleting note: $noteId');
      
      final project = await getProject(projectId);
      if (project == null) return false;
      
      final updatedNotes = project.notes.where((note) => note['id'] != noteId).toList();
      
      await _db.collection('projects').doc(projectId).update({
        'notes': updatedNotes,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
      
      if (kDebugMode) print('✅ Note deleted successfully');
      return true;
    } catch (e) {
      if (kDebugMode) print('❌ Error deleting note: $e');
      return false;
    }
  }

  // Materials Budget Management
  Future<bool> setMaterialsBudget(String projectId, double budget) async {
    try {
      if (kDebugMode) print('💰 Setting materials budget: \$${budget.toStringAsFixed(2)}');
      
      await _db.collection('projects').doc(projectId).update({
        'materialsBudget': budget,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
      
      if (kDebugMode) print('✅ Materials budget set successfully');
      return true;
    } catch (e) {
      if (kDebugMode) print('❌ Error setting materials budget: $e');
      return false;
    }
  }

  Future<bool> updateMaterialsBudget(String projectId, double budget) async {
    try {
      if (kDebugMode) print('💰 Updating materials budget: \$${budget.toStringAsFixed(2)}');
      
      await _db.collection('projects').doc(projectId).update({
        'materialsBudget': budget,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
      
      if (kDebugMode) print('✅ Materials budget updated successfully');
      return true;
    } catch (e) {
      if (kDebugMode) print('❌ Error updating materials budget: $e');
      return false;
    }
  }

  Future<bool> deleteMaterialsBudget(String projectId) async {
    try {
      if (kDebugMode) print('💰 Deleting materials budget');
      
      await _db.collection('projects').doc(projectId).update({
        'materialsBudget': FieldValue.delete(),
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
      
      if (kDebugMode) print('✅ Materials budget deleted successfully');
      return true;
    } catch (e) {
      if (kDebugMode) print('❌ Error deleting materials budget: $e');
      return false;
    }
  }

  // Machinery Budget Management
  Future<bool> setMachineryBudget(String projectId, double budget) async {
    try {
      if (kDebugMode) print('🚛 Setting machinery budget: \$${budget.toStringAsFixed(2)}');
      
      await _db.collection('projects').doc(projectId).update({
        'machineryBudget': budget,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
      
      if (kDebugMode) print('✅ Machinery budget set successfully');
      return true;
    } catch (e) {
      if (kDebugMode) print('❌ Error setting machinery budget: $e');
      return false;
    }
  }

  Future<bool> updateMachineryBudget(String projectId, double budget) async {
    try {
      if (kDebugMode) print('🚛 Updating machinery budget: \$${budget.toStringAsFixed(2)}');
      
      await _db.collection('projects').doc(projectId).update({
        'machineryBudget': budget,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
      
      if (kDebugMode) print('✅ Machinery budget updated successfully');
      return true;
    } catch (e) {
      if (kDebugMode) print('❌ Error updating machinery budget: $e');
      return false;
    }
  }

  Future<bool> deleteMachineryBudget(String projectId) async {
    try {
      if (kDebugMode) print('🚛 Deleting machinery budget');
      
      await _db.collection('projects').doc(projectId).update({
        'machineryBudget': FieldValue.delete(),
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
      
      if (kDebugMode) print('✅ Machinery budget deleted successfully');
      return true;
    } catch (e) {
      if (kDebugMode) print('❌ Error deleting machinery budget: $e');
      return false;
    }
  }

}
