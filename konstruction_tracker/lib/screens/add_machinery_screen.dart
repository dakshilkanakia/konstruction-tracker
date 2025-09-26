import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../models/machinery.dart' as models;
import '../services/firestore_service.dart';

class AddMachineryScreen extends StatefulWidget {
  final String projectId;
  final models.Machinery? machinery;

  const AddMachineryScreen({
    super.key,
    required this.projectId,
    this.machinery,
  });

  @override
  State<AddMachineryScreen> createState() => _AddMachineryScreenState();
}

class _AddMachineryScreenState extends State<AddMachineryScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _costController = TextEditingController();
  final _hoursUsedController = TextEditingController();
  final _totalCostController = TextEditingController();
  final _operatorDetailsController = TextEditingController();

  bool _isLoading = false;
  bool _isRental = false;
  bool get _isEditing => widget.machinery != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      _populateFields();
    }
  }

  void _populateFields() {
    final machinery = widget.machinery!;
    _nameController.text = machinery.name ?? '';
    _costController.text = machinery.costPerHour?.toString() ?? '';
    _hoursUsedController.text = machinery.hoursUsed?.toString() ?? '';
    _totalCostController.text = machinery.totalCostOverride?.toString() ?? '';
    _operatorDetailsController.text = machinery.operatorName ?? '';
    _isRental = machinery.type == models.MachineryType.rental;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _costController.dispose();
    _hoursUsedController.dispose();
    _totalCostController.dispose();
    _operatorDetailsController.dispose();
    super.dispose();
  }

  Future<void> _saveMachinery() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final firestoreService = Provider.of<FirestoreService>(context, listen: false);
      
      // Parse values only if they're not empty
      final cost = _costController.text.trim().isEmpty 
          ? null 
          : double.tryParse(_costController.text);
      final hoursUsed = _hoursUsedController.text.trim().isEmpty 
          ? null 
          : double.tryParse(_hoursUsedController.text);
      final totalCostOverride = _totalCostController.text.trim().isEmpty 
          ? null 
          : double.tryParse(_totalCostController.text);

      final machinery = models.Machinery(
        id: _isEditing ? widget.machinery!.id : const Uuid().v4(),
        projectId: widget.projectId,
        name: _nameController.text.trim().isEmpty ? null : _nameController.text.trim(),
        type: _isRental ? models.MachineryType.rental : models.MachineryType.owned,
        costPerHour: cost,
        hoursUsed: hoursUsed,
        totalCostOverride: totalCostOverride,
        operatorName: _operatorDetailsController.text.trim().isEmpty ? null : _operatorDetailsController.text.trim(),
        createdAt: _isEditing ? widget.machinery!.createdAt : DateTime.now(),
        updatedAt: DateTime.now(),
      );

      if (_isEditing) {
        await firestoreService.updateMachinery(machinery);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Machinery updated successfully')),
          );
        }
      } else {
        await firestoreService.createMachinery(machinery);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Machinery added successfully')),
          );
        }
      }

      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving machinery: $e')),
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
        title: const Text('Delete Machinery'),
        content: Text('Are you sure you want to delete "${widget.machinery!.name}"?'),
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
        await firestoreService.deleteMachinery(widget.machinery!.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Machinery deleted successfully')),
          );
          Navigator.pop(context, true);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error deleting machinery: $e')),
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
        title: Text(_isEditing ? 'Edit Machinery' : 'Add Machinery'),
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
              // Machinery name
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Machinery Name',
                  hintText: 'e.g., Excavator, Crane, Concrete Mixer',
                  prefixIcon: Icon(Icons.local_shipping),
                ),
                validator: (value) {
                  // Machinery name is optional
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Rental/Owned toggle
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Machinery Type',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _buildTypeOption(
                            'Owned',
                            Icons.business,
                            false,
                            Theme.of(context).colorScheme.primary,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildTypeOption(
                            'Rental',
                            Icons.schedule,
                            true,
                            Colors.orange,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Cost per hour
              TextFormField(
                controller: _costController,
                decoration: const InputDecoration(
                  labelText: 'Cost per Hour (Optional)',
                  hintText: 'e.g., 50.00',
                  prefixIcon: Icon(Icons.attach_money),
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                ],
                validator: (value) {
                  // Cost per hour is optional, but if provided, must be valid
                  if (value != null && value.trim().isNotEmpty) {
                    final cost = double.tryParse(value);
                    if (cost == null || cost < 0) {
                      return 'Please enter a valid cost per hour';
                    }
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Hours used
              TextFormField(
                controller: _hoursUsedController,
                decoration: const InputDecoration(
                  labelText: 'Hours Used',
                  hintText: 'e.g., 8.5',
                  prefixIcon: Icon(Icons.schedule),
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                ],
                validator: (value) {
                  // Hours are optional, but if provided, must be valid
                  if (value != null && value.trim().isNotEmpty) {
                    final hours = double.tryParse(value);
                    if (hours == null || hours < 0) {
                      return 'Please enter a valid number of hours';
                    }
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Total cost override
              TextFormField(
                controller: _totalCostController,
                decoration: const InputDecoration(
                  labelText: 'Total Cost (Optional)',
                  hintText: 'e.g., 2500.00 - Use this if you want to specify total cost directly',
                  prefixIcon: Icon(Icons.monetization_on),
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
              ),
              const SizedBox(height: 16),

              // Operator details
              TextFormField(
                controller: _operatorDetailsController,
                decoration: const InputDecoration(
                  labelText: 'Operator Details (Optional)',
                  hintText: 'e.g., John Smith, License #12345',
                  prefixIcon: Icon(Icons.person),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 24),

              // Cost preview
              _buildCostPreview(),

              const SizedBox(height: 24),

              // Save button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveMachinery,
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(_isEditing ? 'Update Machinery' : 'Add Machinery'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTypeOption(String title, IconData icon, bool isRental, Color color) {
    final isSelected = _isRental == isRental;
    
    return InkWell(
      onTap: () => setState(() => _isRental = isRental),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected 
              ? color.withOpacity(0.1)
              : Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected 
                ? color.withOpacity(0.5)
                : Theme.of(context).colorScheme.outline.withOpacity(0.3),
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected ? color : Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              size: 24,
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? color : Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCostPreview() {
    final costPerHour = double.tryParse(_costController.text);
    final hoursUsed = double.tryParse(_hoursUsedController.text);
    final totalCostOverride = double.tryParse(_totalCostController.text);
    
    // Calculate total cost based on the logic
    double? calculatedTotal;
    String calculationMethod = '';
    
    if (costPerHour != null && hoursUsed != null) {
      calculatedTotal = costPerHour * hoursUsed;
      calculationMethod = 'Calculated: $costPerHour × $hoursUsed hours';
    } else if (totalCostOverride != null) {
      calculatedTotal = totalCostOverride;
      calculationMethod = 'Direct total cost';
    }
    
    // Don't show preview if no cost information is available
    if (calculatedTotal == null || calculatedTotal == 0) {
      return const SizedBox.shrink();
    }

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
            'Total Cost: \$${calculatedTotal.toStringAsFixed(2)}',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            calculationMethod,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }
}
