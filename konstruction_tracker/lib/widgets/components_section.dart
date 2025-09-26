import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/component.dart';
import '../models/project.dart';
import '../services/firestore_service.dart';
import 'quick_edit_component_dialog.dart';

class ComponentsSection extends StatelessWidget {
  final List<Component> components;
  final Project project;
  final VoidCallback onRefresh;
  final VoidCallback onAddComponent;

  const ComponentsSection({
    super.key,
    required this.components,
    required this.project,
    required this.onRefresh,
    required this.onAddComponent,
  });

  @override
  Widget build(BuildContext context) {
    if (components.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.business,
              size: 64,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'No Components Yet',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tap the + button to add your first component',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onAddComponent,
              icon: const Icon(Icons.add),
              label: const Text('Add Component'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async => onRefresh(),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: components.length,
        itemBuilder: (context, index) {
          final component = components[index];
        return ComponentCard(
          component: component,
          project: project,
          onTap: () async {
            // Show quick edit dialog
            final result = await showDialog<bool>(
              context: context,
              builder: (context) => QuickEditComponentDialog(
                component: component,
                project: project,
              ),
            );
            
            // Refresh if component was updated
            if (result == true) {
              onRefresh();
            }
          },
          onDelete: () async {
            // Delete component and refresh
            await _deleteComponent(context, component);
            onRefresh();
          },
        );
        },
      ),
    );
  }

