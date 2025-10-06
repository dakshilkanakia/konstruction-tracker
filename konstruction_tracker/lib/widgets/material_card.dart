import 'package:flutter/material.dart';
import '../models/material.dart' as models;

class MaterialCard extends StatelessWidget {
  final models.Material material;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const MaterialCard({
    super.key,
    required this.material,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    // With the new structure, we only track ordered quantity and cost
    final quantityOrdered = material.quantityOrdered ?? 0.0;
    final costPerUnit = material.costPerUnit ?? 0.0;

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
              // Header with name and edit icon
              Row(
                children: [
                  Expanded(
                    child: Text(
                      material.name ?? 'Unnamed Material',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
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

              // Quantity information
              Row(
                children: [
                  if (quantityOrdered > 0)
                    Expanded(
                      child: _buildInfoItem(
                        context,
                        'Quantity',
                        '${quantityOrdered.toStringAsFixed(1)} ${material.unit ?? 'units'}',
                        Icons.shopping_cart,
                        Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  if (costPerUnit > 0)
                    Expanded(
                      child: _buildInfoItem(
                        context,
                        'Cost/Unit',
                        '\$${costPerUnit.toStringAsFixed(2)}',
                        Icons.attach_money,
                        Colors.orange,
                      ),
                    ),
                  Expanded(
                    child: _buildInfoItem(
                      context,
                      'Total Cost',
                      '\$${material.finalTotalCost.toStringAsFixed(2)}',
                      Icons.calculate,
                      Colors.green,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),


              // Cost information
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Cost per ${material.unit ?? 'unit'}: \$${(material.costPerUnit ?? 0).toStringAsFixed(2)}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      'Total: \$${material.finalTotalCost.toStringAsFixed(2)}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
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

  Widget _buildInfoItem(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    Color color,
  ) {

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              icon,
              size: 14,
              color: color,
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
            color: color,
          ),
        ),
      ],
    );
  }

}
