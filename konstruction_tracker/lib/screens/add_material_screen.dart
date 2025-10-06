import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../models/material.dart' as models;
import '../services/firestore_service.dart';

class AddMaterialScreen extends StatefulWidget {
  final String projectId;
  final models.Material? material;

  const AddMaterialScreen({
    super.key,
    required this.projectId,
    this.material,
  });

  @override
  State<AddMaterialScreen> createState() => _AddMaterialScreenState();
}

class _AddMaterialScreenState extends State<AddMaterialScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _quantityOrderedController = TextEditingController();
  final _costPerUnitController = TextEditingController();
  final _totalCostController = TextEditingController();
  final _unitController = TextEditingController();

  bool _isLoading = false;
  bool get _isEditing => widget.material != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      _populateFields();
    } else {
      _unitController.text = 'units'; // Default unit
    }
  }

  void _populateFields() {
    final material = widget.material!;
    _nameController.text = material.name ?? '';
    _quantityOrderedController.text = material.quantityOrdered?.toString() ?? '';
    _costPerUnitController.text = material.costPerUnit?.toString() ?? '';
    _totalCostController.text = material.totalCost?.toString() ?? '';
    _unitController.text = material.unit ?? '';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _quantityOrderedController.dispose();
    _costPerUnitController.dispose();
    _totalCostController.dispose();
    _unitController.dispose();
    super.dispose();
  }

  Future<void> _saveMaterial() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final firestoreService = Provider.of<FirestoreService>(context, listen: false);
      
      // Parse values only if they're not empty
      final quantityOrdered = _quantityOrderedController.text.trim().isEmpty 
          ? null 
          : double.tryParse(_quantityOrderedController.text);
      final costPerUnit = _costPerUnitController.text.trim().isEmpty 
          ? null 
          : double.tryParse(_costPerUnitController.text);
      final totalCost = _totalCostController.text.trim().isEmpty 
          ? null 
          : double.tryParse(_totalCostController.text);

      // Validate that if both quantity and cost per unit are provided, total cost should match
      if (quantityOrdered != null && costPerUnit != null && totalCost != null) {
        final calculatedTotal = quantityOrdered * costPerUnit;
        if ((calculatedTotal - totalCost).abs() > 0.01) { // Allow small floating point differences
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Total cost (\$${totalCost.toStringAsFixed(2)}) must match calculated cost (\$${calculatedTotal.toStringAsFixed(2)})'),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }
      }

      final material = models.Material(
        id: _isEditing ? widget.material!.id : const Uuid().v4(),
        projectId: widget.projectId,
        name: _nameController.text.trim().isEmpty ? null : _nameController.text.trim(),
        quantityOrdered: quantityOrdered,
        costPerUnit: costPerUnit,
        totalCost: totalCost,
        unit: _unitController.text.trim().isEmpty ? null : _unitController.text.trim(),
        createdAt: _isEditing ? widget.material!.createdAt : DateTime.now(),
        updatedAt: DateTime.now(),
      );

      if (_isEditing) {
        await firestoreService.updateMaterial(material);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Material updated successfully')),
          );
        }
      } else {
        final success = await firestoreService.createMaterial(material);
        print('💾 ADD_SCREEN: Create material result: $success');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(success ? 'Material added successfully' : 'Failed to add material')),
          );
        }
      }

      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving material: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _showDeleteConfirmation() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Material'),
        content: Text('Are you sure you want to delete "${widget.material!.name}"?'),
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
      setState(() => _isLoading = true);
      try {
        final firestoreService = Provider.of<FirestoreService>(context, listen: false);
        await firestoreService.deleteMaterial(widget.material!.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Material deleted successfully')),
          );
          Navigator.pop(context, true);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error deleting material: $e')),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Material' : 'Add Material'),
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
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Material name
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Material Name',
                  hintText: 'e.g., Concrete, Steel, Lumber',
                  prefixIcon: Icon(Icons.inventory_2),
                ),
                validator: (value) {
                  // Material name is optional
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Quantity ordered
              TextFormField(
                controller: _quantityOrderedController,
                decoration: const InputDecoration(
                  labelText: 'Quantity Ordered',
                  hintText: 'e.g., 100',
                  prefixIcon: Icon(Icons.shopping_cart),
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                ],
                validator: (value) {
                  // Quantity ordered is optional, but if provided, must be valid
                  if (value != null && value.trim().isNotEmpty) {
                    final quantity = double.tryParse(value);
                    if (quantity == null || quantity <= 0) {
                      return 'Please enter a valid quantity';
                    }
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),


              // Cost per unit
              TextFormField(
                controller: _costPerUnitController,
                decoration: const InputDecoration(
                  labelText: 'Cost per Unit',
                  hintText: 'e.g., 5.50',
                  prefixIcon: Icon(Icons.attach_money),
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                ],
                validator: (value) {
                  // Cost per unit is optional, but if provided, must be valid
                  if (value != null && value.trim().isNotEmpty) {
                    final cost = double.tryParse(value);
                    if (cost == null || cost < 0) {
                      return 'Please enter a valid cost';
                    }
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Total Cost
              Builder(
                builder: (context) {
                  final quantity = double.tryParse(_quantityOrderedController.text);
                  final costPerUnit = double.tryParse(_costPerUnitController.text);
                  final hasBothValues = quantity != null && costPerUnit != null;
                  
                  // Auto-calculate total cost if both quantity and cost per unit are provided
                  if (hasBothValues && _totalCostController.text.isEmpty) {
                    final calculatedTotal = quantity * costPerUnit;
                    _totalCostController.text = calculatedTotal.toStringAsFixed(2);
                  }
                  
                  return TextFormField(
                    controller: _totalCostController,
                    enabled: !hasBothValues, // Disable if both quantity and cost per unit are provided
                    decoration: InputDecoration(
                      labelText: hasBothValues ? 'Total Cost (Calculated)' : 'Total Cost',
                      hintText: hasBothValues ? 'Auto-calculated' : 'e.g., 550.00',
                      prefixIcon: const Icon(Icons.attach_money),
                    ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                ],
                validator: (value) {
                  // Total cost is optional, but if provided, must be valid
                  if (value != null && value.trim().isNotEmpty) {
                    final cost = double.tryParse(value);
                    if (cost == null || cost < 0) {
                      return 'Please enter a valid total cost';
                    }
                  }
                  return null;
                },
                onChanged: (value) => setState(() {}), // Trigger rebuild for preview
                  );
                },
              ),
              const SizedBox(height: 16),

              // Unit
              TextFormField(
                controller: _unitController,
                decoration: const InputDecoration(
                  labelText: 'Unit',
                  hintText: 'e.g., cubic yards, tons, pieces',
                  prefixIcon: Icon(Icons.straighten),
                ),
                validator: (value) {
                  // Unit is optional
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // Cost preview
              if (_costPerUnitController.text.isNotEmpty && 
                  _quantityOrderedController.text.isNotEmpty)
                _buildCostPreview(),

              const SizedBox(height: 24),

              // Save button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveMaterial,
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(_isEditing ? 'Update Material' : 'Add Material'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCostPreview() {
    final costPerUnit = double.tryParse(_costPerUnitController.text) ?? 0;
    final quantityOrdered = double.tryParse(_quantityOrderedController.text) ?? 0;
    final totalCost = costPerUnit * quantityOrdered;

    return Container(
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
                'Cost Preview',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Total Cost: \$${totalCost.toStringAsFixed(2)}',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            '(${quantityOrdered.toStringAsFixed(1)} ${_unitController.text} × \$${costPerUnit.toStringAsFixed(2)})',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }
}