  Future<void> _deleteComponent(BuildContext context, Component component) async {
    // Get related labor entries to show in summary
    final firestoreService = Provider.of<FirestoreService>(context, listen: false);
    final laborEntries = await firestoreService.getProjectLabor(component.projectId);
    final relatedLabor = laborEntries.where((l) => l.workCategory == component.name).toList();
    
    // Calculate summary
    final totalLaborCost = relatedLabor.fold(0.0, (sum, labor) => sum + labor.totalCost);
    final contractEntries = relatedLabor.where((l) => l.isContracted).length;
    final workEntries = relatedLabor.where((l) => !l.isContracted).length;
    final progressEntries = relatedLabor.where((l) => l.isProgress).length;
    final setupEntries = relatedLabor.where((l) => !l.isProgress).length;
    
    // Show confirmation dialog with summary
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Component'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Are you sure you want to delete "${component.name}"?'),
            const SizedBox(height: 16),
            if (relatedLabor.isNotEmpty) ...[
              const Text(
                'This will also delete the following related labor entries:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text('• ${relatedLabor.length} total labor entries'),
              Text('• $contractEntries contract entries, $workEntries work entries'),
              Text('• $progressEntries progress entries, $setupEntries setup entries'),
              Text('• Total value: \$${totalLaborCost.toStringAsFixed(2)}'),
              const SizedBox(height: 8),
              const Text(
                'This action cannot be undone.',
                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
              ),
            ] else ...[
              const Text(
                'No related labor entries found.',
                style: TextStyle(fontStyle: FontStyle.italic),
              ),
              const SizedBox(height: 8),
              const Text(
                'This action cannot be undone.',
                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      try {
        final firestoreService = Provider.of<FirestoreService>(context, listen: false);
        
        // Delete related labor entries first
        bool laborDeleteSuccess = true;
        if (relatedLabor.isNotEmpty) {
          laborDeleteSuccess = await firestoreService.deleteLaborByWorkCategory(
            component.projectId, 
            component.name
          );
        }
        
        // Delete the component
        final componentDeleteSuccess = await firestoreService.deleteComponent(component.id);
        
        // Close loading dialog
        Navigator.of(context).pop();
        
        if (componentDeleteSuccess && laborDeleteSuccess) {
          final message = relatedLabor.isNotEmpty 
              ? 'Component "${component.name}" and ${relatedLabor.length} related labor entries deleted successfully'
              : 'Component "${component.name}" deleted successfully';
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(message),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          String errorMessage = 'Failed to delete component.';
          if (!laborDeleteSuccess) {
            errorMessage += ' Some labor entries may not have been deleted.';
          }
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(errorMessage),
              backgroundColor: Colors.red,
            ),
          );
        }
      } catch (e) {
        // Close loading dialog
        Navigator.of(context).pop();
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting component: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

class ComponentCard extends StatelessWidget {
  final Component component;
  final Project project;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const ComponentCard({
    super.key,
    required this.component,
    required this.project,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Expanded(
                    child: Text(
                      component.name,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: _getStatusColor(component.overallProgressPercentage).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: _getStatusColor(component.overallProgressPercentage),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          component.isAreaCompleted && !component.isBudgetExceeded ? 'Completed' : 'In Progress',
                          style: TextStyle(
                            color: _getStatusColor(component.overallProgressPercentage),
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Icon(
                          Icons.edit,
                          size: 16,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      const SizedBox(width: 4),
                      GestureDetector(
                        onTap: onDelete,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Icon(
                            Icons.delete,
                            size: 16,
                            color: Colors.red,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Area Information
              Row(
                children: [
                  Expanded(
                    child: _buildInfoItem(
                      context,
                      'Total Area',
                      '${component.totalArea.toStringAsFixed(1)} sq ft',
                      Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  Expanded(
                    child: _buildInfoItem(
                      context,
                      'Completed',
                      '${component.completedArea.toStringAsFixed(1)} sq ft',
                      Colors.orange,
                    ),
                  ),
                  Expanded(
                    child: _buildInfoItem(
                      context,
                      'Remaining',
                      '${component.remainingArea.toStringAsFixed(1)} sq ft',
                      Colors.green,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Budget Information
              Row(
                children: [
                  Expanded(
                    child: _buildInfoItem(
                      context,
                      'Budget',
                      '\$${component.componentBudget.toStringAsFixed(0)}',
                      Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  Expanded(
                    child: _buildInfoItem(
                      context,
                      'Used',
                      '\$${component.amountUsed.toStringAsFixed(0)}',
                      Colors.orange,
                    ),
                  ),
                  Expanded(
                    child: _buildInfoItem(
                      context,
                      'Remaining',
                      '\$${component.remainingBudget.toStringAsFixed(0)}',
                      Colors.green,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Concrete Information (if applicable)
              if (component.totalConcrete > 0) ...[
                Row(
                  children: [
                    Expanded(
                      child: _buildInfoItem(
                        context,
                        'Total Concrete',
                        '${component.totalConcrete.toStringAsFixed(1)} cu yd',
                        Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    Expanded(
                      child: _buildInfoItem(
                        context,
                        'Poured',
                        '${component.concretePoured.toStringAsFixed(1)} cu yd',
                        Colors.orange,
                      ),
                    ),
                    Expanded(
                      child: _buildInfoItem(
                        context,
                        'Remaining',
                        '${component.remainingConcrete.toStringAsFixed(1)} cu yd',
                        Colors.green,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
              ],
              const SizedBox(height: 4),

              // Area Progress Bar
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Area Progress',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        '${(component.areaProgressPercentage * 100).toStringAsFixed(1)}%',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: _getStatusColor(component.areaProgressPercentage),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: component.areaProgressPercentage,
                    backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
                    color: _getStatusColor(component.areaProgressPercentage),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Budget Progress Bar
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Budget Progress',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        '${(component.budgetProgressPercentage * 100).toStringAsFixed(1)}%',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: component.isBudgetExceeded ? Colors.red : _getBudgetColor(component.budgetProgressPercentage),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: component.budgetProgressPercentage.clamp(0.0, 1.0),
                    backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
                    color: component.isBudgetExceeded ? Colors.red : _getBudgetColor(component.budgetProgressPercentage),
                  ),
                  if (component.isBudgetExceeded || component.isBudgetWarning) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          component.isBudgetExceeded ? Icons.error : Icons.warning,
                          color: component.isBudgetExceeded ? Colors.red : Colors.orange,
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            component.isBudgetExceeded
                                ? 'Budget exceeded by \$${(component.amountUsed - component.componentBudget).toStringAsFixed(0)}'
                                : 'Budget warning - \$${component.remainingBudget.toStringAsFixed(0)} remaining',
                            style: TextStyle(
                              color: component.isBudgetExceeded ? Colors.red : Colors.orange,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),

              // Concrete Progress Bar (if applicable)
              if (component.totalConcrete > 0) ...[
                const SizedBox(height: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Concrete Progress',
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          '${(component.concreteProgressPercentage * 100).toStringAsFixed(1)}%',
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            color: component.concretePoured > component.totalConcrete 
                                ? Colors.orange 
                                : _getConcreteColor(component.concreteProgressPercentage),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    LinearProgressIndicator(
                      value: component.concreteProgressPercentage.clamp(0.0, 1.0), // Still clamp for progress bar
                      backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
                      color: component.concretePoured > component.totalConcrete 
                          ? Colors.orange // Changed from red to orange for warning
                          : _getConcreteColor(component.concreteProgressPercentage),
                    ),
                    if (component.concretePoured > component.totalConcrete || component.isConcreteWarning) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            component.concretePoured > component.totalConcrete ? Icons.warning : Icons.warning,
                            color: component.concretePoured > component.totalConcrete ? Colors.orange : Colors.orange,
                            size: 16,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              component.concretePoured > component.totalConcrete
                                  ? 'Concrete exceeded by ${(component.concretePoured - component.totalConcrete).toStringAsFixed(1)} cu yd'
                                  : 'Concrete warning - ${component.remainingConcrete.toStringAsFixed(1)} cu yd remaining',
                              style: TextStyle(
                                color: component.concretePoured > component.totalConcrete ? Colors.orange : Colors.orange,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoItem(BuildContext context, String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }

  Color _getStatusColor(double progress) {
    if (progress >= 1.0) return Colors.green; // Green for completed
    if (progress >= 0.7) return const Color(0xFF1976D2); // Primary blue
    if (progress >= 0.3) return Colors.orange;
    return Colors.red;
  }

  Color _getBudgetColor(double progress) {
    if (progress > 0.9) return Colors.red;
    if (progress > 0.8) return Colors.orange;
    if (progress > 0.7) return const Color(0xFF4CAF50); // Green for budget
    return const Color(0xFF8BC34A); // Light green for good budget progress
  }

  Color _getConcreteColor(double progress) {
    if (progress >= 1.0) return const Color(0xFF4CAF50); // Green for completed
    if (progress > 0.8) return Colors.orange;
    if (progress > 0.5) return const Color(0xFFFF9800); // Orange for concrete
    return const Color(0xFFFFC107); // Amber for good concrete progress
  }
}
