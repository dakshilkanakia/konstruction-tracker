import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import '../services/firestore_service.dart';
import '../models/project.dart';
import '../models/material.dart' as models;

class MaterialsBudgetCard extends StatefulWidget {
  final Project project;
  final List<models.Material> materials;
  final VoidCallback? onRefresh;

  const MaterialsBudgetCard({
    Key? key,
    required this.project,
    required this.materials,
    this.onRefresh,
  }) : super(key: key);

  @override
  State<MaterialsBudgetCard> createState() => _MaterialsBudgetCardState();
}

class _MaterialsBudgetCardState extends State<MaterialsBudgetCard> {
  final TextEditingController _budgetController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _budgetController.dispose();
    super.dispose();
  }

  double get _usedBudget {
    return widget.materials.fold(0.0, (sum, material) => sum + material.totalCost);
  }

  double get _remainingBudget {
    if (widget.project.materialsBudget == null) return 0.0;
    return widget.project.materialsBudget! - _usedBudget;
  }

  double get _budgetProgress {
    if (widget.project.materialsBudget == null || widget.project.materialsBudget! <= 0) return 0.0;
    return (_usedBudget / widget.project.materialsBudget!).clamp(0.0, 1.0);
  }

  Color _getBudgetColor(double progress) {
    if (progress >= 1.0) return Colors.red;
    if (progress >= 0.8) return Colors.orange;
    if (progress >= 0.6) return Colors.amber;
    return Colors.green;
  }

  Future<void> _setBudget() async {
    final budget = double.tryParse(_budgetController.text);
    if (budget == null || budget <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid budget amount'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    final firestoreService = Provider.of<FirestoreService>(context, listen: false);
    final success = await firestoreService.setMaterialsBudget(
      widget.project.id,
      budget,
    );

    if (success) {
      widget.onRefresh?.call();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Materials budget set successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to set materials budget'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }

    setState(() => _isLoading = false);
  }

  Future<void> _editBudget() async {
    _budgetController.text = widget.project.materialsBudget?.toStringAsFixed(2) ?? '';
    
    final newBudget = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Materials Budget'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _budgetController,
              decoration: const InputDecoration(
                labelText: 'Materials Budget',
                hintText: 'Enter total materials budget',
                prefixText: '\$',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              autofocus: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, _budgetController.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (newBudget != null && newBudget.isNotEmpty) {
      final budget = double.tryParse(newBudget);
      if (budget == null || budget <= 0) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please enter a valid budget amount'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      setState(() => _isLoading = true);

      final firestoreService = Provider.of<FirestoreService>(context, listen: false);
      final success = await firestoreService.updateMaterialsBudget(
        widget.project.id,
        budget,
      );

      if (success) {
        widget.onRefresh?.call();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Materials budget updated successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to update materials budget'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }

      setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteBudget() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Materials Budget'),
        content: const Text('Are you sure you want to delete the materials budget? This will remove budget tracking for materials.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() => _isLoading = true);

      final firestoreService = Provider.of<FirestoreService>(context, listen: false);
      final success = await firestoreService.deleteMaterialsBudget(widget.project.id);

      if (success) {
        widget.onRefresh?.call();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Materials budget deleted successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to delete materials budget'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }

      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (kDebugMode) {
      print('💰 MaterialsBudgetCard: Project materialsBudget = ${widget.project.materialsBudget}');
      print('💰 MaterialsBudgetCard: Project ID = ${widget.project.id}');
    }
    
    // Show setup card if no budget is set
    if (widget.project.materialsBudget == null) {
      if (kDebugMode) {
        print('💰 MaterialsBudgetCard: Showing setup card (materialsBudget is null)');
      }
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.account_balance_wallet,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Materials Budget',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Text(
                'Set a budget to track your materials spending and monitor progress.',
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _budgetController,
                      decoration: const InputDecoration(
                        labelText: 'Materials Budget',
                        hintText: 'Enter total budget',
                        prefixText: '\$',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _setBudget,
                    child: _isLoading 
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Set Budget'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    }

    // Show budget progress card if budget is set
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.account_balance_wallet,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Materials Budget',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'edit') {
                      _editBudget();
                    } else if (value == 'delete') {
                      _deleteBudget();
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit, size: 18),
                          SizedBox(width: 8),
                          Text('Edit Budget'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete, size: 18, color: Colors.red),
                          SizedBox(width: 8),
                          Text('Delete Budget', style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                  ],
                  child: Icon(
                    Icons.more_vert,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Progress Bar
            LinearProgressIndicator(
              value: _budgetProgress,
              backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
              color: _getBudgetColor(_budgetProgress),
            ),
            const SizedBox(height: 8),
            
            // Budget Info
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Used: \$${_usedBudget.toStringAsFixed(2)}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: _getBudgetColor(_budgetProgress),
                  ),
                ),
                Text(
                  'Total: \$${widget.project.materialsBudget!.toStringAsFixed(2)}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            
            // Progress Percentage and Remaining
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${(_budgetProgress * 100).toStringAsFixed(1)}% Complete',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: _getBudgetColor(_budgetProgress),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  'Remaining: \$${_remainingBudget.toStringAsFixed(2)}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: _remainingBudget < 0 ? Colors.red : Colors.grey,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
