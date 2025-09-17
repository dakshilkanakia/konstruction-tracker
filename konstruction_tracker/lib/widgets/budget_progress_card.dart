import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class BudgetProgressCard extends StatelessWidget {
  final double totalBudget;
  final double usedBudget;

  const BudgetProgressCard({
    super.key,
    required this.totalBudget,
    required this.usedBudget,
  });

  double get remainingBudget => totalBudget - usedBudget;
  double get budgetProgress => totalBudget > 0 ? (usedBudget / totalBudget) : 0.0;
  bool get isOverBudget => usedBudget > totalBudget;
  bool get isBudgetWarning => budgetProgress > 0.8;

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(symbol: '\$');
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with warning icon if needed
            Row(
              children: [
                Text(
                  'Budget Progress',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                if (isOverBudget || isBudgetWarning)
                  Icon(
                    isOverBudget ? Icons.error : Icons.warning,
                    color: isOverBudget ? Colors.red : Colors.orange,
                  ),
              ],
            ),
            const SizedBox(height: 16),

            // Progress Bar
            LinearProgressIndicator(
              value: budgetProgress.clamp(0.0, 1.0),
              backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
              color: _getBudgetColor(),
            ),
            const SizedBox(height: 12),

            // Progress Percentage
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${(budgetProgress * 100).toStringAsFixed(1)}% Used',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: _getBudgetColor(),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (isOverBudget)
                  Text(
                    'OVER BUDGET',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),

            // Budget Breakdown
            Row(
              children: [
                Expanded(
                  child: _buildBudgetItem(
                    context,
                    'Used',
                    currencyFormat.format(usedBudget),
                    _getBudgetColor(),
                  ),
                ),
                Expanded(
                  child: _buildBudgetItem(
                    context,
                    'Remaining',
                    currencyFormat.format(remainingBudget),
                    remainingBudget >= 0 ? Colors.green : Colors.red,
                  ),
                ),
                Expanded(
                  child: _buildBudgetItem(
                    context,
                    'Total',
                    currencyFormat.format(totalBudget),
                    Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ],
            ),

            // Warning Message
            if (isOverBudget || isBudgetWarning) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isOverBudget 
                      ? Colors.red.withOpacity(0.1)
                      : Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isOverBudget ? Colors.red : Colors.orange,
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      isOverBudget ? Icons.error : Icons.warning,
                      color: isOverBudget ? Colors.red : Colors.orange,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        isOverBudget
                            ? 'Budget exceeded by ${currencyFormat.format(usedBudget - totalBudget)}'
                            : 'Approaching budget limit - ${currencyFormat.format(remainingBudget)} remaining',
                        style: TextStyle(
                          color: isOverBudget ? Colors.red : Colors.orange,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildBudgetItem(BuildContext context, String label, String value, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: color,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Color _getBudgetColor() {
    if (isOverBudget) return Colors.red;
    if (budgetProgress > 0.9) return Colors.red;
    if (budgetProgress > 0.8) return Colors.orange;
    if (budgetProgress > 0.7) return const Color(0xFFB8860B); // Dark gold
    return const Color(0xFFFFD700); // Gold
  }
}
