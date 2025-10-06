import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
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

class QuickEditComponentDialog extends StatefulWidget {
  final Component component;
  final Project project;

  const QuickEditComponentDialog({
    super.key,
    required this.component,
    required this.project,
  });

  @override
  State<QuickEditComponentDialog> createState() => _QuickEditComponentDialogState();
}

class _QuickEditComponentDialogState extends State<QuickEditComponentDialog> {
  final _formKey = GlobalKey<FormState>();
  final _completedAreaController = TextEditingController();
  final _amountUsedController = TextEditingController();
  final _concretePouredController = TextEditingController();
  bool _isLoading = false;
  bool _showAdvanced = false;
  
  // Advanced fields
  final _nameController = TextEditingController();
  final _totalAreaController = TextEditingController();
  final _componentBudgetController = TextEditingController();
  final _totalConcreteController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Pre-fill with current values
    _completedAreaController.text = widget.component.completedArea.toString();
    _amountUsedController.text = widget.component.amountUsed.toString();
    _concretePouredController.text = widget.component.concretePoured.toString();
    
    // Advanced fields
    _nameController.text = widget.component.name;
    _totalAreaController.text = widget.component.totalArea.toString();
    _componentBudgetController.text = widget.component.componentBudget.toString();
    _totalConcreteController.text = widget.component.totalConcrete.toString();
  }

  @override
  void dispose() {
    _completedAreaController.dispose();
    _amountUsedController.dispose();
    _concretePouredController.dispose();
    _nameController.dispose();
    _totalAreaController.dispose();
    _componentBudgetController.dispose();
    _totalConcreteController.dispose();
    super.dispose();
  }

  Future<void> _saveComponent() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final completedArea = double.parse(_completedAreaController.text);
    final amountUsed = double.parse(_amountUsedController.text.isEmpty ? '0' : _amountUsedController.text);
    final concretePoured = double.parse(_concretePouredController.text.isEmpty ? '0' : _concretePouredController.text);

    // Validate against labor progress (only when values are being changed)
    final firestoreService = Provider.of<FirestoreService>(context, listen: false);
    final laborProgress = await _getLaborProgress(firestoreService);
    
    // Only validate completed area if it's different from the original
    if (completedArea != widget.component.completedArea && completedArea < laborProgress.minCompletedArea) {
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
    if (amountUsed != widget.component.amountUsed && amountUsed < laborProgress.minAmountUsed) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Amount used cannot be less than \$${laborProgress.minAmountUsed.toStringAsFixed(2)}'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    // Get values from advanced fields if shown, otherwise use current values
    final name = _showAdvanced ? _nameController.text.trim() : widget.component.name;
    final totalArea = _showAdvanced ? double.parse(_totalAreaController.text) : widget.component.totalArea;
    final componentBudget = _showAdvanced ? double.parse(_componentBudgetController.text) : widget.component.componentBudget;
    final totalConcrete = _showAdvanced ? double.parse(_totalConcreteController.text) : widget.component.totalConcrete;

    final updatedComponent = widget.component.copyWith(
      name: name,
      totalArea: totalArea,
      completedArea: completedArea,
      componentBudget: componentBudget,
      amountUsed: amountUsed,
      totalConcrete: totalConcrete,
      concretePoured: concretePoured,
      updatedAt: DateTime.now(),
    );

    final success = await firestoreService.updateComponent(updatedComponent);

    if (success) {
      // Sync component changes to work setup (if exists)
      await firestoreService.syncComponentToWorkSetup(widget.project.id, updatedComponent.name);
    }

    setState(() => _isLoading = false);

    if (success && mounted) {
      Navigator.pop(context, true); // Return true to indicate success
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Component updated successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to update component'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<LaborProgressData> _getLaborProgress(FirestoreService firestoreService) async {
    try {
      final allLabor = await firestoreService.getProjectLabor(widget.project.id);
      
      // Get all labor entries for this component
      final componentLabor = allLabor.where((l) => l.workCategory == widget.component.name).toList();
      
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

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 600),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Header
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.edit,
                          color: Theme.of(context).colorScheme.primary,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Quick Update',
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              widget.component.name,
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Context Info (Read-only)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Total Area',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                              Text(
                                '${widget.component.totalArea.toStringAsFixed(1)} sq ft',
                                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Component Budget',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                              Text(
                                '\$${widget.component.componentBudget.toStringAsFixed(0)}',
                                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Total Concrete',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                              Text(
                                '${widget.component.totalConcrete.toStringAsFixed(1)} cu yd',
                                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Advanced Fields (if expanded)
                  if (_showAdvanced) ...[
                    Text(
                      'Advanced Settings',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Component Name
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Component Name *',
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

                    // Component Budget
                    TextFormField(
                      controller: _componentBudgetController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
                      ],
                      decoration: const InputDecoration(
                        labelText: 'Component Budget *',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.account_balance_wallet),
                        prefixText: '\$',
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter component budget';
                        }
                        final budget = double.tryParse(value);
                        if (budget == null || budget <= 0) {
                          return 'Please enter a valid budget amount';
                        }
                        return null;
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
                    ),
                    const SizedBox(height: 20),
                  ],

                  // Quick Update Fields
                  Text(
                    _showAdvanced ? 'Progress Update' : 'Update Progress',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
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
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.done),
                      suffixText: 'sq ft',
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter completed area';
                      }
                      final completedArea = double.tryParse(value);
                      if (completedArea == null || completedArea < 0) {
                        return 'Please enter a valid area';
                      }
                      
                      final totalArea = _showAdvanced 
                          ? double.tryParse(_totalAreaController.text) ?? widget.component.totalArea
                          : widget.component.totalArea;
                      
                      if (completedArea > totalArea) {
                        return 'Completed area cannot exceed total area';
                      }
                      return null;
                    },
                    onChanged: (value) => setState(() {}),
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
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.money_off),
                      prefixText: '\$',
                    ),
                    validator: (value) {
                      if (value != null && value.trim().isNotEmpty) {
                        final amountUsed = double.tryParse(value);
                        if (amountUsed == null || amountUsed < 0) {
                          return 'Please enter a valid amount';
                        }
                        
                        // Allow amount used to exceed component budget - warning is shown in UI
                      }
                      return null;
                    },
                    onChanged: (value) => setState(() {}),
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
                        
                        // Allow concrete poured to exceed total concrete (overpour is allowed)
                        // No validation error, just allow the value
                      }
                      return null;
                    },
                    onChanged: (value) => setState(() {}),
                  ),
                  const SizedBox(height: 20),

                  // Progress Preview
                  _buildProgressPreview(),
                  const SizedBox(height: 24),

                  // Action Buttons
                  Row(
                    children: [
                      if (!_showAdvanced)
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              setState(() => _showAdvanced = true);
                            },
                            child: const Text('Advanced Edit'),
                          ),
                        ),
                      if (!_showAdvanced) const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _saveComponent,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Text('Save Changes'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProgressPreview() {
    final totalArea = _showAdvanced 
        ? double.tryParse(_totalAreaController.text) ?? widget.component.totalArea
        : widget.component.totalArea;
    final completedArea = double.tryParse(_completedAreaController.text) ?? 0;
    final componentBudget = _showAdvanced 
        ? double.tryParse(_componentBudgetController.text) ?? widget.component.componentBudget
        : widget.component.componentBudget;
    final amountUsed = double.tryParse(_amountUsedController.text) ?? 0;
    final totalConcrete = _showAdvanced 
        ? double.tryParse(_totalConcreteController.text) ?? widget.component.totalConcrete
        : widget.component.totalConcrete;
    final concretePoured = double.tryParse(_concretePouredController.text) ?? 0;

    final areaProgress = totalArea > 0 ? (completedArea / totalArea) : 0.0;
    final budgetProgress = componentBudget > 0 ? (amountUsed / componentBudget) : 0.0;
    final concreteProgress = totalConcrete > 0 ? (concretePoured / totalConcrete) : 0.0;

    final isAreaExceeded = completedArea > totalArea;
    final isBudgetExceeded = amountUsed > componentBudget;
    final isConcreteExceeded = concretePoured > totalConcrete;
    final isBudgetWarning = budgetProgress > 0.8;
    final isConcreteWarning = concreteProgress > 0.8;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Live Preview',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),

          // Area Progress
          Row(
            children: [
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Area Progress',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 4),
                    LinearProgressIndicator(
                      value: areaProgress,
                      backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
                      color: isAreaExceeded ? Colors.red : Colors.green,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '${(areaProgress * 100).toStringAsFixed(1)}%',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: isAreaExceeded ? Colors.red : Colors.green,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Concrete Progress
          if (totalConcrete > 0) ...[
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Concrete Progress',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(height: 4),
                      LinearProgressIndicator(
                        value: concreteProgress,
                        backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
                        color: isConcreteExceeded 
                            ? Colors.red 
                            : isConcreteWarning 
                                ? Colors.orange 
                                : Colors.green,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  '${(concreteProgress * 100).toStringAsFixed(1)}%',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: isConcreteExceeded 
                        ? Colors.red 
                        : isConcreteWarning 
                            ? Colors.orange 
                            : Colors.green,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
          ],

          // Budget Progress
          Row(
            children: [
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Budget Progress',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 4),
                    LinearProgressIndicator(
                      value: budgetProgress,
                      backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
                      color: isBudgetExceeded 
                          ? Colors.red 
                          : isBudgetWarning 
                              ? Colors.orange 
                              : Colors.green,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '${(budgetProgress * 100).toStringAsFixed(1)}%',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: isBudgetExceeded 
                      ? Colors.red 
                      : isBudgetWarning 
                          ? Colors.orange 
                          : Colors.green,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),

          // Warnings
          if (isAreaExceeded || isBudgetExceeded || isConcreteExceeded) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  Icons.error,
                  color: Colors.red,
                  size: 16,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    _getWarningMessage(isAreaExceeded, isBudgetExceeded, isConcreteExceeded),
                    style: TextStyle(
                      color: Colors.red,
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
    );
  }

  String _getWarningMessage(bool isAreaExceeded, bool isBudgetExceeded, bool isConcreteExceeded) {
    final exceededItems = <String>[];
    if (isAreaExceeded) exceededItems.add('area');
    if (isBudgetExceeded) exceededItems.add('budget');
    // Concrete overpour is now allowed, so don't add to exceeded items
    
    if (exceededItems.length == 1) {
      return '${exceededItems[0].substring(0, 1).toUpperCase()}${exceededItems[0].substring(1)} limit exceeded';
    } else if (exceededItems.length == 2) {
      return '${exceededItems[0].substring(0, 1).toUpperCase()}${exceededItems[0].substring(1)} and ${exceededItems[1]} limits exceeded';
    } else {
      return 'Area and budget limits exceeded';
    }
  }
}
