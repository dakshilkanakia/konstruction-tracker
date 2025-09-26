import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../models/component.dart';
import '../models/labor.dart';
import '../models/project.dart';
import '../services/firestore_service.dart';

class AddContractScreen extends StatefulWidget {
  final Project project;
  final Labor? contract; // For editing existing contracts

  const AddContractScreen({
    super.key,
    required this.project,
    this.contract,
  });

  @override
  State<AddContractScreen> createState() => _AddContractScreenState();
}

class _AddContractScreenState extends State<AddContractScreen> {
  final _formKey = GlobalKey<FormState>();
  final _workCategoryController = TextEditingController();
  final _totalSqFtController = TextEditingController();
  final _ratePerSqFtController = TextEditingController();

  bool _isLoading = false;
  bool _isLoadingComponents = true;
  List<Component> _components = [];
  String? _selectedComponent;
  bool get _isEditing => widget.contract != null;

  @override
  void initState() {
    super.initState();
    _loadComponents();
  }

  void _populateFields() {
    final contract = widget.contract!;
    _totalSqFtController.text = contract.totalSqFt?.toString() ?? '';
    _ratePerSqFtController.text = contract.ratePerSqFt?.toString() ?? '';
    
    // Check if work category matches an existing component
    final matchingComponent = _components.where((c) => c.name == contract.workCategory).firstOrNull;
    if (matchingComponent != null) {
      _selectedComponent = contract.workCategory;
    } else {
      _selectedComponent = 'custom';
      _workCategoryController.text = contract.workCategory;
    }
  }

