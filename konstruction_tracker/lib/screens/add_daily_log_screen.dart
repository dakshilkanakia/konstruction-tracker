import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../models/daily_log.dart' as models;
import '../services/firestore_service.dart';

class AddDailyLogScreen extends StatefulWidget {
  final String projectId;
  final models.DailyLog? dailyLog;

  const AddDailyLogScreen({
    super.key,
    required this.projectId,
    this.dailyLog,
  });

  @override
  State<AddDailyLogScreen> createState() => _AddDailyLogScreenState();
}

class _AddDailyLogScreenState extends State<AddDailyLogScreen> {
  final _formKey = GlobalKey<FormState>();
  final _weatherController = TextEditingController();
  final _workCompletedController = TextEditingController();
  final _materialsUsedController = TextEditingController();
  final _issuesConcernsController = TextEditingController();

  DateTime _selectedDate = DateTime.now();
  bool _isLoading = false;
  bool get _isEditing => widget.dailyLog != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      _populateFields();
    }
  }

  void _populateFields() {
    final dailyLog = widget.dailyLog!;
    _selectedDate = dailyLog.date;
    _weatherController.text = dailyLog.weather ?? '';
    _workCompletedController.text = dailyLog.workCompleted ?? '';
    _materialsUsedController.text = dailyLog.materialsUsed ?? '';
    _issuesConcernsController.text = dailyLog.issuesAndConcerns ?? '';
  }

  @override
  void dispose() {
    _weatherController.dispose();
    _workCompletedController.dispose();
    _materialsUsedController.dispose();
    _issuesConcernsController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _saveDailyLog() async {
    setState(() => _isLoading = true);

    try {
      final firestoreService = Provider.of<FirestoreService>(context, listen: false);

      final dailyLog = models.DailyLog(
        id: _isEditing ? widget.dailyLog!.id : const Uuid().v4(),
        projectId: widget.projectId,
        date: _selectedDate,
        weather: _weatherController.text.trim(),
        workCompleted: _workCompletedController.text.trim(),
        materialsUsed: _materialsUsedController.text.trim(),
        issuesAndConcerns: _issuesConcernsController.text.trim(),
        createdAt: _isEditing ? widget.dailyLog!.createdAt : DateTime.now(),
        updatedAt: DateTime.now(),
      );

      bool success = false;
      if (_isEditing) {
        success = await firestoreService.updateDailyLog(dailyLog);
      } else {
        success = await firestoreService.createDailyLog(dailyLog);
      }

      if (mounted) {
        setState(() => _isLoading = false);
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(_isEditing ? 'Daily log updated successfully' : 'Daily log added successfully')),
          );
          Navigator.pop(context, true); // Return true to indicate success
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to save daily log')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving daily log: $e')),
        );
      }
    }
  }

  Future<void> _showDeleteConfirmation() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Daily Log'),
        content: Text('Are you sure you want to delete the log for ${_getFormattedDate()}?'),
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
        await firestoreService.deleteDailyLog(widget.dailyLog!.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Daily log deleted successfully')),
          );
          Navigator.pop(context, true);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error deleting daily log: $e')),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  String _getFormattedDate() {
    return '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Daily Log' : 'Add Daily Log'),
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
              // Date selection
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.calendar_today,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Date',
                            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _getFormattedDate(),
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                        ],
                      ),
                    ),
                    TextButton.icon(
                      onPressed: _selectDate,
                      icon: const Icon(Icons.edit),
                      label: const Text('Change'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Weather conditions
              TextFormField(
                controller: _weatherController,
                decoration: const InputDecoration(
                  labelText: 'Weather Conditions (Optional)',
                  hintText: 'e.g., Sunny, 75°F, Light winds',
                  prefixIcon: Icon(Icons.wb_sunny),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 16),

              // Work completed
              TextFormField(
                controller: _workCompletedController,
                decoration: const InputDecoration(
                  labelText: 'Work Completed (Optional)',
                  hintText: 'e.g., Completed foundation pour, Installed framing',
                  prefixIcon: Icon(Icons.construction),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),

              // Materials used
              TextFormField(
                controller: _materialsUsedController,
                decoration: const InputDecoration(
                  labelText: 'Materials Used (Optional)',
                  hintText: 'e.g., 10 cubic yards concrete, 50 2x4s',
                  prefixIcon: Icon(Icons.inventory_2),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),

              // Issues and concerns
              TextFormField(
                controller: _issuesConcernsController,
                decoration: const InputDecoration(
                  labelText: 'Issues & Concerns (Optional)',
                  hintText: 'e.g., Weather delay, Material shortage, Safety concern',
                  prefixIcon: Icon(Icons.warning),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 24),

              // Info note
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: Theme.of(context).colorScheme.primary,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'All fields are optional. You can add as much or as little detail as needed for each day.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Save button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveDailyLog,
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(_isEditing ? 'Update Daily Log' : 'Add Daily Log'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
