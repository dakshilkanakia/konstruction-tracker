import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/daily_log.dart' as models;

class DailyLogCard extends StatelessWidget {
  final models.DailyLog dailyLog;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const DailyLogCard({
    super.key,
    required this.dailyLog,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMM dd, yyyy');
    final timeFormat = DateFormat('h:mm a');
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with date and edit icon
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          dateFormat.format(dailyLog.date),
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Created at ${timeFormat.format(dailyLog.createdAt)}',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Icon(
                      Icons.edit,
                      size: 16,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Weather information
              if (dailyLog.weather?.isNotEmpty == true)
                _buildInfoSection(
                  context,
                  'Weather',
                  dailyLog.weather!,
                  Icons.wb_sunny,
                  Colors.orange,
                ),

              // Work completed
              if (dailyLog.workCompleted?.isNotEmpty == true)
                _buildInfoSection(
                  context,
                  'Work Completed',
                  dailyLog.workCompleted!,
                  Icons.construction,
                  Theme.of(context).colorScheme.primary,
                ),

              // Materials used
              if (dailyLog.materialsUsed?.isNotEmpty == true)
                _buildInfoSection(
                  context,
                  'Materials Used',
                  dailyLog.materialsUsed!,
                  Icons.inventory_2,
                  Colors.blue,
                ),

              // Issues and concerns
              if (dailyLog.issuesAndConcerns?.isNotEmpty == true)
                _buildInfoSection(
                  context,
                  'Issues & Concerns',
                  dailyLog.issuesAndConcerns!,
                  Icons.warning,
                  Colors.red,
                ),

              // Empty state if no content
              if (dailyLog.weather?.isEmpty != false &&
                  dailyLog.workCompleted?.isEmpty != false &&
                  dailyLog.materialsUsed?.isEmpty != false &&
                  dailyLog.issuesAndConcerns?.isEmpty != false)
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
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'No details added for this day',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoSection(
    BuildContext context,
    String title,
    String content,
    IconData icon,
    Color color,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: color.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                color: color,
                size: 16,
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            content,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}