  Future<void> _loadComponents() async {
    try {
      final firestoreService = Provider.of<FirestoreService>(context, listen: false);
      final components = await firestoreService.getProjectComponents(widget.project.id);
      setState(() {
        _components = components;
        _isLoadingComponents = false;
        
        if (_isEditing) {
          _populateFields();
        }
      });
    } catch (e) {
      setState(() => _isLoadingComponents = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading components: $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    _workCategoryController.dispose();
    _totalSqFtController.dispose();
    _ratePerSqFtController.dispose();
    super.dispose();
  }

  Future<void> _saveContract() async {
    if (!_formKey.currentState!.validate()) return;
    
    // Validate component selection
    if (_selectedComponent == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a component')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final firestoreService = Provider.of<FirestoreService>(context, listen: false);
      
      final totalSqFt = double.tryParse(_totalSqFtController.text) ?? 0.0;
      final ratePerSqFt = double.tryParse(_ratePerSqFtController.text) ?? 0.0;

      final contract = Labor(
        id: _isEditing ? widget.contract!.id : const Uuid().v4(),
        projectId: widget.project.id,
        type: LaborType.contracted,
        entryType: LaborEntryType.contract,
        workCategory: _selectedComponent == 'custom' 
            ? _workCategoryController.text.trim()
            : _selectedComponent!,
        totalSqFt: totalSqFt,
        ratePerSqFt: ratePerSqFt,
        createdAt: _isEditing ? widget.contract!.createdAt : DateTime.now(),
        updatedAt: DateTime.now(),
      );

      print('💾 CONTRACT_SCREEN: Creating contract with ID: ${contract.id}');
      print('💾 CONTRACT_SCREEN: Contract details - Category: ${contract.workCategory}, SqFt: ${contract.totalSqFt}, Rate: ${contract.ratePerSqFt}');
      
      bool success;
      if (_isEditing) {
        success = await firestoreService.updateLabor(contract);
        print('💾 CONTRACT_SCREEN: Update result: $success');
        
        // Sync component after contract update
        if (success) {
          await firestoreService.syncLaborProgressToComponent(
            widget.project.id,
            contract.workCategory,
          );
        }
      } else {
        success = await firestoreService.createLabor(contract);
        print('💾 CONTRACT_SCREEN: Create result: $success');
      }

      if (mounted) {
        setState(() => _isLoading = false);
        
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(_isEditing 
                ? 'Contract updated successfully' 
                : 'Contract created successfully'),
            ),
          );
          Navigator.pop(context, true);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to save contract')),
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
    final totalSqFt = double.tryParse(_totalSqFtController.text) ?? 0.0;
    final ratePerSqFt = double.tryParse(_ratePerSqFtController.text) ?? 0.0;
    final totalBudget = totalSqFt * ratePerSqFt;

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Contract' : 'Add New Contract'),
        actions: [
          if (_isEditing)
            IconButton(
              onPressed: () => _showDeleteDialog(),
              icon: const Icon(Icons.delete),
              tooltip: 'Delete Contract',
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
                          Icons.assignment,
                          color: Theme.of(context).colorScheme.primary,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Contract Setup',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Set up a new contracted work agreement. You can track progress later.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Work Category - Component Dropdown
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_isLoadingComponents) ...[
                    const LinearProgressIndicator(),
                    const SizedBox(height: 8),
                    Text(
                      'Loading components...',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ] else ...[
                    // Component Dropdown
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        border: Border.all(color: Theme.of(context).colorScheme.outline),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedComponent,
                          hint: const Text('Select Component'),
                          isExpanded: true,
                          items: [
                            // Existing components
                            ..._components.map((component) => DropdownMenuItem<String>(
                              value: component.name,
                              child: Text(component.name),
                            )),
                            // Custom option
                            const DropdownMenuItem<String>(
                              value: 'custom',
                              child: Text('Custom Component'),
                            ),
                          ],
                          onChanged: (value) {
                            setState(() {
                              _selectedComponent = value;
                              if (value != 'custom') {
                                _workCategoryController.clear();
                              }
                            });
                          },
                        ),
                      ),
                    ),
                    // Custom component text field (shown when "Custom Component" is selected)
                    if (_selectedComponent == 'custom') ...[
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _workCategoryController,
                        decoration: const InputDecoration(
                          labelText: 'Custom Component Name',
                          hintText: 'Enter custom component name',
                          prefixIcon: Icon(Icons.edit),
                        ),
                        validator: (value) {
                          if (_selectedComponent == 'custom' && (value == null || value.trim().isEmpty)) {
                            return 'Please enter custom component name';
                          }
                          return null;
                        },
                      ),
                    ],
                  ],
                ],
              ),
              const SizedBox(height: 16),

              // Total Square Feet
              TextFormField(
                controller: _totalSqFtController,
                decoration: const InputDecoration(
                  labelText: 'Total Square Feet',
                  hintText: 'e.g., 1000',
                  prefixIcon: Icon(Icons.straighten),
                  suffixText: 'sq ft',
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                ],
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter total square feet';
                  }
                  final sqFt = double.tryParse(value);
                  if (sqFt == null || sqFt <= 0) {
                    return 'Please enter a valid square footage';
                  }
                  return null;
                },
                onChanged: (value) => setState(() {}), // Trigger rebuild for budget preview
              ),
              const SizedBox(height: 16),

              // Rate per Square Foot
              TextFormField(
                controller: _ratePerSqFtController,
                decoration: const InputDecoration(
                  labelText: 'Rate per Square Foot',
                  hintText: 'e.g., 2.50',
                  prefixIcon: Icon(Icons.attach_money),
                  suffixText: '/ sq ft',
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                ],
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter rate per square foot';
                  }
                  final rate = double.tryParse(value);
                  if (rate == null || rate <= 0) {
                    return 'Please enter a valid rate';
                  }
                  return null;
                },
                onChanged: (value) => setState(() {}), // Trigger rebuild for budget preview
              ),
              const SizedBox(height: 24),

              // Budget Preview
              if (totalBudget > 0)
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
                            'Contract Summary',
                            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _buildSummaryRow('Total Area:', '${totalSqFt.toStringAsFixed(1)} sq ft'),
                      _buildSummaryRow('Rate:', '\$${ratePerSqFt.toStringAsFixed(2)} / sq ft'),
                      const Divider(),
                      _buildSummaryRow(
                        'Total Contract Value:', 
                        '\$${totalBudget.toStringAsFixed(2)}',
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
                  onPressed: _isLoading ? null : _saveContract,
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(_isEditing ? 'Update Contract' : 'Create Contract'),
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
        title: const Text('Delete Contract'),
        content: const Text(
          'Are you sure you want to delete this contract? This will also delete all associated progress entries.',
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
      await _deleteContract();
    }
  }

  Future<void> _deleteContract() async {
    setState(() => _isLoading = true);

    try {
      final firestoreService = Provider.of<FirestoreService>(context, listen: false);
      
      // TODO: Also delete associated progress entries
      final success = await firestoreService.deleteLabor(widget.contract!.id);

      if (mounted) {
        setState(() => _isLoading = false);
        
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Contract deleted successfully')),
          );
          Navigator.pop(context, true);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to delete contract')),
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
