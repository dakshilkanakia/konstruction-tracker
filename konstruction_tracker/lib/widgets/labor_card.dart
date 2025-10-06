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
    // Determine the card type and display accordingly
    if (labor.isContracted) {
      return labor.isContract 
          ? _buildContractCard(context)
          : _buildProgressCard(context);
    } else {
      // Non-contracted work: differentiate between work setup, work progress, and simple work
      if (labor.isWorkSetup) {
        return _buildWorkSetupCard(context);
      } else if (labor.isWorkProgress) {
        return _buildWorkProgressCard(context);
      } else {
        return _buildSimpleWorkCard(context);
      }
    }
  }

  Widget _buildContractCard(BuildContext context) {
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
              // Contract header
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
                          'Contract Setup',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.w500,
                            ),
                          ),
                      ],
                    ),
                  ),
                  _buildTypeChip('Contract', Icons.assignment, Colors.blue),
                ],
              ),
              const SizedBox(height: 12),

              // Contract details
              Row(
                children: [
                  Expanded(
                    child: _buildInfoItem(
                      context,
                      'Total Area',
                      '${labor.totalSqFt?.toStringAsFixed(0) ?? '0'} sq ft',
                      Icons.straighten,
                    ),
                  ),
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
                      'Total Value',
                      '\$${labor.totalValue.toStringAsFixed(2)}',
                      Icons.account_balance_wallet,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Action row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Tap to edit contract terms',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                      fontStyle: FontStyle.italic,
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

  Widget _buildProgressCard(BuildContext context) {
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
              // Progress header
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
                          'Progress Entry',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.green,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        if (labor.location?.isNotEmpty == true)
                          Text(
                            '📍 ${labor.location}',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                            ),
                          ),
                        if (labor.subcontractorCompany?.isNotEmpty == true)
                          Text(
                            labor.subcontractorCompany!,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                            ),
                          ),
                      ],
                    ),
                  ),
                  _buildTypeChip('Progress', Icons.trending_up, Colors.green),
                ],
              ),
              const SizedBox(height: 12),

              // Progress details
              Row(
                children: [
                  Expanded(
                    child: _buildInfoItem(
                      context,
                      'Completed',
                      '${labor.completedSqFt?.toStringAsFixed(1) ?? '0.0'} sq ft',
                      Icons.check_circle,
                    ),
                  ),
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
                      'Cost',
                      '\$${labor.totalCost.toStringAsFixed(2)}',
                      Icons.monetization_on,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Date and actions
              Row(
                children: [
                  Expanded(
                    child: _buildInfoItem(
                      context,
                      'Work Date',
                      labor.workDate != null 
                          ? '${labor.workDate!.day}/${labor.workDate!.month}/${labor.workDate!.year}'
                          : 'No date',
                      Icons.calendar_today,
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

  Widget _buildWorkSetupCard(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
                        const SizedBox(height: 4),
                        _buildTypeChip('Work Setup', Icons.work_history, Theme.of(context).colorScheme.primary),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: onDelete,
                    icon: const Icon(Icons.delete, color: Colors.red),
                    tooltip: 'Delete',
                  ),
                ],
              ),
              const SizedBox(height: 12),
              
              // Work setup details
              Row(
                children: [
                  Expanded(
                    child: _buildInfoItem(
                      context,
                      'Total Budget',
                      '\$${labor.totalBudget?.toStringAsFixed(2) ?? '0.00'}',
                      Icons.account_balance_wallet,
                    ),
                  ),
                  Expanded(
                    child: _buildInfoItem(
                      context,
                      'Hourly Rate',
                      '\$${labor.fixedHourlyRate?.toStringAsFixed(2) ?? '0.00'}/hr',
                      Icons.attach_money,
                    ),
                  ),
                  Expanded(
                    child: _buildInfoItem(
                      context,
                      'Max Hours',
                      '${labor.maxHours.toStringAsFixed(1)} hrs',
                      Icons.schedule,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWorkProgressCard(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
                      borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
                        const SizedBox(height: 4),
                        _buildTypeChip('Work Progress', Icons.trending_up, Colors.orange),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: onDelete,
                    icon: const Icon(Icons.delete, color: Colors.red),
                    tooltip: 'Delete',
                  ),
                ],
              ),
              const SizedBox(height: 12),
              
              // Work progress details
              Row(
                children: [
                  Expanded(
                    child: _buildInfoItem(
                      context,
                      'Hours Worked',
                      '${labor.hoursWorked?.toStringAsFixed(1) ?? '0.0'} hrs',
                      Icons.schedule,
                    ),
                  ),
                  Expanded(
                    child: _buildInfoItem(
                      context,
                      'Cost',
                      '\$${labor.totalCost.toStringAsFixed(2)}',
                      Icons.monetization_on,
                    ),
                  ),
                  Expanded(
                    child: _buildInfoItem(
                      context,
                      'Work Date',
                      labor.workDate != null 
                          ? '${labor.workDate!.month}/${labor.workDate!.day}/${labor.workDate!.year}'
                          : 'Not set',
                      Icons.calendar_today,
                    ),
                  ),
                ],
              ),
              
              // Optional details
              if (labor.location?.isNotEmpty == true || labor.subcontractorCompany?.isNotEmpty == true || labor.numberOfWorkers != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    if (labor.location?.isNotEmpty == true)
                      Expanded(
                        child: _buildInfoItem(
                          context,
                          'Location',
                          labor.location!,
                          Icons.location_on,
                        ),
                      ),
                    if (labor.subcontractorCompany?.isNotEmpty == true)
                      Expanded(
                        child: _buildInfoItem(
                          context,
                          'Company',
                          labor.subcontractorCompany!,
                          Icons.business,
                        ),
                      ),
                    if (labor.numberOfWorkers != null)
                      Expanded(
                        child: _buildInfoItem(
                          context,
                          'Workers',
                          '${labor.numberOfWorkers}',
                          Icons.people,
                        ),
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSimpleWorkCard(BuildContext context) {
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
              // Non-contracted header
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
                        if (labor.location?.isNotEmpty == true)
                          Text(
                            '📍 ${labor.location}',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                            ),
                          ),
                        if (labor.subcontractorCompany?.isNotEmpty == true)
                          Text(
                            labor.subcontractorCompany!,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                            ),
                          ),
                        if (labor.description?.isNotEmpty == true)
                        Text(
                            labor.description!,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                  ),
                  _buildTypeChip('Hourly Work', Icons.schedule, Theme.of(context).colorScheme.primary),
                ],
              ),
              const SizedBox(height: 12),

              // Non-contracted work details
              Row(
                children: [
                  Expanded(
                    child: _buildInfoItem(
                      context,
                      'Hourly Rate',
                      '\$${labor.fixedHourlyRate?.toStringAsFixed(2) ?? '0.00'}/hr',
                      Icons.speed,
                    ),
                  ),
                  Expanded(
                    child: _buildInfoItem(
                      context,
                      'Hours Worked',
                      '${labor.hoursWorked?.toStringAsFixed(1) ?? '0.0'} hrs',
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
              const SizedBox(height: 12),

              // Worker information and date
              Row(
                children: [
                  if (labor.numberOfWorkers != null)
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
                      labor.workDate != null 
                          ? '${labor.workDate!.day}/${labor.workDate!.month}/${labor.workDate!.year}'
                          : 'No date',
                      Icons.calendar_today,
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

  Widget _buildTypeChip(String label, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 12,
            color: color,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
        ],
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
