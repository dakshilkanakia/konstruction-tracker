import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/labor.dart';
import '../models/project.dart';
import '../services/firestore_service.dart';
import '../screens/add_contract_screen.dart';
import '../screens/add_progress_screen.dart';
import '../screens/add_work_setup_screen.dart';
import '../screens/add_work_progress_screen.dart';

class LaborSection extends StatefulWidget {
  final Project project;
  final VoidCallback onRefresh;

  const LaborSection({
    super.key,
    required this.project,
    required this.onRefresh,
  });

  @override
  State<LaborSection> createState() => _LaborSectionState();
}

class _LaborSectionState extends State<LaborSection> {
  List<Labor> _labor = [];
  List<Labor> _contracts = [];
  List<Labor> _workSetups = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadLabor();
  }

  Future<void> _loadLabor() async {
    setState(() => _isLoading = true);
    try {
      final firestoreService = Provider.of<FirestoreService>(context, listen: false);
      final labor = await firestoreService.getProjectLabor(widget.project.id);
      
      setState(() {
        _labor = labor;
        // Separate contracts and work setups
        _contracts = labor.where((l) => l.isContracted && l.isContract).toList();
        _workSetups = labor.where((l) => l.isWorkSetup).toList();
        _isLoading = false;
        
        // Debug prints
        print('📱 LABOR WIDGET: Loaded ${labor.length} total labor entries for project ${widget.project.id}');
        print('📱 LABOR WIDGET: Found ${_contracts.length} contracts, ${_workSetups.length} work setups');
        
        // Debug each labor entry
        for (var entry in labor) {
          print('📱 LABOR WIDGET: Entry - Category: ${entry.workCategory}, Type: ${entry.typeString}, EntryType: ${entry.entryTypeString}, isWorkSetup: ${entry.isWorkSetup}, isWorkProgress: ${entry.isWorkProgress}');
        }
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading labor: $e')),
        );
      }
    }
  }

  Future<void> _addContract() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => AddContractScreen(project: widget.project),
      ),
    );
    
    if (result == true) {
      _loadLabor();
      widget.onRefresh(); // Notify parent to refresh
    }
  }

  Future<void> _addProgress(Labor contract) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => AddProgressScreen(
          project: widget.project,
          contract: contract,
        ),
      ),
    );
    
    if (result == true) {
      _loadLabor();
      widget.onRefresh(); // Notify parent to refresh
    }
  }

  Future<void> _addWorkSetup() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => AddWorkSetupScreen(project: widget.project),
      ),
    );
    
    if (result == true) {
      _loadLabor();
      widget.onRefresh(); // Notify parent to refresh
    }
  }

  Future<void> _addWorkProgress(Labor workSetup) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => AddWorkProgressScreen(
          project: widget.project,
          workSetup: workSetup,
        ),
      ),
    );
    
    if (result == true) {
      _loadLabor();
      widget.onRefresh(); // Notify parent to refresh
    }
  }



  Future<void> _deleteLabor(Labor labor) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Labor Entry'),
        content: Text('Are you sure you want to delete this labor entry?'),
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
      try {
        final firestoreService = Provider.of<FirestoreService>(context, listen: false);
        await firestoreService.deleteLabor(labor.id);
        
        // Sync component after labor deletion
        await firestoreService.syncLaborProgressToComponent(
          widget.project.id,
          labor.workCategory,
        );
        
        // If this is a work progress entry, sync work setup remaining values
        if (labor.isWorkProgress && labor.workSetupId != null) {
          await firestoreService.syncWorkSetupRemainingValues(
            widget.project.id,
            labor.workSetupId!,
          );
        }
        
        _loadLabor();
        widget.onRefresh(); // Notify parent to refresh
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Labor entry deleted successfully')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error deleting labor entry: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_labor.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.work_outline,
              size: 64,
              color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'No Labor Entries Added',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Start by creating a contract or adding non-contracted work',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  onPressed: _addContract,
                  icon: const Icon(Icons.assignment),
                  label: const Text('Add Contract'),
                ),
                const SizedBox(width: 16),
                ElevatedButton.icon(
                  onPressed: _addWorkSetup,
                  icon: const Icon(Icons.work_history),
                  label: const Text('Add Work Setup'),
                ),
              ],
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header with stats and action buttons
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Icon(
                    Icons.work,
                    color: Theme.of(context).colorScheme.primary,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Labor Tracking',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                        Text(
                          '${_contracts.length} contracts • ${_workSetups.length} work setups • \$${_getTotalCost().toStringAsFixed(2)} total',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: () {
                      print('🔄 LABOR WIDGET: Manual refresh triggered');
                      _loadLabor();
                    },
                    icon: const Icon(Icons.refresh, size: 16),
                    label: const Text('Refresh'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.secondary,
                      foregroundColor: Theme.of(context).colorScheme.onSecondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _addContract,
                      icon: const Icon(Icons.assignment),
                      label: const Text('Add Contract'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _addWorkSetup,
                      icon: const Icon(Icons.work_history),
                      label: const Text('Add Work Setup'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        
        // Content
        Expanded(
          child: RefreshIndicator(
            onRefresh: _loadLabor,
            child: ListView(
              padding: const EdgeInsets.only(bottom: 16),
              children: [
                // Contracts Section
                if (_contracts.isNotEmpty) ...[
                  _buildSectionHeader('Contracts', _contracts.length, _getContractedCost()),
                  const SizedBox(height: 8),
                  ..._contracts.map((contract) => _buildContractCard(contract)),
                  const SizedBox(height: 16),
                ],

                // Work Setups Section
                if (_workSetups.isNotEmpty) ...[
                  _buildSectionHeader('Work Setups', _workSetups.length, _getWorkSetupCost()),
                  const SizedBox(height: 8),
                  ..._workSetups.map((workSetup) => _buildWorkSetupCard(workSetup)),
                  const SizedBox(height: 16),
                ],

              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildContractCard(Labor contract) {
    // Get all progress entries for this contract and sort by work date
    final progressEntries = _labor
        .where((l) => l.contractId == contract.id && l.isProgress)
        .toList()
        ..sort((a, b) {
          // Sort by work date (ascending), fallback to creation date if no work date
          final aDate = a.workDate ?? a.createdAt;
          final bDate = b.workDate ?? b.createdAt;
          return aDate.compareTo(bDate);
        });
    
    final totalSqFt = contract.totalSqFt ?? 0.0;
    final completedSqFt = Labor.calculateTotalCompleted(progressEntries);
    final progressPercentage = Labor.calculateProgressPercentage(totalSqFt, completedSqFt);
    final remainingSqFt = totalSqFt - completedSqFt;
    final totalBudget = contract.totalValue;
    final completedBudget = progressEntries.fold(0.0, (sum, entry) => sum + entry.totalCost);
    final remainingBudget = Labor.calculateRemainingBudget(totalBudget, completedBudget);
    
    // Concrete progress calculations
    final totalConcrete = contract.totalConcrete;
    final concretePoured = Labor.calculateTotalConcretePoured(progressEntries);
    final initialConcretePoured = contract.initialConcretePoured ?? 0.0;
    final totalConcretePoured = concretePoured + initialConcretePoured;
    final concreteProgressPercentage = totalConcrete != null 
        ? Labor.calculateConcreteProgressPercentage(totalConcrete, totalConcretePoured)
        : 0.0;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Contract header
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        contract.workCategory,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '\$${contract.ratePerSqFt?.toStringAsFixed(2) ?? '0.00'} / sq ft • ${totalSqFt.toStringAsFixed(0)} sq ft total',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (value) {
                    switch (value) {
                      case 'edit':
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => AddContractScreen(
                              project: widget.project,
                              contract: contract,
                            ),
                          ),
                        ).then((result) {
                          if (result == true) {
                            _loadLabor();
                            widget.onRefresh();
                          }
                        });
                        break;
                      case 'delete':
                        _deleteLabor(contract);
                        break;
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit, size: 20),
                          SizedBox(width: 8),
                          Text('Edit Contract'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete, size: 20, color: Colors.red),
                          SizedBox(width: 8),
                          Text('Delete Contract'),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Progress bar
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Progress: ${progressPercentage.toStringAsFixed(1)}%',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      '${completedSqFt.toStringAsFixed(0)} / ${totalSqFt.toStringAsFixed(0)} sq ft',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                LinearProgressIndicator(
                  value: progressPercentage / 100,
                  backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    progressPercentage >= 100
                        ? Colors.green
                        : const Color(0xFF9C27B0), // Purple for contract progress
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Concrete progress (if total concrete is set)
            if (totalConcrete != null) ...[
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Concrete: ${concreteProgressPercentage.toStringAsFixed(1)}%',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        '${totalConcretePoured.toStringAsFixed(1)} / ${totalConcrete.toStringAsFixed(1)} cu yd',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  LinearProgressIndicator(
                    value: (concreteProgressPercentage / 100).clamp(0.0, 1.0),
                    backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      concreteProgressPercentage >= 100
                          ? Colors.orange // Orange for concrete overpour
                          : const Color(0xFFFF9800), // Orange for concrete progress
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
            ],

            // Budget info
            Row(
              children: [
                Expanded(
                  child: _buildInfoItem(
                    'Completed Budget',
                    '\$${completedBudget.toStringAsFixed(2)}',
                    Icons.monetization_on,
                    Colors.orange,
                  ),
                ),
                Expanded(
                  child: _buildInfoItem(
                    'Remaining Budget',
                    '\$${remainingBudget.toStringAsFixed(2)}',
                    Icons.account_balance_wallet,
                    Colors.green,
                  ),
                ),
                Expanded(
                  child: _buildInfoItem(
                    'Remaining Work',
                    '${remainingSqFt.toStringAsFixed(0)} sq ft',
                    Icons.straighten,
                    Theme.of(context).colorScheme.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Action buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _addProgress(contract),
                    icon: const Icon(Icons.add),
                    label: const Text('Add Progress'),
                  ),
                ),
                const SizedBox(width: 12),
                OutlinedButton(
                  onPressed: () => _showProgressHistory(contract, progressEntries),
                  child: Text('${progressEntries.length} Entries'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWorkSetupCard(Labor workSetup) {
    // Get all work progress entries for this work setup and sort by work date
    final workProgressEntries = _labor
        .where((l) => l.workSetupId == workSetup.id && l.isWorkProgress)
        .toList()
        ..sort((a, b) {
          // Sort by work date (ascending), fallback to creation date if no work date
          final aDate = a.workDate ?? a.createdAt;
          final bDate = b.workDate ?? b.createdAt;
          return aDate.compareTo(bDate);
        });
    
    // Detect work setup type (existing component vs custom component)
    final isExistingComponentWorkSetup = workSetup.remainingArea != null && workSetup.remainingBudget != null;
    
    // Calculate values based on work setup type
    final maxHours = isExistingComponentWorkSetup 
        ? null 
        : workSetup.maxHours;
    final workedHours = Labor.calculateTotalHoursWorked(workProgressEntries);
    final progressPercentage = isExistingComponentWorkSetup 
        ? 0.0 // For existing components, we'll calculate based on area progress
        : Labor.calculateWorkProgressPercentage(maxHours ?? 0.0, workedHours);
    final remainingHours = isExistingComponentWorkSetup 
        ? null 
        : (workSetup.remainingHours ?? ((maxHours ?? 0.0) - workedHours));
    
    // Calculate used budget from progress entries
    final usedBudget = workProgressEntries.fold(0.0, (sum, entry) => sum + entry.totalCost);
    
    // For existing component work setups, use the stored remaining values directly
    // For custom component work setups, use the synced remaining budget or calculate from original total budget
    final remainingBudget = isExistingComponentWorkSetup 
        ? (workSetup.remainingBudget ?? 0.0)
        : (workSetup.remainingBudget ?? ((workSetup.totalBudget ?? 0.0) - usedBudget));
    
    // Debug logging for work setup card
    if (kDebugMode) {
      print('🔍 WORK_SETUP_CARD: Building card for work setup ${workSetup.id}');
      print('  Work Setup Type: ${isExistingComponentWorkSetup ? "Existing Component" : "Custom Component"}');
      print('  Work Setup remainingBudget: ${workSetup.remainingBudget}');
      print('  Work Setup remainingHours: ${workSetup.remainingHours}');
      print('  Work Setup totalBudget: ${workSetup.totalBudget}');
      print('  Work Setup maxHours: ${workSetup.maxHours}');
      print('  Calculated usedBudget: $usedBudget');
      print('  Calculated remainingBudget: $remainingBudget');
      print('  Calculated remainingHours: $remainingHours');
      print('  Progress Entries Count: ${workProgressEntries.length}');
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Work setup header
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        workSetup.workCategory,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        isExistingComponentWorkSetup 
                            ? 'Remaining Area: ${workSetup.remainingArea?.toStringAsFixed(1) ?? '0.0'} sq ft • Remaining Budget: \$${workSetup.remainingBudget?.toStringAsFixed(2) ?? '0.00'}'
                            : '\$${workSetup.fixedHourlyRate?.toStringAsFixed(2) ?? '0.00'} / hour • ${maxHours?.toStringAsFixed(0) ?? '0'} max hours',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (value) {
                    switch (value) {
                      case 'edit':
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => AddWorkSetupScreen(
                              project: widget.project,
                              workSetup: workSetup,
                            ),
                          ),
                        ).then((result) {
                          if (result == true) {
                            _loadLabor();
                            widget.onRefresh();
                          }
                        });
                        break;
                      case 'delete':
                        _deleteLabor(workSetup);
                        break;
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit, size: 20),
                          SizedBox(width: 8),
                          Text('Edit Work Setup'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete, size: 20, color: Colors.red),
                          SizedBox(width: 8),
                          Text('Delete Work Setup'),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Progress bar
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      isExistingComponentWorkSetup 
                          ? 'Work Setup Active'
                          : 'Progress: ${progressPercentage.toStringAsFixed(1)}%',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      isExistingComponentWorkSetup 
                          ? '${workProgressEntries.length} progress entries'
                          : '${workedHours.toStringAsFixed(1)} / ${maxHours?.toStringAsFixed(1) ?? '0'} hours',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                if (!isExistingComponentWorkSetup) ...[
                  LinearProgressIndicator(
                    value: progressPercentage / 100,
                    backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      progressPercentage >= 100
                          ? Colors.green
                          : const Color(0xFF3F51B5), // Indigo for work setup progress
                    ),
                  ),
                ] else ...[
                  Container(
                    height: 4,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceVariant,
                      borderRadius: BorderRadius.circular(2),
                    ),
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: const Color(0xFF3F51B5), // Indigo for work setup progress
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 12),

            // Budget info
            Row(
              children: [
                Expanded(
                  child: _buildInfoItem(
                    'Used Budget',
                    '\$${usedBudget.toStringAsFixed(2)}',
                    Icons.monetization_on,
                    Colors.orange,
                  ),
                ),
                Expanded(
                  child: _buildInfoItem(
                    'Remaining Budget',
                    '\$${remainingBudget.toStringAsFixed(2)}',
                    Icons.account_balance_wallet,
                    Colors.green,
                  ),
                ),
                Expanded(
                  child: _buildInfoItem(
                    isExistingComponentWorkSetup 
                        ? 'Remaining Area'
                        : 'Remaining Hours',
                    isExistingComponentWorkSetup 
                        ? '${workSetup.remainingArea?.toStringAsFixed(1) ?? '0.0'} sq ft'
                        : '${remainingHours?.toStringAsFixed(1) ?? '0.0'} hrs',
                    isExistingComponentWorkSetup 
                        ? Icons.square_foot
                        : Icons.schedule,
                    Theme.of(context).colorScheme.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Action buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _addWorkProgress(workSetup),
                    icon: const Icon(Icons.add),
                    label: const Text('Add Progress'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Theme.of(context).colorScheme.onPrimary,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                OutlinedButton(
                  onPressed: () => _showWorkProgressHistory(workSetup, workProgressEntries),
                  child: Text('${workProgressEntries.length} Entries'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(
          icon,
          size: 20,
          color: color,
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Future<void> _showWorkProgressHistory(Labor workSetup, List<Labor> workProgressEntries) async {
    // Sort work progress entries by work date (ascending)
    final sortedEntries = List<Labor>.from(workProgressEntries)
      ..sort((a, b) {
        final aDate = a.workDate ?? a.createdAt;
        final bDate = b.workDate ?? b.createdAt;
        return aDate.compareTo(bDate);
      });
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Work Progress History - ${workSetup.workCategory}'),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: sortedEntries.isEmpty
              ? const Center(child: Text('No progress entries yet'))
              : ListView.builder(
                  itemCount: sortedEntries.length,
                  itemBuilder: (context, index) {
                    final progress = sortedEntries[index];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        child: Text(
                          '${progress.hoursWorked?.toStringAsFixed(0) ?? '0'}h',
                          style: const TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      title: Text(
                        '${progress.hoursWorked?.toStringAsFixed(1) ?? '0.0'} hours • \$${progress.totalCost.toStringAsFixed(2)}',
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            progress.workDate != null 
                                ? 'Date: ${DateFormat('MMM dd, yyyy').format(progress.workDate!)}'
                                : 'Date: Not specified',
                          ),
                          if (progress.location?.isNotEmpty == true)
                            Text('📍 Location: ${progress.location}'),
                          if (progress.subcontractorCompany?.isNotEmpty == true)
                            Text('Company: ${progress.subcontractorCompany}'),
                          if (progress.numberOfWorkers != null)
                            Text('Workers: ${progress.numberOfWorkers}'),
                        ],
                      ),
                      trailing: PopupMenuButton<String>(
                        onSelected: (value) {
                          Navigator.pop(context); // Close dialog first
                          switch (value) {
                            case 'edit':
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => AddWorkProgressScreen(
                                    project: widget.project,
                                    workSetup: workSetup,
                                    workProgress: progress,
                                  ),
                                ),
                              ).then((result) {
                                if (result == true) {
                                  _loadLabor();
                                  widget.onRefresh();
                                }
                              });
                              break;
                            case 'delete':
                              _deleteLabor(progress);
                              break;
                          }
                        },
                        itemBuilder: (context) => [
                          const PopupMenuItem(
                            value: 'edit',
                            child: Row(
                              children: [
                                Icon(Icons.edit, size: 18),
                                SizedBox(width: 8),
                                Text('Edit'),
                              ],
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'delete',
                            child: Row(
                              children: [
                                Icon(Icons.delete, size: 18, color: Colors.red),
                                SizedBox(width: 8),
                                Text('Delete'),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<void> _showProgressHistory(Labor contract, List<Labor> progressEntries) async {
    // Sort progress entries by work date (ascending)
    final sortedEntries = List<Labor>.from(progressEntries)
      ..sort((a, b) {
        final aDate = a.workDate ?? a.createdAt;
        final bDate = b.workDate ?? b.createdAt;
        return aDate.compareTo(bDate);
      });
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${contract.workCategory} - Progress History'),
        content: SizedBox(
          width: double.maxFinite,
          height: 300,
          child: sortedEntries.isEmpty
              ? const Center(child: Text('No progress entries yet'))
              : ListView.builder(
                  itemCount: sortedEntries.length,
                  itemBuilder: (context, index) {
                    final entry = sortedEntries[index];
                    return ListTile(
                      leading: const Icon(Icons.trending_up),
                      title: Text(
                        '${entry.completedSqFt?.toStringAsFixed(1) ?? '0'} sq ft${entry.concretePoured != null ? ' • ${entry.concretePoured!.toStringAsFixed(1)} cu yd' : ''}'
                      ),
                      subtitle: Text(
                        '${entry.workDate?.day}/${entry.workDate?.month}/${entry.workDate?.year} • \$${entry.totalCost.toStringAsFixed(2)}',
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => AddProgressScreen(
                                project: widget.project,
                                contract: contract,
                                progress: entry,
                              ),
                            ),
                          ).then((result) {
                            if (result == true) {
                              _loadLabor();
                              widget.onRefresh();
                            }
                          });
                        },
                      ),
                    );
                  },
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, int count, double cost) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
          Text(
            '$count entries • \$${cost.toStringAsFixed(2)}',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  double _getTotalCost() {
    return _labor.fold(0.0, (sum, labor) => sum + labor.totalValue);
  }

  double _getContractedCost() {
    return _labor
        .where((l) => l.type == LaborType.contracted)
        .fold(0.0, (sum, labor) => sum + labor.totalValue);
  }

  double _getWorkSetupCost() {
    return _workSetups.fold(0.0, (sum, workSetup) => sum + workSetup.totalValue);
  }
}
