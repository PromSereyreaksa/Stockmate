import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ActivityItem extends StatelessWidget {
  final String type; // 'add' or 'remove'
  final int previousQty;
  final int newQty;
  final DateTime timestamp;
  final String? reason;

  const ActivityItem({
    super.key,
    required this.type,
    required this.previousQty,
    required this.newQty,
    required this.timestamp,
    this.reason,
  });

  @override
  Widget build(BuildContext context) {
    final isAddition = type == 'add';
    final icon = isAddition ? Icons.add_circle_outline : Icons.remove_circle_outline;
    final iconColor = isAddition ? Colors.green : Colors.red;
    final title = isAddition ? 'Stock Added' : 'Sale';
    final change = newQty - previousQty;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Colors.grey.shade200,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          // Icon
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: iconColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),

          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    Text(
                      '$previousQty → $newQty',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: iconColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '${change.abs()} units • ${DateFormat('MMM d, yyyy').format(timestamp)}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                if (reason != null && reason!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    reason!,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[500],
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}