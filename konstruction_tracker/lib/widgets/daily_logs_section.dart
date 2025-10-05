import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/daily_log.dart' as models;
import '../services/firestore_service.dart';
import '../screens/add_daily_log_screen.dart';
import 'daily_log_card.dart';

class DailyLogsSection extends StatefulWidget {
  final String projectId;

  const DailyLogsSection({
    super.key,
    required this.projectId,
  });

  @override
  State<DailyLogsSection> createState() => _DailyLogsSectionState();
}

class _DailyLogsSectionState extends State<DailyLogsSection> {
  List<models.DailyLog> _dailyLogs = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDailyLogs();
  }

  Future<void> _loadDailyLogs() async {
    setState(() => _isLoading = true);
    try {
      final firestoreService = Provider.of<FirestoreService>(context, listen: false);
      
      // Run test to debug the issue
      await firestoreService.testDailyLogs(widget.projectId);
      
      final dailyLogs = await firestoreService.getProjectDailyLogs(widget.projectId);
      print('📱 DAILY_LOGS: Loaded ${dailyLogs.length} daily logs for project ${widget.projectId}');
      setState(() {
        _dailyLogs = dailyLogs;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      print('❌ DAILY_LOGS: Error loading daily logs: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading daily logs: $e')),
        );
      }
    }
  }

  Future<void> _addDailyLog() async {
    print('📱 DAILY_LOGS: Opening AddDailyLogScreen for project ${widget.projectId}');
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => AddDailyLogScreen(projectId: widget.projectId),
      ),
    );
    
    print('📱 DAILY_LOGS: Received navigation result: $result');
    if (result == true) {
      print('📱 DAILY_LOGS: Refreshing daily logs list');
      _loadDailyLogs();
    }
  }

  Future<void> _editDailyLog(models.DailyLog dailyLog) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => AddDailyLogScreen(
          projectId: widget.projectId,
          dailyLog: dailyLog,
        ),
      ),
    );
    
    if (result == true) {
      _loadDailyLogs();
    }
  }

  Future<void> _deleteDailyLog(models.DailyLog dailyLog) async {
    final dateFormat = DateFormat('MMM dd, yyyy');
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Daily Log'),
        content: Text('Are you sure you want to delete the log for ${dateFormat.format(dailyLog.date)}?'),
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
        await firestoreService.deleteDailyLog(dailyLog.id);
        _loadDailyLogs();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Daily log deleted successfully')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error deleting daily log: $e')),
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

    if (_dailyLogs.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.assignment_outlined,
              size: 64,
              color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'No Daily Logs Added',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Add daily logs to track project progress and activities',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _addDailyLog,
              icon: const Icon(Icons.add),
              label: const Text('Add First Daily Log'),
            ),
          ],
        ),
      );
    }

    // Sort logs by date (oldest first - ascending order)
    _dailyLogs.sort((a, b) => a.date.compareTo(b.date));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header with stats
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(
                Icons.assignment,
                color: Theme.of(context).colorScheme.primary,
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Daily Logs',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    Text(
                      '${_dailyLogs.length} entries • Latest: ${_getLatestLogDate()}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        
        // Daily logs list
        Expanded(
          child: RefreshIndicator(
            onRefresh: _loadDailyLogs,
            child: ListView.builder(
              padding: const EdgeInsets.only(bottom: 16),
              itemCount: _dailyLogs.length,
              itemBuilder: (context, index) {
                final dailyLog = _dailyLogs[index];
                return DailyLogCard(
                  dailyLog: dailyLog,
                  onTap: () => _editDailyLog(dailyLog),
                  onDelete: () => _deleteDailyLog(dailyLog),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  String _getLatestLogDate() {
    if (_dailyLogs.isEmpty) return 'None';
    
    final latestLog = _dailyLogs.reduce((a, b) => a.date.isAfter(b.date) ? a : b);
    final dateFormat = DateFormat('MMM dd');
    return dateFormat.format(latestLog.date);
  }
}


