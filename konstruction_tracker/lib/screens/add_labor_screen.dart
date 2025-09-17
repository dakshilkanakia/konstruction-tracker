import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../models/labor.dart';
import '../models/project.dart';
import '../services/firestore_service.dart';

class AddLaborScreen extends StatefulWidget {
  final Project project;
  final Labor? labor; // For editing existing labor

  const AddLaborScreen({
    super.key,
    required this.project,
    this.labor,
  });

  @override
  State<AddLaborScreen> createState() => _AddLaborScreenState();
}

class _AddLaborScreenState extends State<AddLaborScreen> {
  final _formKey = GlobalKey<FormState>();
  final _workCategoryController = TextEditingController();
  final _ratePerSqFtController = TextEditingController();
  final _workAreaController = TextEditingController();
  final _fixedHourlyRateController = TextEditingController();
  final _totalHoursController = TextEditingController();
  final _subcontractorController = TextEditingController();
  final _numberOfWorkersController = TextEditingController();
  final _descriptionController = TextEditingController();
  
  bool _isLoading = false;
  LaborType _laborType = LaborType.contracted;
  DateTime _workDate = DateTime.now();
  
  bool get _isEditing => widget.labor != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      _populateFields();
    }
  }

  void _populateFields() {
    final labor = widget.labor!;
    _workCategoryController.text = labor.workCategory;
    _ratePerSqFtController.text = labor.ratePerSqFt?.toString() ?? '';
    _workAreaController.text = labor.workAreaSqFt?.toString() ?? '';
    _fixedHourlyRateController.text = labor.fixedHourlyRate?.toString() ?? '';
    _totalHoursController.text = labor.totalHours.toString();
    _subcontractorController.text = labor.subcontractorCompany;
    _numberOfWorkersController.text = labor.numberOfWorkers.toString();
    _descriptionController.text = labor.description;
    _laborType = labor.type;
    _workDate = labor.workDate;
  }

  @override
  void dispose() {
    _workCategoryController.dispose();
    _ratePerSqFtController.dispose();
    _workAreaController.dispose();
    _fixedHourlyRateController.dispose();
    _totalHoursController.dispose();
    _subcontractorController.dispose();
    _numberOfWorkersController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _selectWorkDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _workDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null && picked != _workDate) {
      setState(() => _workDate = picked);
    }
  }

  Future<void> _saveLabor() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final firestoreService = Provider.of<FirestoreService>(context, listen: false);
      
      // Parse values
      final workCategory = _workCategoryController.text.trim();
      final subcontractorCompany = _subcontractorController.text.trim();
      final numberOfWorkers = int.parse(_numberOfWorkersController.text);
      final totalHours = double.parse(_totalHoursController.text);
      final description = _descriptionController.text.trim();

      Labor labor;

      if (_laborType == LaborType.contracted) {
        // Contracted work
        final ratePerSqFt = double.parse(_ratePerSqFtController.text);
        final workAreaSqFt = double.parse(_workAreaController.text);
        
        labor = Labor(
          id: _isEditing ? widget.labor!.id : const Uuid().v4(),
          projectId: widget.project.id,
          type: _laborType,
          description: description,
          hoursWorked: totalHours, // Keep for backward compatibility
          costPerHour: ratePerSqFt, // Keep for backward compatibility
          workerName: subcontractorCompany, // Keep for backward compatibility
          workDate: _workDate,
          createdAt: _isEditing ? widget.labor!.createdAt : DateTime.now(),
          updatedAt: DateTime.now(),
          workCategory: workCategory,
          ratePerSqFt: ratePerSqFt,
          workAreaSqFt: workAreaSqFt,
          subcontractorCompany: subcontractorCompany,
          numberOfWorkers: numberOfWorkers,
          totalHours: totalHours,
        );
      } else {
        // Non-contracted work
        final fixedHourlyRate = double.parse(_fixedHourlyRateController.text);
        
        labor = Labor(
          id: _isEditing ? widget.labor!.id : const Uuid().v4(),
          projectId: widget.project.id,
          type: _laborType,
          description: description,
          hoursWorked: totalHours, // Keep for backward compatibility
          costPerHour: fixedHourlyRate, // Keep for backward compatibility
          workerName: subcontractorCompany, // Keep for backward compatibility
          workDate: _workDate,
          createdAt: _isEditing ? widget.labor!.createdAt : DateTime.now(),
          updatedAt: DateTime.now(),
          workCategory: workCategory,
          fixedHourlyRate: fixedHourlyRate,
          subcontractorCompany: subcontractorCompany,
          numberOfWorkers: numberOfWorkers,
          totalHours: totalHours,
        );
      }

      final success = _isEditing
          ? await firestoreService.updateLabor(labor)
          : await firestoreService.createLabor(labor);

      setState(() => _isLoading = false);

      if (success && mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isEditing 
                ? 'Labor entry updated successfully' 
                : 'Labor entry added successfully'),
            backgroundColor: Colors.green,
          ),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isEditing 
                ? 'Failed to update labor entry' 
                : 'Failed to add labor entry'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Labor Entry' : 'Add Labor Entry'),
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

            // Labor Type Selection
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Labor Type *',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _buildTypeOption(
                            'Contracted Work',
                            Icons.business_center,
                            LaborType.contracted,
                            Colors.blue,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildTypeOption(
                            'Non-Contracted Work',
                            Icons.person,
                            LaborType.nonContracted,
                            const Color(0xFFFFD700),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Work Category
            TextFormField(
              controller: _workCategoryController,
              decoration: const InputDecoration(
                labelText: 'Work Category *',
                hintText: 'e.g., Sidewalk, Heavy Duty Pavement, Excavation',
                border: OutlineInputBorder(),
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

            // Work Date
            Card(
              child: ListTile(
                leading: const Icon(Icons.calendar_today),
                title: const Text('Work Date'),
                subtitle: Text(
                  '${_workDate.day}/${_workDate.month}/${_workDate.year}',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: _selectWorkDate,
              ),
            ),
            const SizedBox(height: 16),

            // Contracted Work Fields
            if (_laborType == LaborType.contracted) ...[
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _ratePerSqFtController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
                      ],
                      decoration: const InputDecoration(
                        labelText: 'Rate per Sq Ft *',
                        hintText: 'e.g., 15.50',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.attach_money),
                        prefixText: '\$',
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter rate per sq ft';
                        }
                        final rate = double.tryParse(value);
                        if (rate == null || rate <= 0) {
                          return 'Please enter a valid rate';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _workAreaController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
                      ],
                      decoration: const InputDecoration(
                        labelText: 'Work Area (Sq Ft) *',
                        hintText: 'e.g., 100.0',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.square_foot),
                        suffixText: 'sq ft',
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter work area';
                        }
                        final area = double.tryParse(value);
                        if (area == null || area <= 0) {
                          return 'Please enter a valid area';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],

            // Non-Contracted Work Fields
            if (_laborType == LaborType.nonContracted) ...[
              TextFormField(
                controller: _fixedHourlyRateController,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
                ],
                decoration: const InputDecoration(
                  labelText: 'Fixed Hourly Rate *',
                  hintText: 'e.g., 35.00',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.attach_money),
                  prefixText: '\$',
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter fixed hourly rate';
                  }
                  final rate = double.tryParse(value);
                  if (rate == null || rate <= 0) {
                    return 'Please enter a valid rate';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
            ],

            // Total Hours
            TextFormField(
              controller: _totalHoursController,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
              ],
              decoration: const InputDecoration(
                labelText: 'Total Hours *',
                hintText: 'e.g., 8.5',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.schedule),
                suffixText: 'hours',
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter total hours';
                }
                final hours = double.tryParse(value);
                if (hours == null || hours <= 0) {
                  return 'Please enter a valid number of hours';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Subcontractor Company
            TextFormField(
              controller: _subcontractorController,
              decoration: const InputDecoration(
                labelText: 'Subcontractor Company *',
                hintText: 'e.g., ABC Construction Co.',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.business),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter subcontractor company name';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Number of Workers
            TextFormField(
              controller: _numberOfWorkersController,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
              ],
              decoration: const InputDecoration(
                labelText: 'Number of Workers *',
                hintText: 'e.g., 3',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.people),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter number of workers';
                }
                final workers = int.tryParse(value);
                if (workers == null || workers <= 0) {
                  return 'Please enter a valid number of workers';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Description
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description (Optional)',
                hintText: 'e.g., Concrete pouring, Framing work, etc.',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.description),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 24),

            // Cost Preview
            _buildCostPreview(),
            const SizedBox(height: 24),

            // Save Button
            ElevatedButton(
              onPressed: _isLoading ? null : _saveLabor,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(_isEditing ? 'Update Labor Entry' : 'Add Labor Entry'),
            ),
            const SizedBox(height: 16),

            // Info Text
            Text(
              '* Required fields\n\nFor contracted work, cost is calculated as: Rate per Sq Ft × Work Area\nFor non-contracted work, cost is calculated as: Fixed Rate × Total Hours',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeOption(String title, IconData icon, LaborType type, Color color) {
    final isSelected = _laborType == type;
    
    return InkWell(
      onTap: () => setState(() => _laborType = type),
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
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCostPreview() {
    double totalCost = 0.0;
    String calculationText = '';

    if (_laborType == LaborType.contracted) {
      final ratePerSqFt = double.tryParse(_ratePerSqFtController.text) ?? 0;
      final workArea = double.tryParse(_workAreaController.text) ?? 0;
      totalCost = ratePerSqFt * workArea;
      calculationText = 'Rate per Sq Ft × Work Area = \$${ratePerSqFt.toStringAsFixed(2)} × ${workArea.toStringAsFixed(1)} sq ft';
    } else {
      final fixedRate = double.tryParse(_fixedHourlyRateController.text) ?? 0;
      final totalHours = double.tryParse(_totalHoursController.text) ?? 0;
      totalCost = fixedRate * totalHours;
      calculationText = 'Fixed Rate × Total Hours = \$${fixedRate.toStringAsFixed(2)} × ${totalHours.toStringAsFixed(1)} hours';
    }

    if (totalCost <= 0) return const SizedBox.shrink();

    return Card(
      color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
      child: Padding(
        padding: const EdgeInsets.all(16),
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
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              calculationText,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
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
        title: const Text('Delete Labor Entry'),
        content: const Text('Are you sure you want to delete this labor entry?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              setState(() => _isLoading = true);
              try {
                final firestoreService = Provider.of<FirestoreService>(context, listen: false);
                final success = await firestoreService.deleteLabor(widget.labor!.id);
                if (mounted) {
                  if (success) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Labor entry deleted successfully'),
                        backgroundColor: Colors.green,
                      ),
                    );
                    Navigator.pop(context, true);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Failed to delete labor entry'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error: ${e.toString()}'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              } finally {
                if (mounted) {
                  setState(() => _isLoading = false);
                }
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}