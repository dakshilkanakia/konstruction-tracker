import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../models/component.dart';
import '../models/project.dart';
import '../services/firestore_service.dart';

class LaborProgressData {
  final double minCompletedArea;
  final double minAmountUsed;
  
  LaborProgressData({
    required this.minCompletedArea,
    required this.minAmountUsed,
  });
}

class AddComponentScreen extends StatefulWidget {
  final Project project;
  final Component? component; // For editing existing component

  const AddComponentScreen({
    super.key,
    required this.project,
    this.component,
  });

  @override
  State<AddComponentScreen> createState() => _AddComponentScreenState();
}

class _AddComponentScreenState extends State<AddComponentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _totalAreaController = TextEditingController();
  final _completedAreaController = TextEditingController();
  final _componentBudgetController = TextEditingController();
  final _amountUsedController = TextEditingController();
  final _totalConcreteController = TextEditingController();
  final _concretePouredController = TextEditingController();
  bool _isLoading = false;

  bool get _isEditing => widget.component != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      _nameController.text = widget.component!.name;
      _totalAreaController.text = widget.component!.totalArea.toString();
      _completedAreaController.text = widget.component!.completedArea.toString();
      _componentBudgetController.text = widget.component!.componentBudget.toString();
      _amountUsedController.text = widget.component!.amountUsed.toString();
      _totalConcreteController.text = widget.component!.totalConcrete.toString();
      _concretePouredController.text = widget.component!.concretePoured.toString();
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _totalAreaController.dispose();
    _completedAreaController.dispose();
    _componentBudgetController.dispose();
    _amountUsedController.dispose();
    _totalConcreteController.dispose();
    _concretePouredController.dispose();
    super.dispose();
  }

  Future<void> _saveComponent() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final totalArea = double.parse(_totalAreaController.text);
    final completedArea = double.parse(_completedAreaController.text);
    final componentBudget = double.parse(_componentBudgetController.text);
    final amountUsed = double.parse(_amountUsedController.text.isEmpty ? '0' : _amountUsedController.text);
    final totalConcrete = double.parse(_totalConcreteController.text.isEmpty ? '0' : _totalConcreteController.text);
    final concretePoured = double.parse(_concretePouredController.text.isEmpty ? '0' : _concretePouredController.text);

    // Validation: completed area cannot exceed total area
    if (completedArea > totalArea) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Completed area cannot exceed total area'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Validation: amount used cannot exceed component budget
    if (componentBudget > 0 && amountUsed > componentBudget) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Amount used cannot exceed component budget'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    // For zero budget components, amount used should be zero
    if (componentBudget == 0 && amountUsed > 0) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('For zero budget components, amount used must be zero'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Allow concrete poured to exceed total concrete (overpour is allowed)
    // Show warning if concrete poured exceeds total concrete
    if (concretePoured > totalConcrete) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Warning: Concrete poured (${concretePoured.toStringAsFixed(1)} cu yd) exceeds total concrete (${totalConcrete.toStringAsFixed(1)} cu yd)'),
          backgroundColor: Colors.orange,
        ),
      );
    }

    // Validate against labor progress (only for existing components and when amount used is being changed)
    if (_isEditing) {
      final firestoreService = Provider.of<FirestoreService>(context, listen: false);
      final laborProgress = await _getLaborProgress(firestoreService, widget.component!.name);
      
      // Only validate completed area if it's different from the original
      if (completedArea != widget.component!.completedArea && completedArea < laborProgress.minCompletedArea) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Progress cannot be less than ${laborProgress.minCompletedArea.toStringAsFixed(1)} sq ft'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
      
      // Only validate amount used if it's different from the original
      if (amountUsed != widget.component!.amountUsed && amountUsed < laborProgress.minAmountUsed) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Amount used cannot be less than \$${laborProgress.minAmountUsed.toStringAsFixed(2)}'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
    }

    final component = Component(
      id: _isEditing ? widget.component!.id : const Uuid().v4(),
      projectId: widget.project.id,
      name: _nameController.text.trim(),
      totalArea: totalArea,
      completedArea: completedArea,
      componentBudget: componentBudget,
      amountUsed: amountUsed,
      totalConcrete: totalConcrete,
      concretePoured: concretePoured,
      originalCompletedArea: _isEditing && completedArea == widget.component!.completedArea 
          ? widget.component!.originalCompletedArea 
          : completedArea,
      originalAmountUsed: _isEditing && amountUsed == widget.component!.amountUsed 
          ? widget.component!.originalAmountUsed 
          : amountUsed,
      createdAt: _isEditing ? widget.component!.createdAt : DateTime.now(),
      updatedAt: DateTime.now(),
    );

    final firestoreService = Provider.of<FirestoreService>(context, listen: false);
    final success = _isEditing
        ? await firestoreService.updateComponent(component)
        : await firestoreService.createComponent(component);

    if (success && _isEditing) {
      // Sync component changes to work setup (if exists) - only for editing, not creating
      await firestoreService.syncComponentToWorkSetup(component.projectId, component.name);
    }

    setState(() => _isLoading = false);

    if (success && mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isEditing 
              ? 'Component updated successfully' 
              : 'Component added successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isEditing 
              ? 'Failed to update component' 
              : 'Failed to add component'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Component' : 'Add Component'),
        backgroundColor: _isEditing 
            ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
            : null,
        foregroundColor: _isEditing 
            ? Theme.of(context).colorScheme.primary
            : null,
        actions: [
          if (_isEditing)
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: _showDeleteConfirmation,
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Project Info
            Card(
              color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(
                      Icons.business,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Project',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          Text(
                            widget.project.name,
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Component Name
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Component Name *',
                hintText: 'e.g., Sidewalk, Heavy duty pavement',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.business),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a component name';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Total Area
            TextFormField(
              controller: _totalAreaController,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
              ],
              decoration: const InputDecoration(
                labelText: 'Total Area (sq ft) *',
                hintText: 'Enter total area in square feet',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.square_foot),
                suffixText: 'sq ft',
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter total area';
                }
                final area = double.tryParse(value);
                if (area == null || area <= 0) {
                  return 'Please enter a valid area';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Completed Area
            TextFormField(
              controller: _completedAreaController,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
              ],
              decoration: const InputDecoration(
                labelText: 'Completed Area (sq ft) *',
                hintText: 'Enter completed area in square feet',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.done),
                suffixText: 'sq ft',
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter completed area';
                }
                final area = double.tryParse(value);
                if (area == null || area < 0) {
                  return 'Please enter a valid area';
                }
                return null;
              },
              onChanged: (value) {
                // Real-time validation feedback
                final completedArea = double.tryParse(value);
                final totalArea = double.tryParse(_totalAreaController.text);
                
                if (completedArea != null && totalArea != null && completedArea > totalArea) {
                  // Show warning but don't prevent input
                  setState(() {});
                }
              },
            ),
            const SizedBox(height: 16),

            // Component Budget
            TextFormField(
              controller: _componentBudgetController,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
              ],
              decoration: const InputDecoration(
                labelText: 'Component Budget *',
                hintText: 'Total budget allocated for this component',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.account_balance_wallet),
                prefixText: '\$',
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter component budget';
                }
                final budget = double.tryParse(value);
                if (budget == null || budget < 0) {
                  return 'Please enter a valid budget amount (zero is allowed)';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Amount Used
            TextFormField(
              controller: _amountUsedController,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
              ],
              decoration: const InputDecoration(
                labelText: 'Amount Used',
                hintText: 'Amount spent on this component so far',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.money_off),
                prefixText: '\$',
              ),
              validator: (value) {
                if (value != null && value.trim().isNotEmpty) {
                  final amount = double.tryParse(value);
                  if (amount == null || amount < 0) {
                    return 'Please enter a valid amount';
                  }
                }
                return null;
              },
              onChanged: (value) {
                // Real-time validation for budget exceeded
                final amountUsed = double.tryParse(value);
                final componentBudget = double.tryParse(_componentBudgetController.text);
                
                if (amountUsed != null && componentBudget != null) {
                  if (componentBudget > 0 && amountUsed > componentBudget) {
                    setState(() {});
                  } else if (componentBudget == 0 && amountUsed > 0) {
                    setState(() {});
                  }
                }
              },
            ),
            const SizedBox(height: 16),

            // Total Concrete
            TextFormField(
              controller: _totalConcreteController,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
              ],
              decoration: const InputDecoration(
                labelText: 'Total Concrete',
                hintText: 'Total concrete needed in cubic yards',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.local_shipping),
                suffixText: 'cu yd',
              ),
              validator: (value) {
                if (value != null && value.trim().isNotEmpty) {
                  final concrete = double.tryParse(value);
                  if (concrete == null || concrete < 0) {
                    return 'Please enter a valid concrete amount';
                  }
                }
                return null;
              },
              onChanged: (value) {
                setState(() {}); // Trigger rebuild for progress preview
              },
            ),
            const SizedBox(height: 16),

            // Concrete Poured
            TextFormField(
              controller: _concretePouredController,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
              ],
              decoration: const InputDecoration(
                labelText: 'Concrete Poured',
                hintText: 'Concrete already poured in cubic yards',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.opacity),
                suffixText: 'cu yd',
              ),
              validator: (value) {
                if (value != null && value.trim().isNotEmpty) {
                  final poured = double.tryParse(value);
                  if (poured == null || poured < 0) {
                    return 'Please enter a valid concrete amount';
                  }
                }
                return null;
              },
              onChanged: (value) {
                // Real-time validation for concrete exceeded (now shows warning instead of error)
                final concretePoured = double.tryParse(value);
                final totalConcrete = double.tryParse(_totalConcreteController.text);
                
                if (concretePoured != null && totalConcrete != null && concretePoured > totalConcrete) {
                  setState(() {}); // Trigger UI update to show warning
                }
              },
            ),
            const SizedBox(height: 8),

            // Progress Preview
            if (_totalAreaController.text.isNotEmpty && _completedAreaController.text.isNotEmpty)
              _buildAreaProgressPreview(),
            
            // Budget Progress Preview
            if (_componentBudgetController.text.isNotEmpty && _amountUsedController.text.isNotEmpty)
              _buildBudgetProgressPreview(),
            
            // Concrete Progress Preview
            if (_totalConcreteController.text.isNotEmpty && _concretePouredController.text.isNotEmpty)
              _buildConcreteProgressPreview(),

            const SizedBox(height: 32),

            // Save Button
            ElevatedButton(
              onPressed: _isLoading ? null : _saveComponent,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(_isEditing ? 'Update Component' : 'Add Component'),
            ),
            const SizedBox(height: 16),

            // Info Text
            Text(
              '* Required fields\n\nYou can update the completed area daily as work progresses.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAreaProgressPreview() {
    final totalArea = double.tryParse(_totalAreaController.text) ?? 0;
    final completedArea = double.tryParse(_completedAreaController.text) ?? 0;
    
    if (totalArea <= 0) return const SizedBox.shrink();
    
    final progress = (completedArea / totalArea).clamp(0.0, 1.0);
    final isOvercomplete = completedArea > totalArea;
    
    return Card(
      color: isOvercomplete 
          ? Colors.red.withOpacity(0.1)
          : Theme.of(context).colorScheme.surfaceVariant,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isOvercomplete ? Icons.error : Icons.preview,
                  color: isOvercomplete ? Colors.red : Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
              Text(
                isOvercomplete ? 'Error: Area Exceeded' : 'Area Progress Preview',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: isOvercomplete ? Colors.red : null,
                  fontWeight: FontWeight.bold,
                ),
              ),
              ],
            ),
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: progress,
              backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
              color: isOvercomplete ? Colors.red : Colors.green,
            ),
            const SizedBox(height: 8),
            Text(
              isOvercomplete 
                  ? 'Completed area cannot exceed total area'
                  : '${(progress * 100).toStringAsFixed(1)}% Complete • ${(totalArea - completedArea).toStringAsFixed(1)} sq ft remaining',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: isOvercomplete ? Colors.red : null,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBudgetProgressPreview() {
    final componentBudget = double.tryParse(_componentBudgetController.text) ?? 0;
    final amountUsed = double.tryParse(_amountUsedController.text) ?? 0;
    
    if (componentBudget <= 0) return const SizedBox.shrink();
    
    final progress = (amountUsed / componentBudget).clamp(0.0, 1.0);
    final isOverBudget = amountUsed > componentBudget;
    final isWarning = progress > 0.8;
    
    return Card(
      color: isOverBudget 
          ? Colors.red.withOpacity(0.1)
          : isWarning
              ? Colors.orange.withOpacity(0.1)
              : Theme.of(context).colorScheme.surfaceVariant,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isOverBudget ? Icons.error : isWarning ? Icons.warning : Icons.account_balance_wallet,
                  color: isOverBudget ? Colors.red : isWarning ? Colors.orange : Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  isOverBudget ? 'Error: Budget Exceeded' : 'Budget Progress Preview',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: isOverBudget ? Colors.red : isWarning ? Colors.orange : null,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: progress,
              backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
              color: isOverBudget ? Colors.red : isWarning ? Colors.orange : Colors.green,
            ),
            const SizedBox(height: 8),
            Text(
              isOverBudget 
                  ? 'Amount used cannot exceed component budget'
                  : '${(progress * 100).toStringAsFixed(1)}% of budget used • \$${(componentBudget - amountUsed).toStringAsFixed(2)} remaining',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: isOverBudget ? Colors.red : isWarning ? Colors.orange : null,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Component'),
        content: Text('Are you sure you want to delete "${widget.component!.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: Implement delete functionality
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Delete functionality - Coming Soon')),
              );
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Widget _buildConcreteProgressPreview() {
    final totalConcrete = double.tryParse(_totalConcreteController.text) ?? 0;
    final concretePoured = double.tryParse(_concretePouredController.text) ?? 0;
    
    if (totalConcrete <= 0) return const SizedBox.shrink();
    
    final progress = concretePoured / totalConcrete; // Allow progress above 100%
    final isOvercomplete = concretePoured > totalConcrete;
    final isWarning = progress > 0.8 && !isOvercomplete;
    
    return Card(
      color: isOvercomplete 
          ? Colors.red.withOpacity(0.1)
          : isWarning 
              ? Colors.orange.withOpacity(0.1)
              : Theme.of(context).colorScheme.surfaceVariant,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isOvercomplete ? Icons.error : Icons.opacity,
                  color: isOvercomplete 
                      ? Colors.red 
                      : isWarning 
                          ? Colors.orange 
                          : Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  isOvercomplete ? 'Error: Concrete Exceeded' : 'Concrete Progress Preview',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: isOvercomplete ? Colors.red : isWarning ? Colors.orange : null,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: progress,
              backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
              color: isOvercomplete ? Colors.red : isWarning ? Colors.orange : Colors.green,
            ),
            const SizedBox(height: 8),
            Text(
              isOvercomplete 
                  ? 'Warning: Concrete poured exceeds total by ${(concretePoured - totalConcrete).toStringAsFixed(1)} cu yd'
                  : '${(progress * 100).toStringAsFixed(1)}% Complete • ${(totalConcrete - concretePoured).toStringAsFixed(1)} cu yd remaining',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: isOvercomplete ? Colors.orange : isWarning ? Colors.orange : null,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<LaborProgressData> _getLaborProgress(FirestoreService firestoreService, String componentName) async {
    try {
      final allLabor = await firestoreService.getProjectLabor(widget.project.id);
      
      // Get all labor entries for this component
      final componentLabor = allLabor.where((l) => l.workCategory == componentName).toList();
      
      // Calculate minimum completed area from contract progress
      final contractProgressEntries = componentLabor
          .where((l) => l.isProgress && l.isContracted)
          .toList();
      
      final minCompletedArea = contractProgressEntries
          .fold(0.0, (sum, entry) => sum + (entry.completedSqFt ?? 0.0));
      
      // Calculate minimum amount used from all labor costs
      final minAmountUsed = componentLabor
          .fold(0.0, (sum, entry) => sum + entry.totalCost);
      
      return LaborProgressData(
        minCompletedArea: minCompletedArea,
        minAmountUsed: minAmountUsed,
      );
    } catch (e) {
      // If error, return zeros (no minimum validation)
      return LaborProgressData(
        minCompletedArea: 0.0,
        minAmountUsed: 0.0,
      );
    }
  }
}
