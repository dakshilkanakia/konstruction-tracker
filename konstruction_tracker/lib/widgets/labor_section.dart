import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/labor.dart';
import '../models/project.dart';
import '../services/firestore_service.dart';
import '../screens/add_labor_screen.dart';
import 'labor_card.dart';

class LaborSection extends StatefulWidget {
  final Project project;
  final VoidCallback onRefresh;

  const LaborSection({
    super.key,
    required this.project,
    required this.onRefresh,
  });

  @override
  State<LaborSection> createState() => _LaborSectionState();
}

class _LaborSectionState extends State<LaborSection> {
  List<Labor> _labor = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadLabor();
  }

  Future<void> _loadLabor() async {
    setState(() => _isLoading = true);
    try {
      final firestoreService = Provider.of<FirestoreService>(context, listen: false);
      final labor = await firestoreService.getProjectLabor(widget.project.id);
      setState(() {
        _labor = labor;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading labor: $e')),
        );
      }
    }
  }

  Future<void> _addLabor() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => AddLaborScreen(project: widget.project),
      ),
    );
    
    if (result == true) {
      _loadLabor();
      widget.onRefresh(); // Notify parent to refresh
    }
  }

  Future<void> _editLabor(Labor labor) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => AddLaborScreen(
          project: widget.project,
          labor: labor,
        ),
      ),
    );
    
    if (result == true) {
      _loadLabor();
      widget.onRefresh(); // Notify parent to refresh
    }
  }

  Future<void> _deleteLabor(Labor labor) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Labor Entry'),
        content: Text('Are you sure you want to delete this labor entry?'),
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
        await firestoreService.deleteLabor(labor.id);
        _loadLabor();
        widget.onRefresh(); // Notify parent to refresh
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Labor entry deleted successfully')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error deleting labor entry: $e')),
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

    if (_labor.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.work_outline,
              size: 64,
              color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'No Labor Entries Added',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Add labor entries to track work hours and costs',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _addLabor,
              icon: const Icon(Icons.add),
              label: const Text('Add First Labor Entry'),
            ),
          ],
        ),
      );
    }

    // Separate contracted and non-contracted labor
    final contractedLabor = _labor.where((l) => l.type == LaborType.contracted).toList();
    final nonContractedLabor = _labor.where((l) => l.type == LaborType.nonContracted).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
                Icons.work,
                color: Theme.of(context).colorScheme.primary,
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Labor Tracking',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    Text(
                      '${_labor.length} entries • \$${_getTotalCost().toStringAsFixed(2)} total cost',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        
        // Labor list
        Expanded(
          child: RefreshIndicator(
            onRefresh: _loadLabor,
            child: ListView(
              padding: const EdgeInsets.only(bottom: 16),
              children: [
                // Contracted Work Section
                if (contractedLabor.isNotEmpty) ...[
                  _buildSectionHeader('Contracted Work', contractedLabor.length, _getContractedCost()),
                  const SizedBox(height: 8),
                  ...contractedLabor.map((labor) => LaborCard(
                    labor: labor,
                    onTap: () => _editLabor(labor),
                    onDelete: () => _deleteLabor(labor),
                  )),
                  const SizedBox(height: 16),
                ],

                // Non-Contracted Work Section
                if (nonContractedLabor.isNotEmpty) ...[
                  _buildSectionHeader('Non-Contracted Work', nonContractedLabor.length, _getNonContractedCost()),
                  const SizedBox(height: 8),
                  ...nonContractedLabor.map((labor) => LaborCard(
                    labor: labor,
                    onTap: () => _editLabor(labor),
                    onDelete: () => _deleteLabor(labor),
                  )),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title, int count, double cost) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
          Text(
            '$count entries • \$${cost.toStringAsFixed(2)}',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  double _getTotalCost() {
    return _labor.fold(0.0, (sum, labor) => sum + labor.totalCost);
  }

  double _getContractedCost() {
    return _labor
        .where((l) => l.type == LaborType.contracted)
        .fold(0.0, (sum, labor) => sum + labor.totalCost);
  }

  double _getNonContractedCost() {
    return _labor
        .where((l) => l.type == LaborType.nonContracted)
        .fold(0.0, (sum, labor) => sum + labor.totalCost);
  }
}
