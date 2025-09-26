import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import '../models/machinery.dart' as models;
import '../models/project.dart';
import '../services/firestore_service.dart';
import '../screens/add_machinery_screen.dart';
import 'machinery_card.dart';
import 'machinery_budget_card.dart';

class MachinerySection extends StatefulWidget {
  final Project project;
  final VoidCallback? onRefresh;

  const MachinerySection({
    super.key,
    required this.project,
    this.onRefresh,
  });

  @override
  State<MachinerySection> createState() => _MachinerySectionState();
}

class _MachinerySectionState extends State<MachinerySection> {
  List<models.Machinery> _machinery = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMachinery();
  }

  Future<void> _loadMachinery() async {
    setState(() => _isLoading = true);
    try {
      final firestoreService = Provider.of<FirestoreService>(context, listen: false);
      final machinery = await firestoreService.getProjectMachinery(widget.project.id);
      setState(() {
        _machinery = machinery;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading machinery: $e')),
        );
      }
    }
  }

  Future<void> _addMachinery() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => AddMachineryScreen(projectId: widget.project.id),
      ),
    );
    
    if (result == true) {
      _loadMachinery();
      widget.onRefresh?.call(); // Notify parent to refresh project data
    }
  }

  Future<void> _editMachinery(models.Machinery machinery) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => AddMachineryScreen(
          projectId: widget.project.id,
          machinery: machinery,
        ),
      ),
    );
    
    if (result == true) {
      _loadMachinery();
      widget.onRefresh?.call(); // Notify parent to refresh project data
    }
  }

  Future<void> _deleteMachinery(models.Machinery machinery) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Machinery'),
        content: Text('Are you sure you want to delete "${machinery.name}"?'),
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
        await firestoreService.deleteMachinery(machinery.id);
        _loadMachinery();
        widget.onRefresh?.call(); // Notify parent to refresh project data
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Machinery deleted successfully')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error deleting machinery: $e')),
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

    if (_machinery.isEmpty) {
      return Column(
        children: [
          // Machinery Budget Card (even when no machinery)
          MachineryBudgetCard(
            project: widget.project,
            machinery: _machinery,
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
                    Icons.local_shipping_outlined,
                    size: 64,
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No Machinery Added',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Add machinery to track equipment usage and costs',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: _addMachinery,
                    icon: const Icon(Icons.add),
                    label: const Text('Add First Machinery'),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    }

    if (kDebugMode) {
      print('🚛 MachinerySection: Building with project machineryBudget = ${widget.project.machineryBudget}');
      print('🚛 MachinerySection: Machinery count = ${_machinery.length}');
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Machinery Budget Card
        MachineryBudgetCard(
          project: widget.project,
          machinery: _machinery,
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
                Icons.local_shipping,
                color: Theme.of(context).colorScheme.primary,
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Machinery & Equipment',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    Text(
                      '${_machinery.length} items • \$${_getTotalCost().toStringAsFixed(2)} total cost',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        
        // Machinery list
        Expanded(
          child: RefreshIndicator(
            onRefresh: _loadMachinery,
            child: ListView.builder(
              padding: const EdgeInsets.only(bottom: 16),
              itemCount: _machinery.length,
              itemBuilder: (context, index) {
                final machinery = _machinery[index];
                return MachineryCard(
                  machinery: machinery,
                  onTap: () => _editMachinery(machinery),
                  onDelete: () => _deleteMachinery(machinery),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  double _getTotalCost() {
    return _machinery.fold(0.0, (sum, machinery) => sum + machinery.totalCost);
  }
}