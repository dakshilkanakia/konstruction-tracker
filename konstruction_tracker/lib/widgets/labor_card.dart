import 'package:flutter/material.dart';
import '../models/labor.dart';

class LaborCard extends StatelessWidget {
  final Labor labor;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const LaborCard({
    super.key,
    required this.labor,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
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
              // Header with type and edit icon
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          labor.workCategory,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          labor.subcontractorCompany,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                          ),
                        ),
                        if (labor.description.isNotEmpty)
                          Text(
                            labor.description,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
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

              // Labor information based on type
              if (labor.type == LaborType.contracted) ...[
                // Contracted work details
                Row(
                  children: [
                    Expanded(
                      child: _buildInfoItem(
                        context,
                        'Rate/Sq Ft',
                        '\$${labor.ratePerSqFt?.toStringAsFixed(2) ?? '0.00'}',
                        Icons.attach_money,
                      ),
                    ),
                    Expanded(
                      child: _buildInfoItem(
                        context,
                        'Work Area',
                        '${labor.workAreaSqFt?.toStringAsFixed(1) ?? '0.0'} sq ft',
                        Icons.square_foot,
                      ),
                    ),
                    Expanded(
                      child: _buildInfoItem(
                        context,
                        'Total Cost',
                        '\$${labor.totalCost.toStringAsFixed(2)}',
                        Icons.calculate,
                      ),
                    ),
                  ],
                ),
              ] else ...[
                // Non-contracted work details
                Row(
                  children: [
                    Expanded(
                      child: _buildInfoItem(
                        context,
                        'Fixed Rate',
                        '\$${labor.fixedHourlyRate?.toStringAsFixed(2) ?? '0.00'}/hr',
                        Icons.speed,
                      ),
                    ),
                    Expanded(
                      child: _buildInfoItem(
                        context,
                        'Total Hours',
                        '${labor.totalHours.toStringAsFixed(1)} hrs',
                        Icons.schedule,
                      ),
                    ),
                    Expanded(
                      child: _buildInfoItem(
                        context,
                        'Total Cost',
                        '\$${labor.totalCost.toStringAsFixed(2)}',
                        Icons.calculate,
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 12),

              // Worker information
              Row(
                children: [
                  Expanded(
                    child: _buildInfoItem(
                      context,
                      'Workers',
                      '${labor.numberOfWorkers} people',
                      Icons.people,
                    ),
                  ),
                  Expanded(
                    child: _buildInfoItem(
                      context,
                      'Work Date',
                      '${labor.workDate.day}/${labor.workDate.month}/${labor.workDate.year}',
                      Icons.calendar_today,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Type indicator
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: labor.type == LaborType.contracted 
                          ? Colors.blue.withOpacity(0.1)
                          : const Color(0xFFFFD700).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: labor.type == LaborType.contracted 
                            ? Colors.blue.withOpacity(0.3)
                            : const Color(0xFFFFD700).withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          labor.type == LaborType.contracted ? Icons.business_center : Icons.person,
                          size: 12,
                          color: labor.type == LaborType.contracted ? Colors.blue : const Color(0xFFFFD700),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          labor.type == LaborType.contracted ? 'Contracted' : 'Non-Contracted',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                            color: labor.type == LaborType.contracted ? Colors.blue : const Color(0xFFFFD700),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: onDelete,
                    icon: const Icon(Icons.delete_outline),
                    color: Colors.red.withOpacity(0.7),
                    iconSize: 20,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoItem(
    BuildContext context,
    String label,
    String value,
    IconData icon,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              icon,
              size: 14,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}