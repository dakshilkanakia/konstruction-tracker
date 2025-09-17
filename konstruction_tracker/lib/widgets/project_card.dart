import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/project.dart';

class ProjectCard extends StatelessWidget {
  final Project project;
  final VoidCallback onTap;
  final VoidCallback onArchiveToggle;

  const ProjectCard({
    super.key,
    required this.project,
    required this.onTap,
    required this.onArchiveToggle,
  });

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(symbol: '\$');
    
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
              // Header Row
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          project.name,
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          project.location,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                  PopupMenuButton(
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        child: ListTile(
                          leading: Icon(project.isArchived ? Icons.unarchive : Icons.archive),
                          title: Text(project.isArchived ? 'Unarchive' : 'Archive'),
                          contentPadding: EdgeInsets.zero,
                        ),
                        onTap: onArchiveToggle,
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Project Info Row
              Row(
                children: [
                  Expanded(
                    child: _buildInfoItem(
                      context,
                      'Days Running',
                      '${project.daysSinceStart}',
                      Icons.calendar_today,
                    ),
                  ),
                  Expanded(
                    child: _buildInfoItem(
                      context,
                      'Contractor',
                      project.generalContractor,
                      Icons.person,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Budget Progress
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Budget Progress',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        '${(project.budgetProgress * 100).toStringAsFixed(1)}%',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: _getBudgetColor(context, project.budgetProgress),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: project.budgetProgress,
                    backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
                    color: _getBudgetColor(context, project.budgetProgress),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Used: ${currencyFormat.format(project.usedBudget)}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      Text(
                        'Total: ${currencyFormat.format(project.totalBudget)}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoItem(BuildContext context, String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
        ),
        const SizedBox(width: 4),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
              Text(
                value,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Color _getBudgetColor(BuildContext context, double progress) {
    if (progress <= 0.7) {
      return Colors.green;
    } else if (progress <= 0.9) {
      return Colors.orange;
    } else {
      return Colors.red;
    }
  }
}
