import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import '../models/material.dart' as models;
import '../models/project.dart';
import '../services/firestore_service.dart';
import '../screens/add_material_screen.dart';
import 'material_card.dart';
import 'materials_budget_card.dart';

class MaterialsSection extends StatefulWidget {
  final Project project;
  final VoidCallback onRefresh;

  const MaterialsSection({
    super.key,
    required this.project,
    required this.onRefresh,
  });

  @override
  State<MaterialsSection> createState() => _MaterialsSectionState();
}

class _MaterialsSectionState extends State<MaterialsSection> {
  List<models.Material> _materials = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMaterials();
  }

  Future<void> _loadMaterials() async {
    setState(() => _isLoading = true);
    try {
      final firestoreService = Provider.of<FirestoreService>(context, listen: false);
      final materials = await firestoreService.getProjectMaterials(widget.project.id);
      print('📱 WIDGET: Loaded ${materials.length} materials for project ${widget.project.id}');
      setState(() {
        _materials = materials;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading materials: $e')),
        );
      }
    }
  }

  Future<void> _addMaterial() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => AddMaterialScreen(projectId: widget.project.id),
      ),
    );
    
    if (result == true) {
      _loadMaterials();
      widget.onRefresh(); // Notify parent to refresh
    }
  }

  Future<void> _editMaterial(models.Material material) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => AddMaterialScreen(
          projectId: widget.project.id,
          material: material,
        ),
      ),
    );
    
    if (result == true) {
      _loadMaterials();
      widget.onRefresh(); // Notify parent to refresh
    }
  }

  Future<void> _deleteMaterial(models.Material material) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Material'),
        content: Text('Are you sure you want to delete "${material.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final firestoreService = Provider.of<FirestoreService>(context, listen: false);
        await firestoreService.deleteMaterial(material.id);
        _loadMaterials();
        widget.onRefresh(); // Notify parent to refresh
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Material deleted successfully')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error deleting material: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_materials.isEmpty) {
      return Column(
        children: [
          // Materials Budget Card (even when no materials)
          MaterialsBudgetCard(
            project: widget.project,
            materials: _materials,
            onRefresh: widget.onRefresh,
          ),
          const SizedBox(height: 16),
          
          // Empty state
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.inventory_2_outlined,
                    size: 64,
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No Materials Added',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Add materials to track inventory and costs',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: _addMaterial,
                    icon: const Icon(Icons.add),
                    label: const Text('Add First Material'),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    }

    if (kDebugMode) {
      print('📦 MaterialsSection: Building with project materialsBudget = ${widget.project.materialsBudget}');
      print('📦 MaterialsSection: Materials count = ${_materials.length}');
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Materials Budget Card
        MaterialsBudgetCard(
          project: widget.project,
          materials: _materials,
          onRefresh: widget.onRefresh,
        ),
        const SizedBox(height: 16),
        
        // Header with stats
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(
                Icons.inventory_2,
                color: Theme.of(context).colorScheme.primary,
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Material Inventory',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    Text(
                      '${_materials.length} materials • \$${_getTotalCost().toStringAsFixed(2)} total cost',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: _loadMaterials,
                icon: const Icon(Icons.refresh),
                tooltip: 'Refresh Materials',
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        
        // Materials list
        Expanded(
          child: RefreshIndicator(
            onRefresh: _loadMaterials,
            child: ListView.builder(
              padding: const EdgeInsets.only(bottom: 16),
              itemCount: _materials.length,
              itemBuilder: (context, index) {
                final material = _materials[index];
                return MaterialCard(
                  material: material,
                  onTap: () => _editMaterial(material),
                  onDelete: () => _deleteMaterial(material),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  double _getTotalCost() {
    return _materials.fold(0.0, (sum, material) => sum + material.finalTotalCost);
  }
}
