import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';
import '../models/labor.dart';
import '../models/project.dart';
import '../services/firestore_service.dart';

class AddWorkProgressScreen extends StatefulWidget {
  final Project project;
  final Labor workSetup; // The work setup this progress belongs to
  final Labor? workProgress; // For editing existing progress entries

  const AddWorkProgressScreen({
    super.key,
    required this.project,
    required this.workSetup,
    this.workProgress,
  });

  @override
  State<AddWorkProgressScreen> createState() => _AddWorkProgressScreenState();
}

class _AddWorkProgressScreenState extends State<AddWorkProgressScreen> {
  final _formKey = GlobalKey<FormState>();
  final _hoursWorkedController = TextEditingController();
  final _numberOfWorkersController = TextEditingController();
  final _companyController = TextEditingController();
  final _completedAreaController = TextEditingController();
  final _totalHoursController = TextEditingController();
  final _fixedHourlyRateController = TextEditingController();

  bool _isLoading = false;
  DateTime _workDate = DateTime.now();
  bool get _isEditing => widget.workProgress != null;
  bool get _isExistingComponentWorkSetup => widget.workSetup.remainingArea != null && widget.workSetup.remainingBudget != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      _populateFields();
    }
  }

  void _populateFields() {
    final workProgress = widget.workProgress!;
    _hoursWorkedController.text = workProgress.hoursWorked?.toString() ?? '';
    _numberOfWorkersController.text = workProgress.numberOfWorkers?.toString() ?? '';
    _companyController.text = workProgress.subcontractorCompany ?? '';
    _completedAreaController.text = workProgress.completedArea?.toString() ?? '';
    _totalHoursController.text = workProgress.hoursWorked?.toString() ?? '';
    _fixedHourlyRateController.text = workProgress.fixedHourlyRate?.toString() ?? '';
    _workDate = workProgress.workDate ?? DateTime.now();
  }

  @override
  void dispose() {
    _hoursWorkedController.dispose();
    _numberOfWorkersController.dispose();
    _companyController.dispose();
    _completedAreaController.dispose();
    _totalHoursController.dispose();
    _fixedHourlyRateController.dispose();
    super.dispose();
  }

  Future<void> _saveWorkProgress() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final firestoreService = Provider.of<FirestoreService>(context, listen: false);
      
      // Get values based on work setup type
      final hoursWorked = _isExistingComponentWorkSetup 
          ? (double.tryParse(_totalHoursController.text) ?? 0.0)
          : (double.tryParse(_hoursWorkedController.text) ?? 0.0);
      final numberOfWorkers = _isExistingComponentWorkSetup 
          ? null 
          : (int.tryParse(_numberOfWorkersController.text) ?? 1);
      final completedArea = _isExistingComponentWorkSetup 
          ? (double.tryParse(_completedAreaController.text) ?? 0.0)
          : null;
      final fixedHourlyRate = _isExistingComponentWorkSetup 
          ? (double.tryParse(_fixedHourlyRateController.text) ?? 0.0)
          : widget.workSetup.fixedHourlyRate;
      final subcontractorCompany = _isExistingComponentWorkSetup 
          ? null 
          : (_companyController.text.trim().isEmpty ? null : _companyController.text.trim());

      final workProgress = Labor(
        id: _isEditing ? widget.workProgress!.id : const Uuid().v4(),
        projectId: widget.project.id,
        type: LaborType.nonContracted,
        entryType: LaborEntryType.progress, // Work progress entry
        workCategory: widget.workSetup.workCategory, // Same as work setup
        workSetupId: widget.workSetup.id, // Link to work setup
        hoursWorked: hoursWorked,
        fixedHourlyRate: fixedHourlyRate,
        numberOfWorkers: numberOfWorkers,
        completedArea: completedArea,
        workDate: _workDate,
        subcontractorCompany: subcontractorCompany,
        createdAt: _isEditing ? widget.workProgress!.createdAt : DateTime.now(),
        updatedAt: DateTime.now(),
      );

      print('💾 WORK_PROGRESS_SCREEN: Creating work progress with ID: ${workProgress.id}');
      print('💾 WORK_PROGRESS_SCREEN: Progress details - Hours: ${workProgress.hoursWorked}, Workers: ${workProgress.numberOfWorkers}, Cost: \$${workProgress.totalCost}');
      
      bool success;
      if (_isEditing) {
        success = await firestoreService.updateLabor(workProgress);
        print('💾 WORK_PROGRESS_SCREEN: Update result: $success');
      } else {
        success = await firestoreService.createLabor(workProgress);
        print('💾 WORK_PROGRESS_SCREEN: Create result: $success');
      }

      if (mounted) {
        setState(() => _isLoading = false);
        
        if (success) {
          // Sync progress cost to matching component
          await firestoreService.syncLaborProgressToComponent(
            widget.project.id,
            widget.workSetup.workCategory,
            isEdit: _isEditing,
          );
          
          // For existing components, sync work setup remaining values
          if (_isExistingComponentWorkSetup) {
            await firestoreService.syncWorkSetupRemainingValues(
              widget.project.id,
              widget.workSetup.id,
            );
            print('💾 WORK_PROGRESS_SCREEN: Synced work setup remaining values');
          }
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(_isEditing 
                ? 'Work progress updated successfully' 
                : 'Work progress recorded successfully'),
            ),
          );
          Navigator.pop(context, true);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to save work progress')),
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
    // Calculate values based on work setup type
    final hoursWorked = _isExistingComponentWorkSetup 
        ? (double.tryParse(_totalHoursController.text) ?? 0.0)
        : (double.tryParse(_hoursWorkedController.text) ?? 0.0);
    final hourlyRate = _isExistingComponentWorkSetup 
        ? (double.tryParse(_fixedHourlyRateController.text) ?? 0.0)
        : (widget.workSetup.fixedHourlyRate ?? 0.0);
    final progressCost = hoursWorked * hourlyRate;
    
    // For existing components, use remaining values from work setup
    final maxHours = _isExistingComponentWorkSetup 
        ? null 
        : widget.workSetup.maxHours;
    final remainingHours = maxHours != null ? maxHours - hoursWorked : null;
    final totalBudget = _isExistingComponentWorkSetup 
        ? widget.workSetup.remainingBudget ?? 0.0
        : (widget.workSetup.totalBudget ?? 0.0);
    
    // For existing component work setups, calculate remaining budget correctly
    final remainingBudget = _isExistingComponentWorkSetup 
        ? ((widget.workSetup.remainingBudget ?? 0.0) + (widget.workProgress?.totalCost ?? 0.0)) - progressCost
        : totalBudget - progressCost;

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Work Progress' : 'Record Work Progress'),
        actions: [
          if (_isEditing)
            IconButton(
              onPressed: () => _showDeleteDialog(),
              icon: const Icon(Icons.delete),
              tooltip: 'Delete Progress Entry',
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
              // Work setup info header
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
                          Icons.trending_up,
                          color: Theme.of(context).colorScheme.primary,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Work Progress Entry',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Work Setup: ${widget.workSetup.workCategory}',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      _isExistingComponentWorkSetup 
                          ? 'Remaining Area: ${widget.workSetup.remainingArea?.toStringAsFixed(1) ?? '0.0'} sq ft • Remaining Budget: \$${widget.workSetup.remainingBudget?.toStringAsFixed(2) ?? '0.00'}'
                          : 'Budget: \$${totalBudget.toStringAsFixed(2)} • Rate: \$${hourlyRate.toStringAsFixed(2)}/hr • Max Hours: ${maxHours?.toStringAsFixed(1) ?? '0.0'}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Work Date
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.calendar_today),
                title: const Text('Work Date'),
                subtitle: Text(DateFormat('MMM dd, yyyy').format(_workDate)),
                trailing: const Icon(Icons.chevron_right),
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: _workDate,
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now().add(const Duration(days: 30)),
                  );
                  if (date != null) {
                    setState(() => _workDate = date);
                  }
                },
              ),
              const SizedBox(height: 16),

              // Conditional Fields based on work setup type
              if (_isExistingComponentWorkSetup) ...[
                // Completed Area (for existing components)
                TextFormField(
                  controller: _completedAreaController,
                  decoration: const InputDecoration(
                    labelText: 'Completed Area',
                    hintText: 'e.g., 50.0',
                    prefixIcon: Icon(Icons.square_foot),
                    suffixText: 'sq ft',
                  ),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                  ],
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter completed area';
                    }
                    final area = double.tryParse(value);
                    if (area == null || area <= 0) {
                      return 'Please enter valid area';
                    }
                    // Check against remaining area
                    final remainingArea = widget.workSetup.remainingArea ?? 0.0;
                    if (area > remainingArea && !_isEditing) {
                      return 'Cannot exceed remaining area (${remainingArea.toStringAsFixed(1)} sq ft)';
                    }
                    return null;
                  },
                  onChanged: (value) => setState(() {}), // Trigger rebuild for cost preview
                ),
                const SizedBox(height: 16),

                // Total Hours (for existing components)
                TextFormField(
                  controller: _totalHoursController,
                  decoration: const InputDecoration(
                    labelText: 'Total Hours',
                    hintText: 'e.g., 8.5',
                    prefixIcon: Icon(Icons.schedule),
                    suffixText: 'hours',
                  ),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                  ],
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter total hours';
                    }
                    final hours = double.tryParse(value);
                    if (hours == null || hours <= 0) {
                      return 'Please enter valid hours';
                    }
                    return null;
                  },
                  onChanged: (value) => setState(() {}), // Trigger rebuild for cost preview
                ),
                const SizedBox(height: 16),

                // Fixed Hourly Rate (for existing components)
                TextFormField(
                  controller: _fixedHourlyRateController,
                  decoration: const InputDecoration(
                    labelText: 'Fixed Hourly Rate',
                    hintText: 'e.g., 25.00',
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
                      return 'Please enter valid hourly rate';
                    }
                    return null;
                  },
                  onChanged: (value) => setState(() {}), // Trigger rebuild for cost preview
                ),
              ] else ...[
                // Hours Worked (for custom components)
                TextFormField(
                  controller: _hoursWorkedController,
                  decoration: const InputDecoration(
                    labelText: 'Hours Worked',
                    hintText: 'e.g., 8.5',
                    prefixIcon: Icon(Icons.schedule),
                    suffixText: 'hours',
                  ),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                  ],
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter hours worked';
                    }
                    final hours = double.tryParse(value);
                    if (hours == null || hours <= 0) {
                      return 'Please enter valid hours';
                    }
                    // Check against remaining hours
                    if (remainingHours != null && hours > remainingHours && !_isEditing) {
                      return 'Cannot exceed remaining hours (${remainingHours.toStringAsFixed(1)})';
                    }
                    return null;
                  },
                  onChanged: (value) => setState(() {}), // Trigger rebuild for cost preview
                ),
                const SizedBox(height: 16),

                // Number of Workers (for custom components)
                TextFormField(
                  controller: _numberOfWorkersController,
                  decoration: const InputDecoration(
                    labelText: 'Number of Workers',
                    hintText: 'e.g., 3',
                    prefixIcon: Icon(Icons.people),
                    suffixText: 'people',
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                  ],
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter number of workers';
                    }
                    final workers = int.tryParse(value);
                    if (workers == null || workers <= 0) {
                      return 'Please enter valid number of workers';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Company Name (Optional) (for custom components)
                TextFormField(
                  controller: _companyController,
                  decoration: const InputDecoration(
                    labelText: 'Company Name (Optional)',
                    hintText: 'e.g., ABC Construction',
                    prefixIcon: Icon(Icons.business),
                  ),
                ),
              ],
              const SizedBox(height: 24),

              // Progress Cost Preview
              if (progressCost > 0)
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
                            'Progress Summary',
                            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (_isExistingComponentWorkSetup) ...[
                        _buildSummaryRow('Completed Area:', '${_completedAreaController.text} sq ft'),
                        _buildSummaryRow('Total Hours:', '${hoursWorked.toStringAsFixed(1)} hours'),
                        _buildSummaryRow('Hourly Rate:', '\$${hourlyRate.toStringAsFixed(2)} / hour'),
                        _buildSummaryRow('Progress Cost:', '\$${progressCost.toStringAsFixed(2)}'),
                        const Divider(),
                        _buildSummaryRow('Remaining Area:', '${((widget.workSetup.remainingArea ?? 0.0) + (widget.workProgress?.completedArea ?? 0.0)) - (double.tryParse(_completedAreaController.text) ?? 0.0)} sq ft', isHighlight: true),
                        _buildSummaryRow('Remaining Budget:', '\$${remainingBudget.toStringAsFixed(2)}', isHighlight: true),
                      ] else ...[
                        _buildSummaryRow('Hours Worked:', '${hoursWorked.toStringAsFixed(1)} hours'),
                        _buildSummaryRow('Hourly Rate:', '\$${hourlyRate.toStringAsFixed(2)} / hour'),
                        _buildSummaryRow('Progress Cost:', '\$${progressCost.toStringAsFixed(2)}'),
                        const Divider(),
                        _buildSummaryRow('Remaining Hours:', '${remainingHours?.toStringAsFixed(1) ?? '0.0'} hours', isHighlight: true),
                        _buildSummaryRow('Remaining Budget:', '\$${remainingBudget.toStringAsFixed(2)}', isHighlight: true),
                      ],
                    ],
                  ),
                ),
              const SizedBox(height: 32),

              // Save button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveWorkProgress,
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(_isEditing ? 'Update Progress' : 'Record Progress'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, {bool isHighlight = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: isHighlight ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: isHighlight ? Theme.of(context).colorScheme.primary : null,
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
        title: const Text('Delete Work Progress'),
        content: const Text('Are you sure you want to delete this work progress entry?'),
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
      await _deleteWorkProgress();
    }
  }

  Future<void> _deleteWorkProgress() async {
    setState(() => _isLoading = true);

    try {
      final firestoreService = Provider.of<FirestoreService>(context, listen: false);
      final success = await firestoreService.deleteLabor(widget.workProgress!.id);

      if (mounted) {
        setState(() => _isLoading = false);
        
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Work progress deleted successfully')),
          );
          Navigator.pop(context, true);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to delete work progress')),
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
