import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';
import '../models/labor.dart';
import '../models/project.dart';
import '../services/firestore_service.dart';

class AddProgressScreen extends StatefulWidget {
  final Project project;
  final Labor contract; // The contract this progress belongs to
  final Labor? progress; // For editing existing progress entries

  const AddProgressScreen({
    super.key,
    required this.project,
    required this.contract,
    this.progress,
  });

  @override
  State<AddProgressScreen> createState() => _AddProgressScreenState();
}

class _AddProgressScreenState extends State<AddProgressScreen> {
  final _formKey = GlobalKey<FormState>();
  final _completedSqFtController = TextEditingController();
  final _concretePouredController = TextEditingController();
  final _locationController = TextEditingController();
  final _subcontractorController = TextEditingController();

  bool _isLoading = false;
  DateTime _workDate = DateTime.now();
  bool get _isEditing => widget.progress != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      _populateFields();
    }
  }

  void _populateFields() {
    final progress = widget.progress!;
    _completedSqFtController.text = progress.completedSqFt?.toString() ?? '';
    _concretePouredController.text = progress.concretePoured?.toString() ?? '';
    _locationController.text = progress.location ?? '';
    _subcontractorController.text = progress.subcontractorCompany ?? '';
    _workDate = progress.workDate ?? DateTime.now();
  }

  @override
  void dispose() {
    _completedSqFtController.dispose();
    _concretePouredController.dispose();
    _locationController.dispose();
    _subcontractorController.dispose();
    super.dispose();
  }

  Future<void> _saveProgress() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final firestoreService = Provider.of<FirestoreService>(context, listen: false);
      
      final completedSqFt = double.tryParse(_completedSqFtController.text) ?? 0.0;
      final concretePoured = double.tryParse(_concretePouredController.text);
      final location = _locationController.text.trim().isEmpty ? null : _locationController.text.trim();

      final progress = Labor(
        id: _isEditing ? widget.progress!.id : const Uuid().v4(),
        projectId: widget.project.id,
        type: LaborType.contracted,
        entryType: LaborEntryType.progress,
        workCategory: widget.contract.workCategory, // Same as contract
        contractId: widget.contract.id, // Link to contract
        completedSqFt: completedSqFt,
        concretePoured: concretePoured,
        ratePerSqFt: widget.contract.ratePerSqFt, // Copy from contract for cost calculation
        workDate: _workDate,
        location: location,
        subcontractorCompany: _subcontractorController.text.trim().isEmpty 
            ? null 
            : _subcontractorController.text.trim(),
        createdAt: _isEditing ? widget.progress!.createdAt : DateTime.now(),
        updatedAt: DateTime.now(),
      );

      bool success;
      if (_isEditing) {
        success = await firestoreService.updateLabor(progress);
      } else {
        success = await firestoreService.createLabor(progress);
      }

      if (mounted) {
        setState(() => _isLoading = false);
        
        if (success) {
          // Sync progress to matching component
          await firestoreService.syncLaborProgressToComponent(
            widget.project.id,
            widget.contract.workCategory,
          );
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(_isEditing 
                ? 'Progress updated successfully' 
                : 'Progress recorded successfully'),
            ),
          );
          Navigator.pop(context, true);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to save progress')),
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
    final completedSqFt = double.tryParse(_completedSqFtController.text) ?? 0.0;
    final concretePoured = double.tryParse(_concretePouredController.text);
    final ratePerSqFt = widget.contract.ratePerSqFt ?? 0.0;
    final progressCost = completedSqFt * ratePerSqFt;

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Progress' : 'Record Progress'),
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
              // Contract info header
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
                          'Progress Entry',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Contract: ${widget.contract.workCategory}',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      'Rate: \$${ratePerSqFt.toStringAsFixed(2)} / sq ft',
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

              // Square Feet Completed
              TextFormField(
                controller: _completedSqFtController,
                decoration: const InputDecoration(
                  labelText: 'Square Feet Completed',
                  hintText: 'e.g., 150',
                  prefixIcon: Icon(Icons.straighten),
                  suffixText: 'sq ft',
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                ],
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter square feet completed';
                  }
                  final sqFt = double.tryParse(value);
                  if (sqFt == null || sqFt <= 0) {
                    return 'Please enter a valid square footage';
                  }
                  // Optional: Check against remaining work
                  final totalSqFt = widget.contract.totalSqFt ?? 0.0;
                  if (sqFt > totalSqFt) {
                    return 'Cannot exceed total contract sq ft (${totalSqFt.toStringAsFixed(1)})';
                  }
                  return null;
                },
                onChanged: (value) => setState(() {}), // Trigger rebuild for cost preview
              ),
              const SizedBox(height: 16),

              // Concrete Poured (Optional)
              TextFormField(
                controller: _concretePouredController,
                decoration: const InputDecoration(
                  labelText: 'Concrete Poured (Optional)',
                  hintText: 'e.g., 5.5',
                  prefixIcon: Icon(Icons.construction),
                  suffixText: 'cu yd',
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                ],
                validator: (value) {
                  if (value != null && value.trim().isNotEmpty) {
                    final concrete = double.tryParse(value);
                    if (concrete == null || concrete < 0) {
                      return 'Please enter a valid concrete amount';
                    }
                  }
                  return null;
                },
                onChanged: (value) => setState(() {}), // Trigger rebuild for preview
              ),
              
              // Concrete overpour warning (if contract has total concrete)
              if (widget.contract.totalConcrete != null && widget.contract.totalConcrete! > 0)
                Container(
                  margin: const EdgeInsets.only(top: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.orange, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Concrete poured can exceed total concrete (${widget.contract.totalConcrete!.toStringAsFixed(1)} cu yd) if needed.',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.orange.shade700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 16),

              // Location (Optional)
              TextFormField(
                controller: _locationController,
                decoration: const InputDecoration(
                  labelText: 'Location (Optional)',
                  hintText: 'e.g., North side, Building A, etc.',
                  prefixIcon: Icon(Icons.location_on),
                ),
              ),
              const SizedBox(height: 16),

              // Subcontractor Company (Optional)
              TextFormField(
                controller: _subcontractorController,
                decoration: const InputDecoration(
                  labelText: 'Subcontractor Company (Optional)',
                  hintText: 'e.g., ABC Construction',
                  prefixIcon: Icon(Icons.business),
                ),
              ),
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
                      _buildSummaryRow('Completed:', '${completedSqFt.toStringAsFixed(1)} sq ft'),
                      if (concretePoured != null)
                        _buildSummaryRow('Concrete Poured:', '${concretePoured.toStringAsFixed(1)} cu yd'),
                      _buildSummaryRow('Rate:', '\$${ratePerSqFt.toStringAsFixed(2)} / sq ft'),
                      const Divider(),
                      _buildSummaryRow(
                        'Progress Cost:', 
                        '\$${progressCost.toStringAsFixed(2)}',
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
                  onPressed: _isLoading ? null : _saveProgress,
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
        title: const Text('Delete Progress Entry'),
        content: const Text('Are you sure you want to delete this progress entry?'),
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
      await _deleteProgress();
    }
  }

  Future<void> _deleteProgress() async {
    setState(() => _isLoading = true);

    try {
      final firestoreService = Provider.of<FirestoreService>(context, listen: false);
      final success = await firestoreService.deleteLabor(widget.progress!.id);

      if (mounted) {
        setState(() => _isLoading = false);
        
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Progress entry deleted successfully')),
          );
          Navigator.pop(context, true);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to delete progress entry')),
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
