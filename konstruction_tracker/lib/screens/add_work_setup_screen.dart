import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../models/labor.dart';
import '../models/project.dart';
import '../services/firestore_service.dart';

class AddWorkSetupScreen extends StatefulWidget {
  final Project project;
  final Labor? workSetup; // For editing existing work setups

  const AddWorkSetupScreen({
    super.key,
    required this.project,
    this.workSetup,
  });

  @override
  State<AddWorkSetupScreen> createState() => _AddWorkSetupScreenState();
}

class _AddWorkSetupScreenState extends State<AddWorkSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _workCategoryController = TextEditingController();
  final _totalBudgetController = TextEditingController();
  final _hourlyRateController = TextEditingController();

  bool _isLoading = false;
  bool get _isEditing => widget.workSetup != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      _populateFields();
    }
  }

  void _populateFields() {
    final workSetup = widget.workSetup!;
    _workCategoryController.text = workSetup.workCategory;
    _totalBudgetController.text = workSetup.totalBudget?.toString() ?? '';
    _hourlyRateController.text = workSetup.fixedHourlyRate?.toString() ?? '';
  }

  @override
  void dispose() {
    _workCategoryController.dispose();
    _totalBudgetController.dispose();
    _hourlyRateController.dispose();
    super.dispose();
  }

  Future<void> _saveWorkSetup() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final firestoreService = Provider.of<FirestoreService>(context, listen: false);
      
      final totalBudget = double.tryParse(_totalBudgetController.text) ?? 0.0;
      final hourlyRate = double.tryParse(_hourlyRateController.text) ?? 0.0;

      final workSetup = Labor(
        id: _isEditing ? widget.workSetup!.id : const Uuid().v4(),
        projectId: widget.project.id,
        type: LaborType.nonContracted,
        entryType: LaborEntryType.contract, // Work setup uses "contract" entry type
        workCategory: _workCategoryController.text.trim(),
        totalBudget: totalBudget,
        fixedHourlyRate: hourlyRate,
        createdAt: _isEditing ? widget.workSetup!.createdAt : DateTime.now(),
        updatedAt: DateTime.now(),
      );

      print('💾 WORK_SETUP_SCREEN: Creating work setup with ID: ${workSetup.id}');
      print('💾 WORK_SETUP_SCREEN: Work setup details - Category: ${workSetup.workCategory}, Budget: ${workSetup.totalBudget}, Rate: ${workSetup.fixedHourlyRate}');
      
      bool success;
      if (_isEditing) {
        success = await firestoreService.updateLabor(workSetup);
        print('💾 WORK_SETUP_SCREEN: Update result: $success');
      } else {
        success = await firestoreService.createLabor(workSetup);
        print('💾 WORK_SETUP_SCREEN: Create result: $success');
      }

      if (mounted) {
        setState(() => _isLoading = false);
        
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(_isEditing 
                ? 'Work setup updated successfully' 
                : 'Work setup created successfully'),
            ),
          );
          Navigator.pop(context, true);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to save work setup')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final totalBudget = double.tryParse(_totalBudgetController.text) ?? 0.0;
    final hourlyRate = double.tryParse(_hourlyRateController.text) ?? 0.0;
    final maxHours = hourlyRate > 0 ? totalBudget / hourlyRate : 0.0;

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Work Setup' : 'Add Work Setup'),
        actions: [
          if (_isEditing)
            IconButton(
              onPressed: () => _showDeleteDialog(),
              icon: const Icon(Icons.delete),
              tooltip: 'Delete Work Setup',
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header info
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.work_history,
                          color: Theme.of(context).colorScheme.primary,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Non-Contracted Work Setup',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Set up budget-based work tracking. You can track progress later.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Work Category - Simple Text Input
              TextFormField(
                controller: _workCategoryController,
                decoration: const InputDecoration(
                  labelText: 'Work Category',
                  hintText: 'e.g., General Labor, Cleanup, Maintenance',
                  prefixIcon: Icon(Icons.category),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter work category';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Total Budget
              TextFormField(
                controller: _totalBudgetController,
                decoration: const InputDecoration(
                  labelText: 'Total Budget',
                  hintText: 'e.g., 1000',
                  prefixIcon: Icon(Icons.account_balance_wallet),
                  prefixText: '\$',
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                ],
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter total budget';
                  }
                  final budget = double.tryParse(value);
                  if (budget == null || budget <= 0) {
                    return 'Please enter a valid budget';
                  }
                  return null;
                },
                onChanged: (value) => setState(() {}), // Trigger rebuild for preview
              ),
              const SizedBox(height: 16),

              // Fixed Hourly Rate
              TextFormField(
                controller: _hourlyRateController,
                decoration: const InputDecoration(
                  labelText: 'Fixed Hourly Rate',
                  hintText: 'e.g., 15.00',
                  prefixIcon: Icon(Icons.attach_money),
                  suffixText: '/ hour',
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                ],
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter hourly rate';
                  }
                  final rate = double.tryParse(value);
                  if (rate == null || rate <= 0) {
                    return 'Please enter a valid hourly rate';
                  }
                  return null;
                },
                onChanged: (value) => setState(() {}), // Trigger rebuild for preview
              ),
              const SizedBox(height: 24),

              // Budget Preview
              if (maxHours > 0)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.calculate,
                            color: Theme.of(context).colorScheme.primary,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Work Setup Summary',
                            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _buildSummaryRow('Total Budget:', '\$${totalBudget.toStringAsFixed(2)}'),
                      _buildSummaryRow('Hourly Rate:', '\$${hourlyRate.toStringAsFixed(2)} / hour'),
                      const Divider(),
                      _buildSummaryRow(
                        'Max Hours Available:', 
                        '${maxHours.toStringAsFixed(1)} hours',
                        isTotal: true,
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 32),

              // Save button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveWorkSetup,
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(_isEditing ? 'Update Work Setup' : 'Create Work Setup'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: isTotal ? Theme.of(context).colorScheme.primary : null,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showDeleteDialog() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Work Setup'),
        content: const Text(
          'Are you sure you want to delete this work setup? This will also delete all associated progress entries.',
        ),
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
      await _deleteWorkSetup();
    }
  }

  Future<void> _deleteWorkSetup() async {
    setState(() => _isLoading = true);

    try {
      final firestoreService = Provider.of<FirestoreService>(context, listen: false);
      
      // TODO: Also delete associated progress entries
      final success = await firestoreService.deleteLabor(widget.workSetup!.id);

      if (mounted) {
        setState(() => _isLoading = false);
        
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Work setup deleted successfully')),
          );
          Navigator.pop(context, true);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to delete work setup')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    }
  }
}
