import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/project.dart';

class ProjectCard extends StatelessWidget {
  final Project project;
  final VoidCallback onTap;
  final VoidCallback onArchiveToggle;
  final VoidCallback? onEdit;

  const ProjectCard({
    super.key,
    required this.project,
    required this.onTap,
    required this.onArchiveToggle,
    this.onEdit,
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
                      if (onEdit != null)
                        PopupMenuItem(
                          child: const ListTile(
                            leading: Icon(Icons.edit),
                            title: Text('Edit Project'),
                            contentPadding: EdgeInsets.zero,
                          ),
                          onTap: onEdit,
                        ),
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
                  const SizedBox(height: 8),
                  Text(
                    'Budget: ${currencyFormat.format(project.totalBudget)}',
                    style: Theme.of(context).textTheme.bodySmall,
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

}
